# ==============================
# Portfolio Analysis Script
# ==============================

library(tidyverse)

# Load required functions
source("R/helpers.R")
source("R/prediction.R")

# Check required files
if (!file.exists("insurance.csv")) {
    stop("Dataset not found")
}



# Load data
df <- read_csv("insurance.csv") %>%
    mutate(
        sex = as.factor(sex),
        smoker = as.factor(smoker),
        region = as.factor(region)
    )


# ==============================
# Model Comparison
# ==============================

model_linear <- lm(charges ~ age + bmi + smoker + children, data = df)

model_log <- lm(log(charges) ~ age + bmi + smoker + children, data = df)

model_glm <- glm(
    charges ~ age + bmi + smoker + children,
    family = Gamma(link = "log"),
    data = df
)

# Predictions
pred_linear <- predict(model_linear, df)
pred_log <- exp(predict(model_log, df)) * exp(mean(residuals(model_log)^2)/2)
pred_glm <- predict(model_glm, df, type = "response")

# Errors
mspe_linear <- mean((df$charges - pred_linear)^2)
mspe_log <- mean((df$charges - pred_log)^2)
mspe_glm <- mean((df$charges - pred_glm)^2)


# MAE
mae_linear <- mean(abs(df$charges - pred_linear))
mae_log <- mean(abs(df$charges - pred_log))
mae_glm <- mean(abs(df$charges - pred_glm))


# AIC
aic_linear <- AIC(model_linear)
aic_log <- AIC(model_log)
aic_glm <- AIC(model_glm)


# Comparison table
model_comparison <- data.frame(
    Model = c("Linear", "Log-Linear", "Gamma GLM"),
    MSPE = c(mspe_linear, mspe_log, mspe_glm),
    MAE = c(mae_linear, mae_log, mae_glm),
    AIC = c(aic_linear, aic_log, aic_glm)
)

model_comparison$MSPE <- round(model_comparison$MSPE, 2)
model_comparison$MAE  <- round(model_comparison$MAE, 2)
model_comparison$AIC  <- round(model_comparison$AIC, 2)

print(model_comparison)

# ==============================
# Portfolio Prediction
# ==============================

# Using Gamma GLM due to its suitability for skewed positive data
portfolio_results <- predict_clients(
    df,
    model_glm,
    levels(df$smoker)
)

# ==============================
# Portfolio Distribution
# ==============================

cat("\n--- Risk Distribution ---\n")
print(table(portfolio_results$risk))

risk_dist <- prop.table(table(portfolio_results$risk))
print(round(risk_dist, 3))


# ==============================
# Cost Analysis
# ==============================

cat("\n--- Portfolio Summary ---\n")
cat("Average Predicted Cost:", round(mean(portfolio_results$predicted_cost), 2), "\n")

cat("\n--- Average Cost by Risk Level ---\n")
print(aggregate(predicted_cost ~ risk, data = portfolio_results, mean))

cat("\n--- Cost Contribution by Risk ---\n")
cost_share <- aggregate(predicted_cost ~ risk, data = portfolio_results, sum)
cost_share$percentage <- round(cost_share$predicted_cost / sum(cost_share$predicted_cost) * 100, 2)
print(cost_share)

# ==============================
# Save Results
# ==============================

if (!dir.exists("outputs")) {
    dir.create("outputs")
}

write.csv(portfolio_results, "outputs/predictions.csv", row.names = FALSE)

cat("\nResults saved to outputs/predictions.csv\n")

# ==============================
# Risk Drivers
# ==============================

cat("\n--- Risk Drivers (Smoking vs Risk) ---\n")
print(table(portfolio_results$smoker, portfolio_results$risk))

# ==============================
# High Risk Analysis
# ==============================

high_risk <- subset(portfolio_results, risk == "High Risk")

cat("\n--- High Risk Profile ---\n")
cat("Average BMI:", round(mean(high_risk$bmi), 2), "\n")
cat("Average Age:", round(mean(high_risk$age), 2), "\n")

# ==============================
# Visualization
# ==============================

hist(
    portfolio_results$predicted_cost,
    breaks = 30,
    main = "Distribution of Predicted Costs",
    xlab = "Predicted Cost",
    col = "lightblue"
)

boxplot(
    predicted_cost ~ risk,
    data = portfolio_results,
    col = c("green", "orange", "red"),
    main = "Predicted Cost by Risk Level",
    ylab = "Predicted Cost"
)
