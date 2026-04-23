# ==============================
# Helper Functions
# ==============================

# Format numbers for display (rounded with comma separators)
format_num <- function(x) {
    format(round(x, 0), big.mark = ",", scientific = FALSE)
}

# Convert Arabic/Persian numerals to standard numeric format
to_english_digits <- function(x) {
    x <- as.character(x)
    
    x <- chartr(
        "\u0660\u0661\u0662\u0663\u0664\u0665\u0666\u0667\u0668\u0669",
        "0123456789", x
    )
    
    x <- chartr(
        "\u06F0\u06F1\u06F2\u06F3\u06F4\u06F5\u06F6\u06F7\u06F8\u06F9",
        "0123456789", x
    )
    
    as.numeric(x)
}


# Determine risk category based on predicted cost
get_risk_label <- function(cost) {
    ifelse(
        cost < 10000,
        "Low Risk",
        ifelse(cost < 30000, "Medium Risk", "High Risk")
    )
}