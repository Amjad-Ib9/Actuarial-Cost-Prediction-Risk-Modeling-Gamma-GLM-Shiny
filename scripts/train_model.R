# ==============================
# Train Insurance Model
# ==============================

library(tidyverse)

# Check dataset exists
if (!file.exists("insurance.csv")) {
    stop("Dataset not found. Please add insurance.csv")
}

# Load data
df <- read_csv("insurance.csv")

# Data preparation (same as app)
df <- df %>%
    mutate(
        sex = as.factor(sex),
        smoker = as.factor(smoker),
        region = as.factor(region)
    )

# Train Gamma GLM (final model)
model_glm <- glm(
    charges ~ age + bmi + smoker + children,
    family = Gamma(link = "log"),
    data = df
)

# Save model
saveRDS(model_glm, "model.rds")

cat("Model trained and saved as model.rds\n")
