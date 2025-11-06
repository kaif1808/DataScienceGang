# DataScienceGang

## Project Overview
This repository contains data processing and analysis scripts for Olympic and demographic data.

## Key Scripts

### Data Processing Scripts

#### `data_processing_pipeline.R`
Combined data processing pipeline that:
1. **Loads and merges CSV files**: Reads individual CSV files (Literacy.csv, Life.csv, Schooling.csv, Obesity.csv), cleans column names, and reshapes data from wide to long format
2. **Creates merged dataset**: Combines all indicators into `merged_data_clean.csv` with columns: Country, Year, Value, Indicator, Source
3. **Extracts indicator-specific tables**: Creates separate data tables for each indicator (literacy_data, life_expectancy_data, schooling_years_data, obesity_data)
4. **Merges by Country and Year**: Combines all indicators into a wide-format table (`merged_indicators`) where each row represents a unique Country-Year combination with separate columns for each indicator

**Input files**: Literacy.csv, Life.csv, Schooling.csv, Obesity.csv  
**Output files**: merged_data_clean.csv, merged_indicators_by_country_year.csv (optional)

#### `Merge_CSVs.R`
*Note: This script has been integrated into `data_processing_pipeline.R`*

Original script for merging individual CSV files into a single cleaned dataset. Processes files by:
- Cleaning column names
- Reshaping from wide to long format
- Filtering data from 2009 onwards
- Adding indicator labels and source information

#### `extract_indicators.R`
*Note: This script has been integrated into `data_processing_pipeline.R`*

Original script for extracting and merging indicator-specific data tables. Creates separate data tables for each indicator and merges them by Country and Year.

### Data Files

#### Input Data
- `Literacy.csv`: Literacy rate data by country and year
- `Life.csv`: Life expectancy data by country and year
- `Schooling.csv`: Schooling years data by country and year
- `Obesity.csv`: Obesity rate data by country and year

#### Processed Data
- `merged_data_clean.csv`: Combined dataset with all indicators in long format (Country, Year, Value, Indicator, Source)
- `merged_indicators_by_country_year.csv`: Wide-format table with all indicators merged by Country and Year (optional output)

### Analysis Scripts

#### `eda_olympic.R`
Exploratory data analysis script for Olympic data.

#### `dataimport.R`
Data import script for loading Olympic datasets from the `data/` directory.

## Directory Structure

- `data/`: Contains Olympic-related CSV files
- `2024olympics/`: Contains 2024 Olympics data files including athletes, events, medals, and results by sport
- `results/`: Contains detailed results files for each Olympic sport

## Usage

To process demographic indicator data:
```r
source("data_processing_pipeline.R")
```

This will create:
- `merged_data_clean.csv`: Intermediate file with all indicators in long format
- Individual data tables in R environment: `literacy_data`, `life_expectancy_data`, `schooling_years_data`, `obesity_data`
- Merged data table: `merged_indicators` (wide format with all indicators by Country and Year)