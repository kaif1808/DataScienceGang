# Data Cleaning Pipeline

## Overview
This directory contains the complete data cleaning pipeline for processing Olympic and economic indicator data.

## Data Sources
- `fresh_data/rayyaan_2.csv` - Prevalence of overweight data
- `fresh_data/Amaani_2.csv` - Socioeconomic indicators
- `fresh_data/ellie_2.csv` - Economic indicators
- `data/Olympic_Medal_Tally_History.csv` - Historical Olympic medals
- `2024olympics/medals_total.csv` - Paris 2024 medals

## Pipeline Structure

### Processing Scripts
1. **`01_utils.R`** - Utility functions (avg_non_na, create_4yr_averages)
2. **`02_process_rayyaan.R`** - Processes rayyaan data (wide→long→wide transformation)
3. **`03_process_amaani.R`** - Processes amaani data with series name mapping
4. **`04_load_ellie.R`** - Loads ellie economic data
5. **`05_merge_datasets.R`** - Merges all three datasets by Country and Year
6. **`06_create_4yr_averages.R`** - Creates 4-year averages WITH lagged variables
7. **`07_load_medals.R`** - Loads Olympic medals data
8. **`08_merge_medals.R`** - Merges medals with processed data
9. **`09_compare_countries.R`** - Diagnostic functions
10. **`10_main.R`** - Main orchestrator script

## Key Feature: Lagged Variables

The pipeline now includes **lagged variables** at the 4-year averaging stage. For each target year (e.g., 2012, 2016, 2020, 2024), the pipeline creates:

- **4-year averages**: Mean of all numeric variables over the 4-year period
- **lag0 variables**: Values from the target year (e.g., GDP_lag0 = 2012 GDP value)
- **lag1 variables**: Values from 1 year before (e.g., GDP_lag1 = 2011 GDP value)
- **lag2 variables**: Values from 2 years before (e.g., GDP_lag2 = 2010 GDP value)
- **lag3 variables**: Values from 3 years before (e.g., GDP_lag3 = 2009 GDP value)

### Example Output Structure
For a country in year 2012:
```
Country Name: USA
Year: 2012
GDP_per_capita: 48000           # 4-year average (2009-2012)
GDP_per_capita_lag0: 50000      # 2012 value
GDP_per_capita_lag1: 49000      # 2011 value
GDP_per_capita_lag2: 47500      # 2010 value
GDP_per_capita_lag3: 45500      # 2009 value
```

### Statistical Validity
This approach is statistically valid for time-series analysis because:
1. **Captures trends**: Lagged variables allow models to capture temporal dependencies
2. **Reduces noise**: 4-year averages smooth out year-to-year fluctuations
3. **Preserves information**: Individual year values retained via lag variables
4. **Enables forecasting**: Can model how past values predict outcomes
5. **Common in econometrics**: Standard approach for panel data with temporal structure

## Usage

### Basic Usage
```r
source("data_cleaning/10_main.R")

# Run the complete pipeline
merged_data <- run_pipeline()
```

### With Options
```r
# Run pipeline with output saving and diagnostics
merged_data <- run_pipeline(
  save_output = TRUE,
  output_path = "output/merged_data.csv",
  run_diagnostics = TRUE
)
```

### Individual Processing
```r
# Process individual datasets
source("data_cleaning/01_utils.R")
source("data_cleaning/02_process_rayyaan.R")
source("data_cleaning/03_process_amaani.R")
source("data_cleaning/04_load_ellie.R")

rayyaan_wide <- process_rayyaan()
amaani_wide <- process_amaani()
ellie_wide <- load_ellie()
```

## Pipeline Steps

1. **Process Data Files**
   - Convert formats to wide structure
   - Standardize column names
   - Handle missing values

2. **Merge Datasets**
   - Join on Country Name and Year
   - Preserve all observations

3. **Create 4-Year Averages with Lags**
   - Two overlapping cycles: (2012, 2016, 2020, 2024) and (2014, 2018, 2022, 2026)
   - Calculate averages for numeric variables
   - Add lagged variables (t, t-1, t-2, t-3) for each target year

4. **Merge with Medals**
   - Add Olympic medal counts
   - Match by country name/code and year

## Target Years

### Cycle 1
- 2012 (2009-2012 average + lags: 2012, 2011, 2010, 2009)
- 2016 (2013-2016 average + lags: 2016, 2015, 2014, 2013)
- 2020 (2017-2020 average + lags: 2020, 2019, 2018, 2017)
- 2024 (2021-2024 average + lags: 2024, 2023, 2022, 2021)

### Cycle 2
- 2014 (2011-2014 average + lags: 2014, 2013, 2012, 2011)
- 2018 (2015-2018 average + lags: 2018, 2017, 2016, 2015)
- 2022 (2019-2022 average + lags: 2022, 2021, 2020, 2019)
- 2026 (2023-2026 average + lags: 2026, 2025, 2024, 2023)

## Dependencies
- `data.table` - Efficient data manipulation

## Configuration
- `series_names.csv` - Maps series names to clean column names

## Notes
- Missing values are handled consistently across transformations
- Lagged variables enable time-series modeling
- All numeric columns receive both averages and lag variables
- Country Code used as fallback for country matching
