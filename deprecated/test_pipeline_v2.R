# ==============================================================================
# Test Pipeline v2
# ==============================================================================
# Quick test script to verify the v2 pipeline works correctly

library(data.table)

# Source the main pipeline
source("data_cleaning/10_main_v2.R")

# Test individual components
cat("Testing individual processing functions...\n\n")

# Test 1: Process rayyaan_2.csv
cat("Test 1: Processing rayyaan_2.csv...\n")
rayyaan_wide <- process_rayyaan_v2()
cat("  - Rows:", nrow(rayyaan_wide), "\n")
cat("  - Columns:", ncol(rayyaan_wide), "\n")
cat("  - Sample columns:", paste(head(names(rayyaan_wide), 5), collapse=", "), "\n\n")

# Test 2: Process Amaani_2.csv
cat("Test 2: Processing Amaani_2.csv...\n")
amaani_wide <- process_amaani_v2()
cat("  - Rows:", nrow(amaani_wide), "\n")
cat("  - Columns:", ncol(amaani_wide), "\n")
cat("  - Sample columns:", paste(head(names(amaani_wide), 5), collapse=", "), "\n\n")

# Test 3: Load ellie_2.csv
cat("Test 3: Loading ellie_2.csv...\n")
ellie_wide <- load_ellie_v2()
cat("  - Rows:", nrow(ellie_wide), "\n")
cat("  - Columns:", ncol(ellie_wide), "\n")
cat("  - Sample columns:", paste(head(names(ellie_wide), 5), collapse=", "), "\n\n")

# Test 4: Merge datasets
cat("Test 4: Merging datasets...\n")
merged_data <- merge_datasets(rayyaan_wide, amaani_wide, ellie_wide)
cat("  - Rows:", nrow(merged_data), "\n")
cat("  - Columns:", ncol(merged_data), "\n")
cat("  - Year range:", min(merged_data$Year, na.rm=TRUE), "to", max(merged_data$Year, na.rm=TRUE), "\n\n")

# Test 5: Create 4-year averages
cat("Test 5: Creating 4-year averages...\n")
merged_data_avg <- create_4yr_averages_pipeline(merged_data)
cat("  - Rows:", nrow(merged_data_avg), "\n")
cat("  - Unique years:", paste(sort(unique(merged_data_avg$Year)), collapse=", "), "\n\n")

# Test 6: Load medals
cat("Test 6: Loading medals data...\n")
medals <- load_medals()
cat("  - Rows:", nrow(medals), "\n")
cat("  - Years:", paste(sort(unique(medals$year)), collapse=", "), "\n\n")

# Test 7: Merge with medals
cat("Test 7: Merging with medals...\n")
final_data <- merge_medals(merged_data_avg, medals)
cat("  - Rows:", nrow(final_data), "\n")
cat("  - Rows with medals:", sum(!is.na(final_data$total)), "\n\n")

# Summary
cat("===========================================\n")
cat("All tests completed successfully!\n")
cat("===========================================\n\n")

# Run full pipeline
cat("Running full pipeline...\n\n")
result <- run_pipeline_v2(
  save_output = TRUE, 
  output_path = "merged_data_v2_test.csv",
  run_diagnostics = FALSE
)

cat("\nPipeline output saved to: merged_data_v2_test.csv\n")
cat("Final dataset dimensions:", nrow(result), "rows x", ncol(result), "columns\n")
