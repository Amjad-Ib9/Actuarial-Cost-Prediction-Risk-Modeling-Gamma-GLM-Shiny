# Insurance Cost Prediction & Risk Classification

A machine learning project that predicts healthcare insurance costs and classifies clients into risk categories using R.

---

## Overview

This project builds a two-stage predictive system:
- **Stage 1 — Regression:** Predict the insurance cost for a client as a numeric value
- **Stage 2 — Classification:** Classify the client into a risk category (Low / Medium / High)

An interactive Shiny Dashboard allows users to input client data and receive instant predictions.

---

## Dataset

The dataset contains **1,338 records** with the following variables:

| Variable | Type | Description |
|----------|------|-------------|
| age | Numeric | Age of the client |
| sex | Categorical | Gender (male / female) |
| bmi | Numeric | Body Mass Index |
| children | Numeric | Number of children |
| smoker | Categorical | Smoking status (yes / no) |
| region | Categorical | US region (northeast / northwest / southeast / southwest) |
| charges | Numeric | Medical insurance cost (target variable) |

---

## Project Structure

```
├── analysis.R            # Full analysis and model training
├── app.R                 # Shiny Dashboard
├── insurance.csv         # Dataset
├── model_linear4.rds     # Best regression model
├── model_RF_class.rds    # Best classification model
├── risk_quantiles.rds    # Risk category thresholds
└── README.md
```

---

## Methodology

### 1. Exploratory Data Analysis (EDA)
- Cost distribution analysis
- Relationship between each variable and cost
- Correlation matrix

### 2. Feature Engineering
- **bmi_cat:** BMI categories (Underweight / Normal / Overweight / Obese)
- **age_cat:** Age groups (Young / Middle / Senior)
- **bmi30:** Binary variable — smoker with BMI ≥ 30 (key engineered feature)

### 3. Regression Models

| Model | MAE | RMSE |
|-------|-----|------|
| Linear 1 (baseline) | 4184.86 | 6289.89 |
| Linear 2 | 3064.74 | 5229.37 |
| Gamma | 4149.10 | 7681.36 |
| Linear 3 | 2976.03 | 5073.79 |
| **Linear 4 (best)** | **2399.34** | **4685.76** |
| Log | 4102.72 | 7946.51 |
| Log 2 | 4085.34 | 8381.53 |
| Random Forest | 2815.25 | 4925.02 |
| XGBoost | 2995.46 | 5373.28 |

### 4. Risk Classification

Risk categories defined by charge percentiles:
- **Low:** Below 33rd percentile
- **Medium:** Between 33rd and 66th percentile
- **High:** Above 66th percentile

| Model | Accuracy | Kappa |
|-------|----------|-------|
| **Random Forest (best)** | **91%** | **0.87** |
| XGBoost | 89.5% | 0.84 |

### 5. Feature Importance

All three models agree on the top predictors:
1. **bmi30** — Smoker with obesity (strongest predictor)
2. **age** — Client age
3. **smoker** — Smoking status

---

## Key Findings

- Smokers with BMI ≥ 30 represent the highest risk group by a significant margin
- The engineered variable `bmi30` improved regression MAE by **43%** compared to the baseline model
- Age is the most continuously influential variable across all models
- Sex and region have minimal impact on cost prediction

---

## Shiny Dashboard

The dashboard includes three pages:

**1. Prediction**
Input client data and receive:
- Predicted insurance cost
- Risk level (Low / Medium / High) with color coding

**2. Model Comparison**
Table and chart comparing all regression models by MAE and RMSE

**3. Data Analysis**
Interactive EDA plots including cost distribution, age vs cost, BMI vs cost, and correlation matrix

---

## Requirements

```r
install.packages(c(
  "tidyverse",
  "caret",
  "Metrics",
  "lmtest",
  "randomForest",
  "xgboost",
  "corrplot",
  "shiny",
  "shinydashboard"
))
```

---

## How to Run

**Run the analysis:**
```r
source("analysis.R")
```

**Launch the dashboard:**
```r
shiny::runApp("app.R")
```

---

## Tools & Libraries

- **Language:** R
- **Modeling:** caret, randomForest, xgboost
- **Visualization:** ggplot2, corrplot
- **Dashboard:** Shiny, shinydashboard
