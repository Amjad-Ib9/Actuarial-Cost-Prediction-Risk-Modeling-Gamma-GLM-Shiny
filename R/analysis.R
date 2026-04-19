
# Portfolio Analysis Script

source("R/data_prep.R")
source("R/model.R")
source("R/functions.R")

# ==============================
# Model Evaluation
# ==============================

pred <- predict(model_glm, newdata = df, type = "response")
mspe <- mean((df$charges - pred)^2)
cat("MSPE:", round(mspe, 2), "\n")



portfolio_results <- predict_clients(
    df,
    model_glm,
    levels(df$smoker)
)

# Overview

head(portfolio_results)

# ==============================
# Portfolio Distribution
# ==============================

table(portfolio_results$risk)
risk_dist <- prop.table(table(portfolio_results$risk))
print(round(risk_dist, 3))


# ==============================
# Cost Analysis
# ==============================

cat("\n--- Portfolio Summary ---\n")
cat("Average Predicted Cost:", round(mean(portfolio_results$predicted_cost), 2), "\n")

cat("\n--- Average Cost by Risk Level ---\n")
aggregate(predicted_cost ~ risk, data = portfolio_results, mean)

cat("\n--- Cost Contribution by Risk ---\n")
cost_share <- aggregate(predicted_cost ~ risk, data = portfolio_results, sum)
cost_share$percentage <- round(cost_share$predicted_cost / sum(cost_share$predicted_cost) * 100, 2)
print(cost_share)

if (!dir.exists("outputs")) {
    dir.create("outputs")
}

write.csv(portfolio_results, "outputs/predictions.csv", row.names = FALSE)


# ==============================
# Risk Drivers
# ==============================

cat("\n--- Risk Drivers (Smoking vs Risk) ---\n")
print(table(portfolio_results$smoker, portfolio_results$risk))

# ==============================
# High Risk Analysis
# ==============================

high_risk <- subset(portfolio_results, risk == "High Risk")
summary(high_risk)
table(high_risk$smoker)
cat("\n--- High Risk Profile ---\n")
cat("Average BMI:", round(mean(high_risk$bmi), 2), "\n")
cat("Average Age:", round(mean(high_risk$age), 2), "\n")

hist(portfolio_results$predicted_cost, breaks = 30,
     main = "Distribution of Predicted Costs",
     xlab = "Predicted Cost",
     col = "lightblue")

boxplot(predicted_cost ~ risk, data = portfolio_results,
        col = c("green", "orange", "red"),
        main = "Predicted Cost by Risk Level",
        ylab = "Predicted Cost")



