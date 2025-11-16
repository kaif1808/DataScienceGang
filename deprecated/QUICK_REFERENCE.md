# Quick Reference: Original vs Adapted Pipeline

## File Mapping

| Purpose | Original Pipeline | Adapted Pipeline (v2) |
|---------|------------------|----------------------|
| Main orchestrator | `10_main.R` | `10_main_v2.R` |
| Process Rayyaan data | `02_process_rayyaan.R` | `02_process_rayyaan_v2.R` |
| Process Amaani data | `03_process_amaani.R` | `03_process_amaani_v2.R` |
| Load Ellie data | `04_load_ellie.R` | `04_load_ellie_v2.R` |
| Utilities | `01_utils.R` | `01_utils.R` (shared) |
| Merge datasets | `05_merge_datasets.R` | `05_merge_datasets.R` (shared) |
| 4-year averages | `06_create_4yr_averages.R` | `06_create_4yr_averages.R` (shared) |
| Load medals | `07_load_medals.R` | `07_load_medals.R` (shared) |
| Merge medals | `08_merge_medals.R` | `08_merge_medals.R` (shared) |
| Diagnostics | `09_compare_countries.R` | `09_compare_countries.R` (shared) |

## Data Source Mapping

| Data Type | Original Source | New Source |
|-----------|----------------|------------|
| Rayyaan data | `data/rayyaan_data.csv` | `fresh_data/rayyaan_2.csv` |
| Amaani data | `data/amaani_data.csv` | `fresh_data/Amaani_2.csv` |
| Ellie data | `data/ellie_data.csv` | `fresh_data/ellie_2.csv` |
| Medals | `data/Olympic_Medal_Tally_History.csv` + `2024olympics/medals_total.csv` | (unchanged) |

## Function Naming

| Purpose | Original Function | New Function |
|---------|------------------|--------------|
| Process Rayyaan | `process_rayyaan()` | `process_rayyaan_v2()` |
| Process Amaani | `process_amaani()` | `process_amaani_v2()` |
| Load Ellie | `load_ellie()` | `load_ellie_v2()` |
| Run pipeline | `run_pipeline()` | `run_pipeline_v2()` |

## Format Differences

### Rayyaan Data
```
ORIGINAL (data/rayyaan_data.csv):
Country, Year, Indicator, Value
------------------------------
USA, 1992, Overweight, 45.2
USA, 1993, Overweight, 45.5

NEW (fresh_data/rayyaan_2.csv):
country, code, indicator, 1992, 1993, ...
------------------------------------------
USA, USA, Overweight, 45.2, 45.5, ...
```

### Amaani Data
```
ORIGINAL (data/amaani_data.csv):
Country Name, Country Code, Series Name, Year, Value
----------------------------------------------------
USA, USA, GDP per capita, 1992, 25000

NEW (fresh_data/Amaani_2.csv):
Country Name, Country Code, Series Name, Time, Value
----------------------------------------------------
USA, USA, GDP per capita, 1992, 25000
```

### Ellie Data
```
Both formats are already wide - minimal changes needed
```

## Usage Comparison

### Original Pipeline
```r
source("data_cleaning/10_main.R")
merged_data <- run_pipeline()
```

### Adapted Pipeline
```r
source("data_cleaning/10_main_v2.R")
merged_data <- run_pipeline_v2()
```

## Key Differences Summary

| Aspect | Original | Adapted (v2) |
|--------|----------|-------------|
| Rayyaan format | Long (Country, Year, Indicator, Value) | Wide (years as columns) |
| Amaani year column | `Year` | `Time` (renamed to `Year` in script) |
| Processing complexity | Direct conversion | Melt → Process → Cast |
| Series mappings | 14 series | 22 series (8 new) |
| Output structure | Same | Same |
| Shared utilities | Yes | Yes (no changes needed) |
