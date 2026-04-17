# Actuarial Pricing & Risk Modeling (Gamma GLM + Shiny)

## Overview

This project develops an end-to-end actuarial pricing system for health insurance using a Gamma Generalized Linear Model (GLM). The system estimates expected medical costs, classifies policyholders into risk segments, and provides interactive visualization through a Shiny dashboard.

## Objectives

* Predict individual insurance costs based on risk factors
* Segment customers into risk categories (Low, Medium, High)
* Analyze portfolio-level risk distribution
* Build an interactive pricing tool for decision-making

## Dataset

The dataset contains information on policyholders, including:

* Age
* BMI (Body Mass Index)
* Smoking status
* Number of children
* Medical insurance charges (target variable)

## Methodology

### 1. Exploratory Data Analysis (EDA)

* Identified skewed distribution of insurance costs
* Detected strong impact of smoking on costs
* Observed interaction effects between BMI and smoking

### 2. Feature Engineering

* Created interaction terms (BMI × Smoking)
* Applied log transformation to handle skewness
* Segmented variables for better interpretability

### 3. Modeling

* Built multiple models for comparison:

  * Linear Regression
  * Log-Linear Model
  * Gamma GLM (final model)

* Selected Gamma GLM due to:

  * Positive and skewed nature of cost data
  * Better statistical fit (AIC comparison)
  * Interpretability in actuarial context

### 4. Prediction System

* Developed reusable functions for:

  * Individual prediction
  * Risk classification
  * Batch prediction (portfolio-level analysis)

### 5. Portfolio Analysis

* Evaluated risk distribution across policyholders
* Identified concentration of costs among high-risk groups
* Analyzed contribution of smoking to overall risk

### 6. Shiny Dashboard

* Built an interactive dashboard for:

  * Real-time cost prediction
  * Risk classification
  * Visualization of client position within the portfolio

## Key Insights

* Smoking is the most significant risk driver
* High-risk individuals contribute disproportionately to total costs
* Clear segmentation exists between low-risk and high-risk groups
* Cost distribution is highly skewed, justifying the use of Gamma GLM

## Tools & Technologies

* R (data analysis, modeling)
* Gamma GLM (statistical modeling)
* Shiny (interactive dashboard)
* GitHub (version control)

## Project Structure

* `data/` → dataset
* `R/` → data processing, modeling, and functions
* `app/` → Shiny dashboard
* `outputs/` → prediction results

## Future Improvements

* API deployment for real-time pricing
* Advanced feature engineering
* Model validation and performance metrics
* Integration with external data sources

## Author

[Amjad Alsurayyi]
