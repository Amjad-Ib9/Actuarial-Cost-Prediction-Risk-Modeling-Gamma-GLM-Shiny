

library(shiny)
library(shinydashboard)
library(tidyverse)
library(DT)

source("R/helpers.R")
source("R/prediction.R")

# Load dataset (insurance data)

if (!file.exists("insurance.csv")) {
    stop("Dataset not found. Please add insurance.csv")
}
insurance_raw <- read_csv("insurance.csv")


# Data preparation (convert categorical variables)


df <- insurance_raw %>%
    mutate(
        sex = as.factor(sex),
        smoker = as.factor(smoker),
        region = as.factor(region)
        
    )


# Validate dataset: stop app if missing values are found

if (any(is.na(df))) {
    stop("Dataset contains missing values")
}

# Load pre-trained model
# Load trained model (must exist before running app)
if (!file.exists("model.rds")) {
    stop("Model file not found. Please run train_model.R first.")
}
model_glm <- readRDS("model.rds")




# Custom numeric input with increment and decrements buttons
# Supports min/max limits and step size, with JavaScript handling for dynamic updates


numericInputCustom <- function(id,
                               label,
                               value,
                               min = -Inf,
                               max = Inf,
                               step = 1) {
    tagList(
        tags$div(
            style = "margin-bottom: 15px;",
            tags$label(`for` = id, label, style = "display:block; font-weight:600; margin-bottom:5px;"),
            tags$div(
                style = "display:flex; align-items:center; gap:6px;",
                tags$button(
                    "-",
                    id = paste0(id, "_minus"),
                    class = "btn btn-default btn-sm",
                    style = "width:34px; height:34px; font-size:18px; font-weight:700;
                             padding:0; line-height:1; flex-shrink:0;"
                ),
                tags$input(
                    id = id,
                    type = "text",
                    value = value,
                    class = "form-control",
                    style = "text-align:center; font-size:15px; height:34px; font-family:Arial,sans-serif;"
                ),
                tags$button(
                    "+",
                    id = paste0(id, "_plus"),
                    class = "btn btn-default btn-sm",
                    style = "width:34px; height:34px; font-size:18px; font-weight:700;
                             padding:0; line-height:1; flex-shrink:0;"
                )
            )
        ),
        tags$script(
            HTML(
                sprintf(
                    "
            (function() {
                var step = %f; var min = %s; var max = %s;
                function getVal() {
  return parseFloat(document.getElementById('%s').value);
}
                function setVal(v) {
                    if (min !== null && v < min) v = min;
                    if (max !== null && v > max) v = max;
                    v = Math.round(v * 1000) / 1000;
                    document.getElementById('%s').value = v;
                    $('#%s').trigger('change');
                }
                $(document).on('click', '#%s_minus', function(e) { e.preventDefault(); setVal(getVal() - step); });
                $(document).on('click', '#%s_plus',  function(e) { e.preventDefault(); setVal(getVal() + step); });
            })();
        ", step, ifelse(is.finite(min), min, "null"), ifelse(is.finite(max), max, "null"), id, id, id, id, id
                )
            )
        )
    )
}



# Precompute KPI metrics for dashboard display

kpi_total      <- nrow(df)
kpi_avg_cost   <- mean(df$charges)
kpi_pred_all   <- predict(model_glm, newdata = df, type = "response")
kpi_risk_all   <- ifelse(
    kpi_pred_all < 10000,
    "Low Risk",
    ifelse(kpi_pred_all < 30000, "Medium Risk", "High Risk")
)
kpi_low_pct    <- round(mean(kpi_risk_all == "Low Risk")    * 100, 1)
kpi_medium_pct <- round(mean(kpi_risk_all == "Medium Risk") * 100, 1)
kpi_high_pct   <- round(mean(kpi_risk_all == "High Risk")   * 100, 1)

# ===== UI =====
ui <- dashboardPage(
    dashboardHeader(title = "Insurance Pricing Dashboard"),
    
    dashboardSidebar(sidebarMenu(
        menuItem(
            "Prediction",
            tabName = "predict",
            icon = icon("chart-line")
        )
    )),
    
    dashboardBody(tags$head(tags$style(
        HTML(
            "
                body, input, button, select, .form-control {
                    font-family: Arial, 'Helvetica Neue', sans-serif !important;
                }
                input, .form-control { direction: ltr !important; text-align: left !important; }
                .box { border-radius: 10px; }

                /* KPI */
                .kpi-row { display:flex; gap:16px; flex-wrap:wrap; margin-bottom:20px; }
                .kpi-card { flex:1; min-width:140px; background:#ffffff; border-radius:12px;
                            padding:16px 20px; border-left:5px solid #ccc;
                            box-shadow:0 2px 6px rgba(0,0,0,0.07); }
                .kpi-card.blue   { border-left-color:#3498DB; }
                .kpi-card.green  { border-left-color:#2ECC71; }
                .kpi-card.orange { border-left-color:#F39C12; }
                .kpi-card.red    { border-left-color:#E74C3C; }
                .kpi-label { font-size:12px; color:#888; text-transform:uppercase;
                             letter-spacing:0.5px; margin-bottom:6px; }
                .kpi-value { font-size:26px; font-weight:700; color:#2C3E50; line-height:1; }
                .kpi-sub   { font-size:12px; color:#aaa; margin-top:4px; }

                /* Comparison */
                .comp-wrap { margin-top:20px; padding:16px; background:#f8f9fa; border-radius:10px; }
                .comp-title { font-size:13px; font-weight:700; color:#555;
                              margin-bottom:12px; text-transform:uppercase; letter-spacing:0.4px; }
                .comp-bar-bg { background:#e0e0e0; border-radius:20px; height:22px;
                               position:relative; overflow:visible; }
                .comp-bar-fill { height:22px; border-radius:20px; transition:width 0.6s ease; }
                .comp-labels { display:flex; justify-content:space-between;
                               font-size:12px; color:#777; margin-top:6px; }
                .comp-badge { display:inline-block; padding:3px 10px; border-radius:20px;
                              font-size:12px; font-weight:700; margin-left:8px; }
                .comp-above { background:#FDECEA; color:#C0392B; }
                .comp-below { background:#EAFAF1; color:#1E8449; }
                .comp-equal { background:#EAF2FB; color:#1A5276; }
                .comp-row   { display:flex; align-items:center; margin-bottom:10px; }
                .comp-name  { font-size:13px; color:#555; width:100px; flex-shrink:0; }
                .comp-amt   { font-size:13px; font-weight:700; color:#2C3E50;
                              margin-left:10px; white-space:nowrap; }

                /* Export section */
                .export-wrap { margin-top:16px; padding:14px 16px;
                               background:#EAF2FB; border-radius:10px;
                               display:flex; align-items:center; justify-content:space-between;
                               flex-wrap:wrap; gap:10px; }
                .export-info { font-size:13px; color:#1A5276; }
                .export-info span { font-weight:700; }
                .btn-export { background:#2980B9; color:#fff; border:none;
                              border-radius:8px; padding:8px 18px; font-size:13px;
                              font-weight:600; cursor:pointer; }
                .btn-export:hover { background:#1A5276; color:#fff; }
            "
        )
    )), tabItems(
        tabItem(
            tabName = "predict",
            
            # KPI Cards
            tags$div(
                class = "kpi-row",
                tags$div(
                    class = "kpi-card blue",
                    tags$div(class = "kpi-label", "Total Clients"),
                    tags$div(class = "kpi-value", format(kpi_total, big.mark = ",")),
                    tags$div(class = "kpi-sub", "in dataset")
                ),
                tags$div(
                    class = "kpi-card blue",
                    tags$div(class = "kpi-label", "Avg. Cost"),
                    tags$div(class = "kpi-value", paste0("$ ", format_num(kpi_avg_cost))),
                    tags$div(class = "kpi-sub", "per client")
                ),
                tags$div(
                    class = "kpi-card green",
                    tags$div(class = "kpi-label", "Low Risk"),
                    tags$div(class = "kpi-value", paste0(kpi_low_pct, "%")),
                    tags$div(class = "kpi-sub", "< $10,000")
                ),
                tags$div(
                    class = "kpi-card orange",
                    tags$div(class = "kpi-label", "Medium Risk"),
                    tags$div(class = "kpi-value", paste0(kpi_medium_pct, "%")),
                    tags$div(class = "kpi-sub", "$10K – $30K")
                ),
                tags$div(
                    class = "kpi-card red",
                    tags$div(class = "kpi-label", "High Risk"),
                    tags$div(class = "kpi-value", paste0(kpi_high_pct, "%")),
                    tags$div(class = "kpi-sub", "> $30,000")
                )
            ),
            
            fluidRow(
                box(
                    title = "Client Information",
                    width = 4,
                    status = "primary",
                    solidHeader = TRUE,
                    numericInputCustom("age", "Age:", 30, min = 18, max = 100),
                    numericInputCustom(
                        "bmi",
                        "BMI:",
                        25,
                        min = 1,
                        max = 100,
                        step = 0.1
                    ),
                    selectInput("smoker", "Smoker:", c("yes", "no")),
                    numericInputCustom("children", "Children:", 0, min = 0, max = 20),
                    br(),
                    actionButton("predict", "Predict", class = "btn-primary", width = "100%"),
                    br(),
                    br(),
                    
                    uiOutput("export_ui")
                ),
                
                column(
                    width = 8,
                    uiOutput("result_box"),
                    br(),
                    
                    box(
                        title = "Prediction History",
                        width = 12,
                        DT::dataTableOutput("history_table")
                    )
                )
                
            )
        )
    ))
)

# ===== SERVER =====
server <- function(input, output) {
    # Store prediction history during user session
    history <- reactiveVal(
        data.frame(
            Time           = character(),
            Age            = numeric(),
            BMI            = numeric(),
            Smoker         = character(),
            Children       = numeric(),
            Predicted_Cost = numeric(),
            Risk           = character(),
            stringsAsFactors = FALSE
        )
    )
    
    # Render prediction history table
    output$history_table <- DT::renderDataTable({
        DT::datatable(
            history(),
            options = list(pageLength = 5, autoWidth = TRUE),
            rownames = FALSE
        )
    })
    
    
    
    
    prediction <- eventReactive(input$predict, {
        # Convert inputs (supports Arabic numerals)
        age_val      <- to_english_digits(input$age)
        bmi_val      <- to_english_digits(input$bmi)
        children_val <- to_english_digits(input$children)
        # Validate user input
        validate(
            need(!is.na(age_val), "Please enter a valid Age"),
            need(!is.na(bmi_val), "Please enter a valid BMI"),
            need(
                !is.na(children_val),
                "Please enter a valid number of Children"
            )
        )
        
        new_data <- data.frame(
            age = age_val,
            bmi = bmi_val,
            smoker = input$smoker,
            children = children_val
        )
        # Generate prediction
        res  <- predict_clients(new_data, model_glm, levels(df$smoker))
        
        new_row <- data.frame(
            Time           = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            Age            = age_val,
            BMI            = bmi_val,
            Smoker         = input$smoker,
            Children       = children_val,
            Predicted_Cost = res$predicted_cost,
            Risk           = res$risk
        )
        
        # Save to session history
        data <- history()
        history(rbind(data, new_row))
        
        return(res)
    })
    
    
    # Render export section dynamically based on history
    output$export_ui <- renderUI({
        data <- history()
        
        if (is.null(data) || nrow(data) == 0) {
            return(tags$div(
                class = "export-wrap",
                tags$div(
                    class = "export-info",
                    icon("info-circle", style = "margin-right:6px;"),
                    "No predictions yet — click Predict to start"
                )
            ))
        }
        
        n <- nrow(data)
        
        label <- if (n == 1) {
            "1 prediction ready to export"
        } else {
            paste0(n, " predictions ready to export")
        }
        
        tags$div(
            class = "export-wrap",
            tags$div(
                class = "export-info",
                icon("table", style = "margin-right:6px;"),
                tags$span(label)
            ),
            # Download prediction history as CSV
            downloadButton(
                "download_csv",
                "Export CSV",
                class = "btn-export",
                icon = icon("download")
            )
        )
    })
    
    
    # Handle CSV export for prediction history
    output$download_csv <- downloadHandler(
        filename = function() {
            paste0("predictions_",
                   format(Sys.time(), "%Y%m%d_%H%M%S"),
                   ".csv")
        },
        content = function(file) {
            data <- history()
            if (nrow(data) == 0)
                return(NULL)
            
            write.csv(data, file, row.names = FALSE)
        }
    )
    
    
    # ===== RESULT BOX =====
    output$result_box <- renderUI({
        req(prediction())
        res <- prediction()
        
        box_status <- ifelse(
            res$risk == "Low Risk",
            "success",
            ifelse(res$risk == "Medium Risk", "warning", "danger")
        )
        
        risk_color <- ifelse(
            res$risk == "Low Risk",
            "#2ECC71",
            ifelse(res$risk == "Medium Risk", "#F39C12", "#E74C3C")
        )
        
        icon_name <- ifelse(
            res$risk == "Low Risk",
            "check-circle",
            ifelse(
                res$risk == "Medium Risk",
                "exclamation-triangle",
                "times-circle"
            )
        )
        
        box(
            title = "Prediction Result",
            width = 12,
            status = box_status,
            solidHeader = TRUE,
            
            h1(tagList(
                icon("money", style = "color:#2ECC71; margin-right:10px;"),
                paste0("$ ", format_num(res$predicted_cost))
            ), style = "text-align:center; font-weight:700;"),
            
            br(),
            
            div(
                style = "text-align:center;",
                icon(
                    icon_name,
                    style = paste0("color:", risk_color, "; font-size:28px;")
                ),
                span(
                    style = paste0(
                        "color:",
                        risk_color,
                        "; font-weight:bold; margin-left:10px; font-size:22px;"
                    ),
                    res$risk
                )
            )
        )
    })
}

# ===== RUN APP =====
shinyApp(ui, server)
