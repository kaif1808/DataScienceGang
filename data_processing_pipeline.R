# ==============================================================================
# Data Processing Pipeline
# ==============================================================================
# This script combines CSV data files, extracts indicator-specific data tables,
# and merges them by Country and Year for analysis.
#
# Pipeline Steps:
#   1. Load and clean individual CSV files (Literacy, Life, Schooling, Obesity)
#   2. Reshape data from wide to long format
#   3. Combine all data into a single merged file
#   4. Extract separate data tables for each indicator
#   5. Merge indicators by Country and Year into a wide-format table
#
# Input Files:
#   - Literacy.csv
#   - Life.csv
#   - Schooling.csv
#   - Obesity.csv
#
# Output Files:
#   - merged_data_clean.csv (intermediate file with all indicators in long format)
#   - merged_indicators_by_country_year.csv (final wide-format table, optional)
#
# ==============================================================================

# Load required libraries
library(tidyverse)
library(data.table)

# ==============================================================================
# STEP 1: Load and Merge Individual CSV Files
# ==============================================================================
# This section reads multiple CSV files, cleans column names, reshapes from
# wide to long format, and combines them into a single dataset.

# Define files and their corresponding indicator names
file_info <- tibble(
  file = c("Literacy.csv", "Life.csv", "Schooling.csv", "Obesity.csv"),
  indicator = c("Literacy rate", "Life expectancy", "Schooling years", "Obesity rate")
)

# Function to clean and reshape each file from wide to long format
load_and_tidy <- function(fpath, indicator_label) {
  # Read the CSV file
  df <- read_csv(fpath, show_col_types = FALSE)
  
  # Clean column names: remove special characters and trim whitespace
  names(df) <- names(df) |>
    trimws() |>
    str_replace_all("?\\.\\.", "") |>
    str_replace_all("[^A-Za-z0-9_]", "")
  
  # Identify year columns (columns that are 4-digit years)
  year_cols <- names(df)[str_detect(names(df), "^[0-9]{4}$")]
  
  if (length(year_cols) == 0) {
    # Handle files that are already in long format
    if (all(c("Country", "Year", "Value") %in% names(df))) {
      df_long <- df
    } else {
      stop(paste("No year columns found in", fpath))
    }
  } else {
    # Convert from wide format (years as columns) to long format (Year as a column)
    df_long <- df %>%
      pivot_longer(
        cols = all_of(year_cols),
        names_to = "Year",
        values_to = "Value"
      ) %>%
      mutate(Year = as.integer(Year))
  }
  
  # Keep only relevant columns and add indicator label and source information
  df_long %>%
    select(Country, Year, Value) %>%
    mutate(
      Indicator = indicator_label,
      Source = basename(fpath),
      Value = as.numeric(Value)
    )
}

# Process all files and combine them into a single data frame
all_data <- map2_dfr(file_info$file, file_info$indicator, load_and_tidy)

# Filter to keep only data from 2009 onwards
all_data <- all_data %>% filter(Year >= 2009)

# Save the cleaned, merged data in long format
write_csv(all_data, "merged_data_clean.csv")

# ==============================================================================
# STEP 2: Extract Indicator-Specific Data Tables
# ==============================================================================
# This section reads the merged data file and creates separate data tables
# for each indicator, then merges them by Country and Year.

# Read the merged data file
merged_data <- fread("merged_data_clean.csv")

# Define the indicator values to extract
indicators <- c("Literacy rate", "Life expectancy", "Schooling years", "Obesity rate")

# Extract separate data tables for each indicator
for (indicator in indicators) {
  # Filter data for the current indicator
  indicator_data <- merged_data[Indicator == indicator]
  
  # Create a valid R variable name from the indicator
  # Remove spaces, convert to lowercase, and clean up naming
  var_name <- gsub(" ", "_", tolower(indicator))
  var_name <- gsub("_rate", "", var_name)  # Remove "rate" suffix for cleaner names
  
  # Assign to a data table with a descriptive name
  assign(paste0(var_name, "_data"), indicator_data)
}

# ==============================================================================
# STEP 3: Merge Indicators by Country and Year
# ==============================================================================
# This section combines all indicator data tables into a single wide-format
# table where each row represents a unique Country-Year combination and
# each indicator becomes a separate column.

# Start with literacy data, selecting only Country, Year, and Value columns
merged_indicators <- literacy_data[, .(Country, Year, Literacy_rate = Value)]

# Merge with life expectancy data (full outer join to keep all combinations)
merged_indicators <- merge(merged_indicators, 
                          life_expectancy_data[, .(Country, Year, Life_expectancy = Value)],
                          by = c("Country", "Year"), 
                          all = TRUE)

# Merge with schooling years data
merged_indicators <- merge(merged_indicators, 
                          schooling_years_data[, .(Country, Year, Schooling_years = Value)],
                          by = c("Country", "Year"), 
                          all = TRUE)

# Merge with obesity data
merged_indicators <- merge(merged_indicators, 
                          obesity_data[, .(Country, Year, Obesity_rate = Value)],
                          by = c("Country", "Year"), 
                          all = TRUE)

# Optional: Save the merged indicators data table to CSV
# Uncomment the following line to save the final merged table
# fwrite(merged_indicators, file = "merged_indicators_by_country_year.csv")

# ==============================================================================
# Available Data Objects After Running This Script:
# ==============================================================================
# Individual indicator data tables (long format):
#   - literacy_data: Contains all Literacy rate observations
#   - life_expectancy_data: Contains all Life expectancy observations
#   - schooling_years_data: Contains all Schooling years observations
#   - obesity_data: Contains all Obesity rate observations
#
# Merged data table (wide format):
#   - merged_indicators: Contains all indicators merged by Country and Year
#     Columns: Country, Year, Literacy_rate, Life_expectancy, Schooling_years, Obesity_rate
#
# ==============================================================================
