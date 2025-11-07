# Data Science Project: Predicting Olympic Performance Using Socioeconomic Variables

## Group Members

- Amaani Bashir
- Ellie Walters
- Kai Faulkner
- Rayyaan Kazi

## Project Overview

The aim of our project is to use socioeconomic variables to predict performance in the Olympic Games. While the Olympic Games have been historically dominated by a handful of wealthy countries and those with mature sporting institutions, due to the recent rise in commercial and media interest in the Olympics from emerging markets and developing countries, it would be of interest to see what factors can predict sporting excellence at the Games. This is also further motivated by the fact that several countries that do not have large sporting budgets or access to sporting facilities regularly outperform at the Games relative to their economic position.

We will conduct a predictive analysis on different quantiles of Olympic performers—highest, middle ranked, and low ranked—in terms of total medals won and a weighted composite score of gold, silver and bronze medals won. The purpose of this task, while preliminary, may give insights on how human capital and development outcomes can have positive externalities into non-economic spheres such as sporting performance, providing some policy motivation for financially-constrained countries who may not afford high sporting budgets.

## Data Sources

We compile data from a variety of sources, namely:

- **World Development Indicators (WDI)**: Socioeconomic indicators from the World Bank
- **World Governance Indicators (WGI)**: Governance and institutional quality metrics
- **International Olympic Committee (IOC)**: Official Olympic Games data including medal tallies, athlete information, and event results

The data is merged with observations that coincide with the official members of the International Olympic Committee (IOC), ensuring alignment between socioeconomic indicators and Olympic participation.

## Code Structure

The project uses a modular data processing pipeline located in the `data_cleaning/` directory. The pipeline is designed to process multiple socioeconomic datasets, merge them with Olympic performance data, and prepare the data for predictive modeling.

### Main Pipeline

**`data_cleaning/10_main.R`**: The orchestrator script that runs the entire data processing pipeline. It sources all required module scripts and executes them in sequence through the `run_pipeline()` function.

**Function signature:**
```r
run_pipeline(save_output = FALSE, output_path = NULL, run_diagnostics = FALSE)
```

**Parameters:**
- `save_output`: Boolean flag to save the final merged dataset to disk
- `output_path`: Path where the output CSV should be saved (if `save_output = TRUE`)
- `run_diagnostics`: Boolean flag to run optional country comparison diagnostics

**Returns:** The final merged dataset as a `data.table` containing socioeconomic indicators and Olympic medal data.

### Module Scripts

The pipeline consists of numbered modules that execute specific data processing tasks:

#### `01_utils.R` - Utility Functions
Provides shared utility functions used across the pipeline:
- **`avg_non_na(x)`**: Calculates the average of non-NA values, returning `NA` if all values are `NA` (to avoid `NaN`)
- **`create_4yr_averages(data)`**: Helper function that creates 4-year averages by filtering data to specified periods and aggregating numeric columns by Country Name and Period_End

#### `02_process_rayyaan.R` - Process Rayyaan's Data
Converts `rayyaan_data.csv` from long format to wide format:
- Reads panel data in long format (Country, Year, Indicator, Value)
- Handles duplicate Country-Year-Indicator combinations by taking the mean
- Converts to wide format where each unique Indicator becomes a separate column
- **Input**: `data/rayyaan_data.csv`
- **Output**: Wide-format `data.table` with Country, Year, and indicator columns

#### `03_process_amaani.R` - Process Amaani's Data
Processes `amaani_data.csv` with series name sanitization:
- Reads long-format data with Series Name, Country Name, Country Code, Year, and Value
- Handles non-numeric values (empty strings and ".." converted to `NA`)
- Sanitizes Series Names using a predefined mapping from `series_names.csv` to create valid R column names
- Converts to wide format using sanitized column names
- **Input**: `data/amaani_data.csv`, `series_names.csv`
- **Output**: Wide-format `data.table` with sanitized indicator columns

#### `04_load_ellie.R` - Load Ellie's Data
Loads `ellie_data.csv` which is already in wide format:
- Simply reads the CSV file using `data.table::fread()`
- **Input**: `data/ellie_data.csv`
- **Output**: Wide-format `data.table` (no transformation needed)

#### `05_merge_datasets.R` - Merge Datasets
Merges the three wide-format datasets (rayyaan, amaani, ellie) by Country Name and Year:
- Standardizes column names (renames "Country" to "Country Name" in rayyaan's data)
- Performs full outer joins to combine all three datasets
- Removes rows with missing Country Name
- **Input**: Three wide-format datasets from previous steps
- **Output**: Single merged `data.table` with all socioeconomic indicators

#### `06_create_4yr_averages.R` - Create 4-Year Averages
Creates overlapping 4-year average cycles aligned with Olympic Games:
- **Cycle 1**: Standard 4-year periods (2009-2012→2012, 2013-2016→2016, 2017-2020→2020, 2021-2024→2024)
- **Cycle 2**: Offset 2-year periods (2011-2014→2014, 2015-2018→2018, 2019-2022→2022, 2023-2026→2026)
- Aggregates numeric columns by taking averages of non-NA values
- Combines both cycles into a single dataset
- **Purpose**: Aligns socioeconomic indicators with Olympic Games timing (every 4 years)

#### `07_load_medals.R` - Load Medals Data
Loads and combines Olympic medal tally history with Paris 2024 data:
- Loads historical medals from `data/Olympic_Medal_Tally_History.csv` (filtered to years >= 2012)
- Loads Paris 2024 medals from `2024olympics/medals_total.csv`
- Transforms Paris 2024 data to match historical structure (renames columns, adds year/edition fields)
- Appends Paris 2024 data to historical medals
- **Input**: Historical medals CSV, Paris 2024 medals CSV
- **Output**: Combined medals `data.table` with columns: country, country_noc, year, gold, silver, bronze, total, edition, edition_id

#### `08_merge_medals.R` - Merge with Medals Data
Merges the socioeconomic dataset with Olympic medals data using intelligent matching:
- **First merge**: Matches by Country Name and Year (exact match)
- **Second merge**: For unmatched rows, attempts matching by Country Code and Year
- Handles duplicate country-year combinations by aggregating medal counts
- Preserves all socioeconomic data while adding medal columns (gold, silver, bronze, total, edition, edition_id)
- **Input**: Merged socioeconomic data, medals data
- **Output**: Final merged dataset with both socioeconomic indicators and Olympic performance metrics

#### `09_compare_countries.R` - Compare Countries (Optional Diagnostics)
Optional diagnostic script to compare country name-code pairs between datasets:
- Extracts unique Country Name-Country Code pairs from both merged_data and medals
- Identifies matches by name and by code
- Finds discrepancies and unmatched countries
- Useful for data quality checks and identifying merge issues
- **Usage**: Called when `run_diagnostics = TRUE` in `run_pipeline()`

## Data Flow

The pipeline processes data through the following steps:

1. **Data Loading**: Three socioeconomic datasets are loaded and processed (rayyaan, amaani, ellie)
2. **Format Conversion**: Long-format data is converted to wide format (where applicable)
3. **Merging**: All three socioeconomic datasets are merged by Country Name and Year
4. **Temporal Aggregation**: 4-year averages are created to align with Olympic cycles
5. **Medal Data Integration**: Olympic medals data is loaded and merged with socioeconomic data
6. **Output**: Final dataset ready for predictive modeling

## Usage

### Running the Complete Pipeline

To run the entire data processing pipeline:

```r
# Source the main pipeline script
source("data_cleaning/10_main.R")

# Run the pipeline (interactive mode)
merged_data <- run_pipeline()

# Run with options: save output and run diagnostics
merged_data <- run_pipeline(
  save_output = TRUE, 
  output_path = "data/final_merged_data.csv",
  run_diagnostics = TRUE
)
```

### Running Individual Modules

You can also source and run individual modules if needed:

```r
# Load utilities
source("data_cleaning/01_utils.R")

# Process individual datasets
rayyaan_wide <- process_rayyaan()
amaani_wide <- process_amaani()
ellie_wide <- load_ellie()

# Merge datasets
merged_data <- merge_datasets(rayyaan_wide, amaani_wide, ellie_wide)

# Create 4-year averages
merged_data <- create_4yr_averages_pipeline(merged_data)

# Load and merge medals
medals <- load_medals()
merged_data <- merge_medals(merged_data, medals)
```

### Expected Output

The final merged dataset contains:
- **Country identifiers**: Country Name, Country Code
- **Temporal information**: Year (aligned with Olympic cycles)
- **Socioeconomic indicators**: All variables from World Development Indicators and World Governance Indicators
- **Olympic performance**: gold, silver, bronze, total medals, edition, edition_id

## Directory Structure

```
DataScienceGang/
├── data/                          # Main data directory
│   ├── rayyaan_data.csv          # Rayyaan's socioeconomic indicators
│   ├── amaani_data.csv           # Amaani's socioeconomic indicators
│   ├── ellie_data.csv            # Ellie's socioeconomic indicators
│   ├── Olympic_Medal_Tally_History.csv  # Historical Olympic medals
│   └── [other Olympic data files]
├── data_cleaning/                 # Modular data processing pipeline
│   ├── 01_utils.R                # Utility functions
│   ├── 02_process_rayyaan.R     # Process rayyaan's data
│   ├── 03_process_amaani.R      # Process amaani's data
│   ├── 04_load_ellie.R           # Load ellie's data
│   ├── 05_merge_datasets.R       # Merge socioeconomic datasets
│   ├── 06_create_4yr_averages.R  # Create 4-year averages
│   ├── 07_load_medals.R          # Load Olympic medals data
│   ├── 08_merge_medals.R         # Merge with medals data
│   ├── 09_compare_countries.R    # Optional diagnostics
│   └── 10_main.R                 # Main pipeline orchestrator
├── 2024olympics/                  # Paris 2024 Olympic Games data
│   ├── medals_total.csv          # Paris 2024 medal tallies
│   ├── athletes.csv              # Athlete information
│   ├── events.csv                # Event details
│   ├── results/                  # Detailed results by sport
│   └── [other 2024 Olympic files]
├── series_names.csv               # Series name mapping for amaani's data
└── README.md                      # This file
```

## Dependencies

The pipeline requires the following R packages:
- `data.table`: For efficient data manipulation and merging

Install dependencies using:
```r
install.packages("data.table")
```

## Next Steps

After running the data processing pipeline, the merged dataset can be used for:
- Exploratory data analysis (see `eda_olympic.R`)
- Predictive modeling to identify socioeconomic factors that predict Olympic performance
- Quantile regression analysis for different performance tiers (high, middle, low performers)
- Policy analysis on the relationship between human capital, development outcomes, and sporting excellence
