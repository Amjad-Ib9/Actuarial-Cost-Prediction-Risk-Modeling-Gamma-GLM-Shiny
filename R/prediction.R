# ==============================
# Prediction Functions
# ==============================

predict_clients <- function(data, model, smoker_levels) {
    
    # Validate required column
    if (!"smoker" %in% names(data)) {
        stop("Missing 'smoker' column")
    }
    
    # Ensure factor levels match training data
    data$smoker <- factor(data$smoker, levels = smoker_levels)
    
    # Generate prediction
    pred <- predict(model, newdata = data, type = "response")
    
    # Store results
    data$predicted_cost <- pred
    
    # Assign risk label
    data$risk <- get_risk_label(data$predicted_cost)
    
    return(data)
}