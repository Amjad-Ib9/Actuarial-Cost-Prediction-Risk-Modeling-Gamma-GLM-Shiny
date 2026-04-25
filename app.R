library(shiny)
library(shinydashboard)
library(tidyverse)
library(randomForest)
library(corrplot)

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
    
    dashboardHeader(title = "Insurance Cost Analysis"),
    
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
                        box(title = "Client Information", width = 4, status = "primary",
    fluidRow(
      column(6, sliderInput("age", "Age", min = 18, max = 64, value = 30)),
      column(6, sliderInput("bmi", "BMI", min = 10, max = 60, value = 25, step = 0.5))
    ),
    fluidRow(
      column(6, selectInput("smoker", "Smoker", choices = c("yes","no"))),
      column(6, selectInput("sex", "Sex", choices = c("male","female")))
    ),
    fluidRow(
      column(6, sliderInput("children", "Children", min = 0, max = 5, value = 0)),
      column(6, selectInput("region", "Region", 
                            choices = c("northeast","northwest","southeast","southwest")))
    ),
    actionButton("predict_btn", "Predict", class = "btn-primary btn-block")
),
                        box(title = "Result", width = 8, status = "success",
                            valueBoxOutput("cost_box", width = 6),
                            valueBoxOutput("risk_box", width = 6),
                            br(),
                            h4("Interpretation:"),
                            textOutput("interpretation")
                        )
                    )
            ),
            
            # ===== Page 2 — Model Comparison =====
            tabItem(tabName = "models",
                    fluidRow(
                        box(title = "Model Comparison", width = 12, status = "primary",
                            tableOutput("results_table"),
                            br(),
                            plotOutput("models_plot")
                        )
                    )
            ),
            
            # ===== Page 3 — Data Analysis =====
            tabItem(tabName = "eda",
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
            sex      = factor(input$sex,     levels = c("female","male")),
            children = input$children,
            region   = factor(input$region,  levels = c("northeast","northwest","southeast","southwest")),
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
    
    # --- Model Comparison ---
    output$results_table <- renderTable({
        results
    })
    
    output$models_plot <- renderPlot({
        ggplot(results, aes(x = reorder(Model, MAE), y = MAE, fill = MAE)) +
            geom_bar(stat = "identity") +
            coord_flip() +
            scale_fill_gradient(low = "steelblue", high = "tomato") +
            labs(title = "Model Comparison by MAE", x = "Model", y = "MAE") +
            theme_minimal()
    })
    
    # --- EDA Plots ---
    output$hist_plot <- renderPlot({
        ggplot(df, aes(x = charges)) +
            geom_histogram(fill = "steelblue", bins = 30) +
            labs(title = "Cost Distribution", x = "Cost", y = "Count") +
            theme_minimal()
    })
    
    output$age_plot <- renderPlot({
        ggplot(df, aes(x = age, y = charges, color = smoker)) +
            geom_point(alpha = 0.5) +
            labs(title = "Age vs Cost", x = "Age", y = "Cost") +
            theme_minimal()
    })
    
    output$bmi_plot <- renderPlot({
        ggplot(df, aes(x = bmi, y = charges, color = smoker)) +
            geom_point(alpha = 0.5) +
            labs(title = "BMI vs Cost", x = "BMI", y = "Cost") +
            theme_minimal()
    })
    
    output$cor_plot <- renderPlot({
        cor_matrix <- cor(df[, c("age","bmi","children","charges")])
        corrplot(cor_matrix, method = "color", addCoef.col = "black")
    })
}

# ==================== Run ====================
shinyApp(ui = ui, server = server)