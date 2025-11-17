# Data Cleaning Pipeline v2 - Documentation

## Overview
This directory contains adapted data cleaning scripts for processing the new data files from `fresh_data/`.

## New Data Files
- `fresh_data/rayyaan_2.csv` - Prevalence of overweight data in wide format (years as columns)
- `fresh_data/Amaani_2.csv` - Various socioeconomic indicators in long format
- `fresh_data/ellie_2.csv` - Economic indicators already in wide format

## Key Differences from Original Pipeline

### Data Format Changes

1. **rayyaan_2.csv**
   - **Old format**: Long format with columns: `Country`, `Year`, `Indicator`, `Value`
   - **New format**: Wide format with columns: `country`, `code`, `indicator`, `1992`, `1993`, ..., `2024`
   - **Adaptation**: Script now melts the wide format to long, then converts to wide with indicators as columns

2. **Amaani_2.csv**
   - **Old format**: Column names were `Country Name`, `Country Code`, `Series Name`, `Year`, `Value`
   - **New format**: Column names are `Country Name`, `Country Code`, `Series Name`, `Time`, `Value`
   - **Adaptation**: Script renames `Time` to `Year` for consistency

3. **ellie_2.csv**
   - No significant format changes, remains in wide format

### New Series in Amaani_2.csv
The updated `series_names.csv` now includes mappings for additional series:
- Gross capital formation (current US$)
- Gross fixed capital formation (% of GDP)
- Gross fixed capital formation (current US$)
- Military expenditure (current USD)
- Multidimensional poverty headcount ratio (UNDP)
- Poverty headcount ratio at $3.00 a day (2021 PPP)
- Social contributions (% of revenue)
- Tax revenue (% of GDP)

## File Structure

### Processing Scripts (v2)
- `02_process_rayyaan_v2.R` - Processes rayyaan_2.csv (handles wide-to-long-to-wide conversion)
- `03_process_amaani_v2.R` - Processes Amaani_2.csv (renames Time to Year)
- `04_load_ellie_v2.R` - Loads ellie_2.csv
- `10_main_v2.R` - Main orchestrator script for v2 pipeline

### Shared Scripts (unchanged)
- `01_utils.R` - Utility functions (avg_non_na, create_4yr_averages)
- `05_merge_datasets.R` - Merges three datasets by Country Name and Year
- `06_create_4yr_averages.R` - Creates overlapping 4-year averages
- `07_load_medals.R` - Loads Olympic medals data
- `08_merge_medals.R` - Merges medals with processed data
- `09_compare_countries.R` - Diagnostic comparison functions

## Usage

### Basic Usage
```r
source("data_cleaning/10_main_v2.R")

# Run the complete pipeline
merged_data <- run_pipeline_v2()
```

### With Options
```r
source("data_cleaning/10_main_v2.R")

# Run pipeline with output saving and diagnostics
merged_data <- run_pipeline_v2(
  save_output = TRUE,
  output_path = "output/merged_data_v2.csv",
  run_diagnostics = TRUE
)
```

### Individual Processing
```r
# Process individual datasets
source("data_cleaning/01_utils.R")
source("data_cleaning/02_process_rayyaan_v2.R")
source("data_cleaning/03_process_amaani_v2.R")
source("data_cleaning/04_load_ellie_v2.R")

rayyaan_wide <- process_rayyaan_v2()
amaani_wide <- process_amaani_v2()
ellie_wide <- load_ellie_v2()
```

## Pipeline Steps

1. **Process Rayyaan Data** (`02_process_rayyaan_v2.R`)
   - Reads wide format data (years as columns)
   - Melts to long format
   - Converts to wide format with indicators as columns
   - Renames columns to match pipeline standards

2. **Process Amaani Data** (`03_process_amaani_v2.R`)
   - Reads long format data
   - Renames `Time` column to `Year`
   - Maps series names using `series_names.csv`
   - Converts to wide format with sanitized column names

3. **Load Ellie Data** (`04_load_ellie_v2.R`)
   - Loads already-wide format data
   - Ensures Year is integer type

4. **Merge Datasets** (`05_merge_datasets.R`)
   - Merges all three datasets on Country Name and Year
   - Handles missing values appropriately

5. **Create 4-Year Averages** (`06_create_4yr_averages.R`)
   - Creates overlapping 4-year periods:
     - Cycle 1: 2012, 2016, 2020, 2024
     - Cycle 2: 2014, 2018, 2022, 2026
   - Aggregates numeric columns using averages

6. **Load Medals** (`07_load_medals.R`)
   - Loads historical Olympic medals data
   - Includes Paris 2024 medals

7. **Merge Medals** (`08_merge_medals.R`)
   - Merges medals data with processed data
   - Matches by Country Name/Code and Year

## Dependencies
- `data.table` - for efficient data manipulation

## Notes
- All v2 scripts maintain backward compatibility with the original pipeline structure
- The series_names.csv file has been updated to include new indicators
- Original processing scripts (without _v2 suffix) remain unchanged and work with original data files
- Missing values are handled consistently across all transformations
