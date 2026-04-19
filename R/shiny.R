library(shiny)
library(shinydashboard)

source("R/data_prep.R")
source("R/model.R")
source("R/function.R")

ui <- dashboardPage(
    
    dashboardHeader(title = "Insurance Pricing Dashboard"),
    
    dashboardSidebar(
        sidebarMenu(
            menuItem("Prediction", tabName = "predict", icon = icon("chart-line"))
        )
    ),
    
    dashboardBody(
        tabItems(
            tabItem(tabName = "predict",
                    
                    fluidRow(
                        
                        # ==============================
                        # Input Box
                        # ==============================
                        box(
                            title = "Client Information",
                            width = 4,
                            status = "primary",
                            solidHeader = TRUE,
                            
                            numericInput("age", "Age:", 30, min = 18, max = 100),
                            numericInput("bmi", "BMI:", 25),
                            selectInput("smoker", "Smoker:", c("yes", "no")),
                            numericInput("children", "Children:", 0),
                            
                            actionButton("predict", "Predict", class = "btn-primary")
                        ),
                        
                        # ==============================
                        # Dynamic Result Box
                        # ==============================
                        uiOutput("result_box")
                        
                    )
            )
        )
    )
)

server <- function(input, output) {
    prediction <- eventReactive(input$predict, {
        
        new_data <- data.frame(
            age = input$age,
            bmi = input$bmi,
            smoker = input$smoker,
            children = input$children
        )
        
        predict_clients(
            new_data,
            model_glm,
            levels(df$smoker)
        )
    })
    
    output$result_box <- renderUI({
        
        req(prediction())
        
        res <- prediction()
        
        box_status <- ifelse(res$risk == "Low Risk", "success",
                             ifelse(res$risk == "Medium Risk", "warning", "danger"))
        
        risk_color <- ifelse(res$risk == "Low Risk", "green",
                             ifelse(res$risk == "Medium Risk", "orange", "red"))
        
        icon_name <- ifelse(res$risk == "Low Risk", "check-circle",
                            ifelse(res$risk == "Medium Risk", "exclamation-triangle", "times-circle"))
        
        box(
            title = "Prediction Result",
            width = 8,
            status = box_status,
            solidHeader = TRUE,
            
            h2(paste0("💰 $", format(round(res$predicted_cost, 2), big.mark = ","))),
            
            tags$div(
                icon(icon_name, style = paste0("color:", risk_color, "; font-size:24px;")),
                span(
                    style = paste0("color:", risk_color, "; font-weight:bold; margin-left:10px; font-size:20px;"),
                    paste("Risk Level:", res$risk)
                )
            )
        )
    })
}

shinyApp(ui, server)
