# ==============================
# Data Preparation Functions
# ==============================

library(tidyverse)

# Load and prepare dataset
prepare_data <- function(file_path = "insurance.csv") {
    
    # Read data
    df <- read_csv(file_path)
    
    # Transform variables
    df <- df %>%
        mutate(
            sex = as.factor(sex),
            smoker = as.factor(smoker),
            region = as.factor(region),
            log_charges = log(charges)
        )
    
    # Validate dataset
    if (any(is.na(df))) {
        stop("Dataset contains missing values")
    }
    
    return(df)
}
