
# EDA Script


source("R/data_prep.R")
library(ggplot2)

# ==============================
# Data Summary 
# ==============================

str(df)
summary(df)
summary(df$charges)

# ===================================
# Distribution of Target 
# ===================================
ggplot(df, aes(x = charges)) +
    geom_histogram(bins = 30, fill = "skyblue") +
    labs(title = "Distribution of Medical Charges") +
    theme_minimal()


# ===================================
# Smoking vs Charges 
# ===================================

ggplot(df, aes(x = smoker, y = charges)) +
    geom_boxplot(fill = "orange") +
    labs(title = "Charges by Smoking Status") +
    theme_minimal()


# ==================================
# Age vs Charges
# ==================================

ggplot(df, aes(x = age, y = charges)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "lm", color = "red") +
    labs(title = "Age vs Charges") +
    theme_minimal()

# =================================
# BMI vs Charges
# =================================

ggplot(df, aes(x = bmi, y = charges)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "lm", color = "green") +
    labs(title = "BMI vs Charges") +
    theme_minimal()


# ================================
# Interaction: BMI & Smoking
# ================================

ggplot(df, aes(x = bmi, y = charges, color = smoker)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "lm", se = FALSE)+
    labs(title = "BMI vs Charges by Smoking Status")


