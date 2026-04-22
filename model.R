# Model Script

# ==============================
# Load prepared data
# ==============================
source("R/dataprep.R")

# ==============================
# Linear Model (Baseline)
# ==============================
model_linear <- lm(charges ~ age + bmi + smoker + children, data = df)

# ==============================
# Log-Linear Model
# ==============================
model_log <- lm(log_charges ~ age + bmi + smoker + children, data = df)

# ==============================
# Interaction Model
# ==============================
model_interaction <- lm(log_charges ~ age + bmi * smoker + children, data = df)

# ==============================
# Gamma GLM (Final Model)
# ==============================
model_glm <- glm(charges ~ age + bmi + smoker + children,
                 family = Gamma(link = "log"),
                 data = df)