# ==============================================================================
# Main Data Processing Pipeline
# ==============================================================================
# Orchestrator script that runs the entire data processing pipeline
# Sources all required scripts and executes them in sequence

# Load required libraries
library(data.table)

# Source all module scripts in pipeline order
source("data_cleaning/01_utils.R")
source("data_cleaning/02_process_rayyaan.R")
source("data_cleaning/03_process_amaani.R")
source("data_cleaning/04_load_ellie.R")
source("data_cleaning/05_merge_datasets.R")
source("data_cleaning/06_create_4yr_averages.R")
source("data_cleaning/07_load_medals.R")
source("data_cleaning/08_merge_medals.R")
source("data_cleaning/09_compare_countries.R")

# ==============================================================================
# Run Pipeline
# ==============================================================================

run_pipeline <- function(save_output = FALSE, output_path = NULL, 
                        run_diagnostics = FALSE) {
  # Step 1: Process rayyaan_data.csv
  cat("Processing rayyaan_data.csv...\n")
  rayyaan_wide <- process_rayyaan()
  
  # Step 2: Process amaani_data.csv
  cat("Processing amaani_data.csv...\n")
  amaani_wide <- process_amaani()
  
  # Step 3: Load ellie_data.csv
  cat("Loading ellie_data.csv...\n")
  ellie_wide <- load_ellie()
  
  # Step 4: Merge all three datasets
  cat("Merging datasets...\n")
  merged_data <- merge_datasets(rayyaan_wide, amaani_wide, ellie_wide)
  
  # Step 5: Create 4-year averages
  cat("Creating 4-year averages...\n")
  merged_data <- create_4yr_averages_pipeline(merged_data)
  
  # Step 6: Load medals data
  cat("Loading medals data...\n")
  medals <- load_medals()
  
  # Step 7: Merge with medals data
  cat("Merging with medals data...\n")
  merged_data <- merge_medals(merged_data, medals)
  
  # Optional: Run diagnostics
  if (run_diagnostics) {
    cat("Running country comparison diagnostics...\n")
    comparison_results <- compare_countries(merged_data, medals)
    cat("Diagnostics complete.\n")
  }
  
  # Optional: Save output
  if (save_output && !is.null(output_path)) {
    cat("Saving output to", output_path, "...\n")
    fwrite(merged_data, output_path)
  }
  
  cat("Pipeline complete!\n")
  return(merged_data)
}

# If running directly (not sourced), execute the pipeline
if (!interactive()) {
  merged_data <- run_pipeline()
}

