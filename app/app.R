library(shiny)
library(shinydashboard)
library(tidyverse)
library(randomForest)
library(corrplot)
#install.packages("DT")
library(DT)

# Load models
model_linear4  <- readRDS("model_linear4.rds")
model_RF_class <- readRDS("model_RF_class.rds")
risk_quantiles <- readRDS("risk_quantiles.rds")
df <- read.csv("insurance.csv")

# Model comparison data
results <- data.frame(
    Model = c("Linear1","Linear2","Gamma","Linear3","Linear4","Log","Log2","RF","XGB"),
    MAE   = c(4184.857, 3064.735, 4149.098, 2976.029, 2399.335, 4102.718, 4085.342, 2815.248, 2995.463),
    RMSE  = c(6289.889, 5229.373, 7681.356, 5073.786, 4685.756, 7946.513, 8381.534, 4925.016, 5373.278)
)

# ==================== UI ====================
ui <- dashboardPage(
    
    dashboardHeader(title = "Insurance Cost Prediction"),
    
    dashboardSidebar(
        sidebarMenu(
            menuItem("Prediction",       tabName = "predict", icon = icon("calculator")),
            menuItem("Model Comparison", tabName = "models",  icon = icon("table")),
            menuItem("Data Analysis",    tabName = "eda",     icon = icon("chart-bar"))
        )
    ),
    
    dashboardBody(
        tags$head(
            tags$style(HTML("
      input[type='number'] {
        -moz-appearance: textfield;
      }
    ")),
            tags$script(HTML("
      $(document).ready(function() {
        $('input[type=number]').attr('lang', 'en');
      });
    "))
        ),
        tabItems(
            
            # ===== Page 1 — Prediction =====
            tabItem(tabName = "predict",
                    fluidRow(
                        box(title = "Client Information", width = 4, status = "primary",height = "621px",
                            div(style = "display: flex; flex-direction: column; align-items: center;",
                                div(style = "width: 80%;",
                                    numericInput("age", "Age", min = 18, max = 64, value = 30),
                                    selectInput("smoker", "Smoker", choices = c("yes","no")),
                                    numericInput("children", "Children", min = 0, max = 5, value = 0),
                                    numericInput("bmi", "BMI", min = 10, max = 60, value = 25, step = 0.5),
                                    actionButton("predict_btn", "Predict", class = "btn-primary btn-block",
                                                 style = "margin-top: 10px;")
                                )
                            )
                        ),
                        box(title = "Result", width = 8, status = "success",
                            valueBoxOutput("cost_box", width = 6),
                            valueBoxOutput("risk_box", width = 6),
                            br(),
                            h4("Interpretation:"),
                            textOutput("interpretation"),
                            hr(),  # خط فاصل
                            h4("Prediction History"),
                            downloadButton("download_history", "Download CSV"),
                            br(), br(),
                            DT::dataTableOutput("history_table")
                              )
                    )
            ),
            
            # ===== Page 2 — Model Comparison =====
            tabItem(tabName = "models",
                    fluidRow(
                        box(title = "Model Comparison", width = 12, status = "primary",
                            DT::dataTableOutput("results_table"),
                            br(),
                            plotOutput("models_plot")
                        )
                    )
            ),
            
            # ===== Page 3 — Data Analysis =====
            tabItem(tabName = "eda",
                    fluidRow(
                        box(title = "Filters", width = 12, status = "primary",
                            column(4,
                                   selectInput("filter_smoker", "Filter by Smoker",
                                               choices = c("All", "yes", "no"))
                            ),
                            column(4,
                                   sliderInput("filter_age", "Filter by Age",
                                               min = 18, max = 64, value = c(18, 64))
                            ),
                            column(4,
                                   sliderInput("filter_bmi", "Filter by BMI",
                                               min = 10, max = 55, value = c(10, 55))
                            )
                        )
                    ),
                    fluidRow(
                        box(title = "Cost Distribution", width = 6, status = "info",
                            plotOutput("hist_plot")),
                        box(title = "Age vs Cost", width = 6, status = "info",
                            plotOutput("age_plot"))
                    ),
                    fluidRow(
                        box(title = "BMI vs Cost", width = 6, status = "info",
                            plotOutput("bmi_plot")),
                        box(title = "Correlation Matrix", width = 6, status = "info",
                            plotOutput("cor_plot"))
                    )
            )
        )
    )
)

# ==================== Server ====================
server <- function(input, output) {
    
    # --- Prediction ---
    prediction <- eventReactive(input$predict_btn, {
        
        new_data <- data.frame(
            age      = input$age,
            bmi      = input$bmi,
            smoker   = factor(input$smoker,  levels = c("no","yes")),
            sex      = factor("male", levels = c("female","male")),     
            children = input$children,
            region   = factor("northeast", levels = c("northeast","northwest","southeast","southwest")),  # قيمة افتراضية
            bmi30    = ifelse(input$bmi >= 30 & input$smoker == "yes", 1, 0)
        )
        
        cost <- predict(model_linear4,  newdata = new_data)
        risk <- predict(model_RF_class, newdata = new_data)
        
        list(cost = round(cost, 2), risk = as.character(risk))
    })
    
    output$cost_box <- renderValueBox({
        req(prediction())
        valueBox(
            value    = paste0("$", format(prediction()$cost, big.mark = ",")),
            subtitle = "Predicted Cost",
            icon     = icon("dollar-sign"),
            color    = "blue"
        )
    })
    
    output$risk_box <- renderValueBox({
        req(prediction())
        color <- switch(prediction()$risk,
                        "Low"    = "green",
                        "Medium" = "yellow",
                        "High"   = "red")
        valueBox(
            value    = prediction()$risk,
            subtitle = "Risk Level",
            icon     = icon("exclamation-triangle"),
            color    = color
        )
    })
    
    output$interpretation <- renderText({
        req(prediction())
        paste0(
            "The predicted cost for this client is $",
            format(prediction()$cost, big.mark = ","),
            " with a risk level of: ", prediction()$risk
        )
    }) 
    
    # إنشاء جدول History
    history <- reactiveVal(data.frame(
        Age      = numeric(),
        BMI      = numeric(),
        Smoker   = character(),
        Children = numeric(),
        Predicted_Cost = numeric(),
        Risk_Level     = character(),
        stringsAsFactors = FALSE
        
    ))
    
    # تحديث الجدول عند كل تنبؤ
    observeEvent(input$predict_btn, {
        req(prediction())
        
        new_row <- data.frame(
            Age            = input$age,
            BMI            = input$bmi,
            Smoker         = input$smoker,
            Children       = input$children,
            Predicted_Cost = prediction()$cost,
            Risk_Level     = prediction()$risk,
            stringsAsFactors = FALSE
            
        )
        
        history(rbind(history(), new_row))
    })
    
    # عرض الجدول
    
    output$history_table <- DT::renderDataTable({
        req(nrow(history()) > 0)
        history()
    }, options = list(
        pageLength = 5,
        scrollX = TRUE,
        dom = 'tip'
    ))
    
    
    
    # تحميل CSV
    output$download_history <- downloadHandler(
        filename = function() {
            paste0("predictions_", Sys.Date(), ".csv")
        },
        content = function(file) {
            write.csv(history(), file, row.names = FALSE)
        }
    )
    
    # --- Model Comparison ---
    output$results_table <- DT::renderDataTable({
        
        formulas <- c(
            "age + bmi + children + smoker + sex + region",
            "age + bmi + smoker + bmi:smoker + age²",
            "age + bmi + smoker + bmi:smoker + age² (Gamma Family)",
            "age + age² + bmi + bmi² + smoker + bmi:smoker + children",
            "age + age² + bmi + bmi² + smoker + bmi:smoker + bmi30 + children",
            "log(charges) ~ age + age² + bmi + bmi² + smoker + bmi:smoker + children",
            "log(charges) ~ age + age² + bmi + bmi² + smoker + bmi:smoker + bmi30 + children",
            "age + bmi + children + smoker + sex + region + bmi30 — Random Forest",
            "age + bmi + children + smoker + sex + region + bmi30 — XGBoost"
        )
        
        # إضافة tooltip على عمود Model
        results$Model <- paste0(
            '<span title="', formulas, '" style="cursor:help; border-bottom: 1px dashed #999;">',
            results$Model,
            '</span>'
        )
        
        results
        
    }, escape = FALSE,
    options = list(
        pageLength = 10,
        dom = 'tip',
        scrollX = TRUE
    ))
    
    
    output$models_plot <- renderPlot({
        ggplot(results, aes(x = reorder(Model, MAE), y = MAE, fill = MAE)) +
            geom_bar(stat = "identity") +
            coord_flip() +
            scale_fill_gradient(low = "steelblue", high = "tomato") +
            labs(title = "Model Comparison by MAE", x = "Model", y = "MAE") +
            theme_minimal()
    })
    
    # --- EDA Plots ---
    
    # بيانات مفلترة
    filtered_df <- reactive({
        data <- df
        
        if (input$filter_smoker != "All") {
            data <- data[data$smoker == input$filter_smoker, ]
        }
        
        data <- data[data$age >= input$filter_age[1] & 
                         data$age <= input$filter_age[2], ]
        
        data <- data[data$bmi >= input$filter_bmi[1] & 
                         data$bmi <= input$filter_bmi[2], ]
        
        data
    })
    
    
    
    
    output$hist_plot <- renderPlot({
        ggplot(filtered_df(), aes(x = charges)) +
            geom_histogram(fill = "steelblue", bins = 30) +
            labs(title = "Cost Distribution", x = "Cost", y = "Count") +
            theme_minimal()
    })
    
    output$age_plot <- renderPlot({
        ggplot(filtered_df(), aes(x = age, y = charges, color = smoker)) +
            geom_point(alpha = 0.5) +
            labs(title = "Age vs Cost", x = "Age", y = "Cost") +
            theme_minimal()
    })
    
    output$bmi_plot <- renderPlot({
        ggplot(filtered_df(), aes(x = bmi, y = charges, color = smoker)) +
            geom_point(alpha = 0.5) +
            labs(title = "BMI vs Cost", x = "BMI", y = "Cost") +
            theme_minimal()
    })
    
    output$cor_plot <- renderPlot({
        data <- filtered_df()
        
        if (nrow(data) < 3) {
            plot.new()
            text(0.5, 0.5, "Not enough data to display", cex = 1.5)
            return()
        }
        cor_matrix <- cor(filtered_df()[, c("age","bmi","children","charges")])
        corrplot(cor_matrix, method = "color", addCoef.col = "black")
    })
}

# ==================== Run ====================
shinyApp(ui = ui, server = server)