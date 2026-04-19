
# Data Prep Script


# ==============================
# 1.Install Packages
# ==============================

#install.packages("tidyverse")
#install.packages("janitor")
#install.packages("skimr")

# ==============================
# 2. Load Packages
# ==============================

library(tidyverse)
library(janitor)
library(skimr)


# ==============================
# 3. Read Data
# ==============================
insurance_raw <- read_csv("data/insurance.csv")


# ==============================
# 4. Data Preparation
# ==============================

df <- insurance_raw %>%
    mutate(
        sex = as.factor(sex),
        smoker = as.factor(smoker),
        region = as.factor(region),
        log_charges = log(charges)
        
    )

# ==============================
# 5. Check missing value 
# ==============================
colSums(is.na(df))



















