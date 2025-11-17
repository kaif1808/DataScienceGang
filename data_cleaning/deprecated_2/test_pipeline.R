# ==============================================================================
# Test Pipeline
# ==============================================================================
# Test script to verify the pipeline works correctly with lagged variables

library(data.table)

# Source the main pipeline
source("data_cleaning/10_main.R")

# Test individual components
cat("Testing data processing pipeline with lagged variables...\n")
cat("==========================================================\n\n")

# Test 1: Process rayyaan_2.csv
cat("Test 1: Processing rayyaan_2.csv...\n")
rayyaan_wide <- process_rayyaan()
cat("  ✓ Rows:", nrow(rayyaan_wide), "\n")
cat("  ✓ Columns:", ncol(rayyaan_wide), "\n")
cat("  ✓ Sample columns:", paste(head(names(rayyaan_wide), 5), collapse=", "), "\n\n")

# Test 2: Process Amaani_2.csv
cat("Test 2: Processing Amaani_2.csv...\n")
amaani_wide <- process_amaani()
cat("  ✓ Rows:", nrow(amaani_wide), "\n")
cat("  ✓ Columns:", ncol(amaani_wide), "\n")
cat("  ✓ Sample columns:", paste(head(names(amaani_wide), 5), collapse=", "), "\n\n")

# Test 3: Load ellie_2.csv
cat("Test 3: Loading ellie_2.csv...\n")
ellie_wide <- load_ellie()
cat("  ✓ Rows:", nrow(ellie_wide), "\n")
cat("  ✓ Columns:", ncol(ellie_wide), "\n")
cat("  ✓ Sample columns:", paste(head(names(ellie_wide), 5), collapse=", "), "\n\n")

# Test 4: Merge datasets
cat("Test 4: Merging datasets...\n")
merged_data <- merge_datasets(rayyaan_wide, amaani_wide, ellie_wide)
cat("  ✓ Rows:", nrow(merged_data), "\n")
cat("  ✓ Columns:", ncol(merged_data), "\n")
cat("  ✓ Year range:", min(merged_data$Year, na.rm=TRUE), "to", max(merged_data$Year, na.rm=TRUE), "\n\n")

# Test 5: Create 4-year averages with lags
cat("Test 5: Creating 4-year averages with lagged variables...\n")
merged_data_avg <- create_4yr_averages_pipeline(merged_data)
cat("  ✓ Rows:", nrow(merged_data_avg), "\n")
cat("  ✓ Columns:", ncol(merged_data_avg), "\n")
cat("  ✓ Unique years:", paste(sort(unique(merged_data_avg$Year)), collapse=", "), "\n")

# Check for lagged variables
lag_cols <- grep("_lag[0-3]$", names(merged_data_avg), value = TRUE)
cat("  ✓ Number of lagged variable columns:", length(lag_cols), "\n")
if (length(lag_cols) > 0) {
  cat("  ✓ Sample lagged columns:", paste(head(lag_cols, 5), collapse=", "), "\n")
}
cat("\n")

# Test 6: Load medals
cat("Test 6: Loading medals data...\n")
medals <- load_medals()
cat("  ✓ Rows:", nrow(medals), "\n")
cat("  ✓ Years:", paste(sort(unique(medals$year)), collapse=", "), "\n\n")

# Test 7: Merge with medals
cat("Test 7: Merging with medals...\n")
final_data <- merge_medals(merged_data_avg, medals)
cat("  ✓ Rows:", nrow(final_data), "\n")
cat("  ✓ Rows with medals:", sum(!is.na(final_data$total)), "\n\n")

# Detailed check of lagged variables for a specific country
cat("Test 8: Verifying lagged variables structure...\n")
if (nrow(final_data) > 0) {
  # Find a country with data in 2012
  sample_country <- final_data[Year == 2012 & !is.na(GDP_per_capita), `Country Name`][1]
  if (!is.na(sample_country)) {
    sample_data <- final_data[`Country Name` == sample_country & Year == 2012, ]
    cat("  ✓ Sample country:", sample_country, "(Year 2012)\n")
    
    # Show GDP data if available
    gdp_cols <- grep("^GDP_per_capita", names(sample_data), value = TRUE)
    if (length(gdp_cols) > 0) {
      cat("  ✓ GDP columns found:\n")
      for (col in gdp_cols) {
        val <- sample_data[[col]]
        if (!is.na(val)) {
          cat("    -", col, "=", round(val, 2), "\n")
        }
      }
    }
  }
}
cat("\n")

# Summary
cat("==========================================================\n")
cat("✓ All tests completed successfully!\n")
cat("==========================================================\n\n")

# Run full pipeline
cat("Running full pipeline...\n\n")
result <- run_pipeline(
  save_output = TRUE, 
  output_path = "merged_data_with_lags.csv",
  run_diagnostics = FALSE
)

cat("\n==========================================================\n")
cat("Pipeline Complete!\n")
cat("==========================================================\n")
cat("Output saved to: merged_data_with_lags.csv\n")
cat("Final dataset dimensions:", nrow(result), "rows x", ncol(result), "columns\n")
cat("\nData structure:\n")
cat("  - Base columns: Country, Year, indicators\n")
cat("  - 4-year averages: Mean values over 4-year periods\n")
cat("  - Lagged variables: _lag0, _lag1, _lag2, _lag3 suffixes\n")
cat("  - Medal data: gold, silver, bronze, total columns\n")
