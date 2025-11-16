# medals_merge_modular.R
#
# Purpose: Main orchestration script for the Olympic medal prediction pipeline.
# This script coordinates the execution of the modular data cleaning pipeline,
# ensuring sequential sourcing of all processing modules and final data cleanup.
#
# Modular Pipeline Overview:
# The pipeline is structured into 6 sequential modules, each handling a specific
# aspect of data processing:
#
# 1. 01_data_loading.R: Loads raw data files and performs initial preparation
#    - Loads Olympic windows (macroeconomic indicators), historical medals,
#      Paris 2024 medals, and participating countries
#    - Converts data to tibbles for consistent processing
#
# 2. 02_noc_mapping.R: Prepares NOC to ISO country code mappings and manual overrides
#    - Loads current and historical NOC-ISO mappings
#    - Combines mappings and handles code standardization
#    - Loads manual country override mappings for custom corrections
#
# 3. 03_standardization.R: Standardizes country names and preprocesses medal data
#    - Applies country name normalization for consistent matching
#    - Implements manual override corrections for problematic mappings
#    - Transforms Paris 2024 data to match historical format
#    - Adds standardized identifiers for cross-dataset matching
#
# 4. 04_medal_combination.R: Combines historical and Paris 2024 medal datasets
#    - Merges historical Olympic medal data with current Paris 2024 results
#    - Creates unified medal dataset spanning all Olympic Games
#    - Generates focused subset for modeling (medals_by_year)
#
# 5. 05_country_joining.R: Performs country matching and medal data joining
#    - Implements 3-stage joining logic: direct NOC, ISO->IOC mapping, name matching
#    - Validates country mappings against Olympic participation records
#    - Creates final modeling dataset combining predictors with medal outcomes
#    - Handles coalescing logic with clear priority order for match resolution
#
# 6. 06_output_generation.R: Handles final output generation and cleanup
#    - Writes final medal model input dataset to CSV
#    - Identifies and exports unmatched countries for manual review
#    - Performs fuzzy string matching to suggest potential country matches
#    - Generates mapping backlog and country reference tables
#    - Returns structured results list for further processing
#
# Execution Order:
# Modules must be sourced in strict numerical order (01-06) as each module
# depends on variables and data transformations from preceding modules.
# The pipeline maintains state through global environment variables.
#
# Final Cleanup Process:
# After pipeline execution, intermediate columns used during processing are
# removed from the final medal model input dataset. The following columns
# are removed from the 'medals' element of the results list:
# - country_source: Original country name before manual overrides
# - country_noc_source: Original NOC code before manual overrides
# - manual_mapping_note: Notes from manual override applications
# - country_std_noc_direct: Intermediate column from joining process
#
# This cleanup ensures the final dataset contains only modeling-relevant
# columns while preserving the raw data integrity for potential reprocessing.
#
# Output:
# Returns a cleaned results list containing:
# - medals: Final modeling dataset (medal_model_input with cleanup applied)
# - unmatched: Countries that could not be matched to Olympic records
# - mapping_backlog: Structured backlog for manual mapping review
# - reference: Country reference table for Olympic medal data
#
# Dependencies:
# - All 6 module scripts must exist in the same directory
# - Required R packages are loaded within each module
# - Source data files must be available in expected locations
#
# Usage: Source this script to execute the complete modular pipeline and
# obtain the cleaned final results for Olympic medal prediction modeling.

library(data.table)

# -----------------------------------------------------------------------------
# Source processing modules in sequential order -------------------------------
# -----------------------------------------------------------------------------

# Module 1: Data Loading
# Loads and prepares raw data files for processing
source("data_cleaning/01_data_loading.R")

# Module 2: NOC Mapping
# Prepares country code mappings and manual overrides
source("data_cleaning/02_noc_mapping.R")

# Module 3: Standardization
# Standardizes country names and preprocesses medal data
source("data_cleaning/03_standardization.R")

# Module 4: Medal Combination
# Combines historical and Paris 2024 medal datasets
source("data_cleaning/04_medal_combination.R")

# Module 5: Country Joining
# Performs country matching and creates final modeling dataset
source("data_cleaning/05_country_joining.R")

# Module 6: Output Generation
# Generates final outputs and returns results list
results <- source("data_cleaning/06_output_generation.R")$value

# -----------------------------------------------------------------------------
# Final data cleanup ----------------------------------------------------------
# -----------------------------------------------------------------------------

# Remove intermediate processing columns from the medal model input dataset
# These columns were used during pipeline processing but are not needed for modeling
columns_to_remove <- c("country_source", "country_noc_source", "manual_mapping_note", "country_std_noc_direct")

# Apply cleanup only to columns that actually exist in the dataset
# This prevents errors if some columns were already removed or don't exist
existing_columns <- intersect(columns_to_remove, colnames(results$medals))
cat("Columns before cleanup:", ncol(results$medals), "\n")
cat("Existing columns to remove:", paste(existing_columns, collapse = ", "), "\n")
if (length(existing_columns) > 0) {
  results$medals <- results$medals[, !names(results$medals) %in% existing_columns]
}
cat("Columns after cleanup:", ncol(results$medals), "\n")

# Re-write the cleaned medal model input to CSV
fwrite(results$medals, "../data/final_medals_model_input.csv")

# -----------------------------------------------------------------------------
# Return cleaned results ------------------------------------------------------
# -----------------------------------------------------------------------------

# Return the processed results list with cleaned medal dataset
# The results contain all final outputs ready for modeling or further analysis
results