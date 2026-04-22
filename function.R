# Function Script

source("R/model.R")

predict_clients <- function(data, model, smoker_levels) {
    
    if (!"smoker" %in% names(data)) {
        stop("Missing 'smoker' column")
    }
    
    data$smoker <- factor(data$smoker, levels = smoker_levels)
    
    pred <- predict(model, newdata = data, type = "response")
    
    data$predicted_cost <- round(pred, 2)
    
    data$risk <- ifelse(data$predicted_cost < 10000, "Low Risk",
                        ifelse(data$predicted_cost < 30000, "Medium Risk", "High Risk"))
    
    data
}