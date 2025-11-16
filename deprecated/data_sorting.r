# ==============================================================================
# Data Sorting Pipeline
# ==============================================================================
# Main data processing pipeline that processes and merges multiple datasets
# This script now uses modular functions from the data_cleaning/ directory for better organization
#
# For the modular version, see data_cleaning/10_main.R
# Individual processing functions are available in:
#   - data_cleaning/01_utils.R
#   - data_cleaning/02_process_rayyaan.R
#   - data_cleaning/03_process_amaani.R
#   - data_cleaning/04_load_ellie.R
#   - data_cleaning/05_merge_datasets.R
#   - data_cleaning/06_create_4yr_averages.R
#   - data_cleaning/07_load_medals.R
#   - data_cleaning/08_merge_medals.R
#   - data_cleaning/09_compare_countries.R (optional diagnostics)

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

# ==============================================================================
# Run Pipeline
# ==============================================================================

# Step 1: Process rayyaan_data.csv
rayyaan_wide <- process_rayyaan()

# Step 2: Process amaani_data.csv
amaani_wide <- process_amaani()

# Step 3: Load ellie_data.csv
ellie_wide <- load_ellie()

# Step 4: Merge all three datasets
merged_data <- merge_datasets(rayyaan_wide, amaani_wide, ellie_wide)

# Step 5: Create 4-year averages
merged_data <- create_4yr_averages_pipeline(merged_data)

# Step 6: Load medals data
medals <- load_medals()

# Step 7: Merge with medals data
merged_data <- merge_medals(merged_data, medals)

# Final merged_data is now available in the environment
#merged_data <- merged_data[ !is.na(total)]

# ==================================================