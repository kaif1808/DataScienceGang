# ==============================================================================
# Create 4-Year Averages with Lagged Variables
# ==============================================================================
# Creates 4-year averages for merged_data with overlapping cycles
# Also includes lagged variables (t, t-1, t-2, t-3) for each target year

library(data.table)
source("data_cleaning/01_utils.R")

create_4yr_averages_with_lags <- function(data, target_year) {
  # Filter to only include the 4-year period
  data_filtered <- data[!is.na(Period_End), ]
  
  if (nrow(data_filtered) == 0) {
    return(data.table())
  }
  
  # Identify column types
  grouping_cols <- c("Country Name", "Country Code")
  grouping_cols <- grouping_cols[grouping_cols %in% names(data_filtered)]
  all_cols <- names(data_filtered)
  numeric_cols <- setdiff(all_cols, c(grouping_cols, "Year", "Period_End"))
  
  # Get the target year and the 3 preceding years
  lag_years <- c(target_year, target_year - 1, target_year - 2, target_year - 3)
  
  # Calculate 4-year averages
  if ("Country Code" %in% names(data_filtered)) {
    avg_result <- data_filtered[, c(
      list(Year = Period_End[1],
           `Country Code` = {
             vals <- `Country Code`[!is.na(`Country Code`)]
             if (length(vals) == 0) NA_character_ else vals[1]
           }),
      lapply(.SD, avg_non_na)
    ), by = .(`Country Name`, Period_End), .SDcols = numeric_cols]
  } else {
    avg_result <- data_filtered[, c(
      list(Year = Period_End[1]),
      lapply(.SD, avg_non_na)
    ), by = .(`Country Name`, Period_End), .SDcols = numeric_cols]
  }
  
  # Remove the Period_End column
  avg_result[, Period_End := NULL]
  
  # Now add lagged variables for each numeric column
  # Get the actual data for the target year and preceding years
  lag_data <- data[Year %in% lag_years, ]
  
  if (nrow(lag_data) > 0) {
    # For each lag period, create columns with _lag0, _lag1, _lag2, _lag3 suffix
    for (lag in 0:3) {
      year_val <- target_year - lag
      year_data <- lag_data[Year == year_val, ]
      
      if (nrow(year_data) > 0) {
        # Select only numeric columns and add lag suffix
        lag_cols <- numeric_cols[numeric_cols %in% names(year_data)]
        
        # Rename columns with lag suffix
        setnames(year_data, lag_cols, paste0(lag_cols, "_lag", lag))
        
        # Select columns to merge
        merge_cols <- c(grouping_cols, paste0(lag_cols, "_lag", lag))
        merge_cols <- merge_cols[merge_cols %in% names(year_data)]
        year_data_subset <- year_data[, ..merge_cols]
        
        # Merge with average result
        avg_result <- merge(avg_result, year_data_subset, 
                           by = grouping_cols, all.x = TRUE)
      }
    }
  }
  
  return(avg_result)
}

create_4yr_averages_pipeline <- function(merged_data) {
  # Preserve original merged_data before averaging
  merged_data_original <- copy(merged_data)
  
  # Cycle 1: Standard 4-year periods (2009-2012→2012, 2013-2016→2016, 2017-2020→2020, 2021-2024→2024)
  data_cycle1 <- copy(merged_data_original)
  data_cycle1[, Period_End := ifelse(Year >= 2009 & Year <= 2012, 2012,
                                     ifelse(Year >= 2013 & Year <= 2016, 2016,
                                            ifelse(Year >= 2017 & Year <= 2020, 2020,
                                                   ifelse(Year >= 2021 & Year <= 2024, 2024, NA_integer_))))]
  
  # Process each target year separately to include lags
  results_cycle1 <- list()
  for (target in c(2012, 2016, 2020, 2024)) {
    results_cycle1[[as.character(target)]] <- create_4yr_averages_with_lags(data_cycle1, target)
  }
  merged_data_cycle1 <- rbindlist(results_cycle1, use.names = TRUE, fill = TRUE)
  
  # Cycle 2: Offset 2-year periods (2011-2014→2014, 2015-2018→2018, 2019-2022→2022, 2023-2026→2026)
  data_cycle2 <- copy(merged_data_original)
  data_cycle2[, Period_End := ifelse(Year >= 2011 & Year <= 2014, 2014,
                                     ifelse(Year >= 2015 & Year <= 2018, 2018,
                                            ifelse(Year >= 2019 & Year <= 2022, 2022,
                                                   ifelse(Year >= 2023 & Year <= 2026, 2026, NA_integer_))))]
  
  # Process each target year separately to include lags
  results_cycle2 <- list()
  for (target in c(2014, 2018, 2022, 2026)) {
    results_cycle2[[as.character(target)]] <- create_4yr_averages_with_lags(data_cycle2, target)
  }
  merged_data_cycle2 <- rbindlist(results_cycle2, use.names = TRUE, fill = TRUE)
  
  # Combine both cycles into a single dataset
  merged_data <- rbindlist(list(merged_data_cycle1, merged_data_cycle2), use.names = TRUE, fill = TRUE)
  
  # Ensure Year is integer
  merged_data[, Year := as.integer(Year)]
  
  return(merged_data)
}

