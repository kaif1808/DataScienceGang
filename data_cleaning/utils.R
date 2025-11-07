# ==============================================================================
# Utility Functions
# ==============================================================================
# Shared utility functions used across multiple data processing scripts

library(data.table)

# ------------------------------------------------------------------------------
# avg_non_na
# ------------------------------------------------------------------------------
# Function to average non-NA values
# Returns NA if all values are NA (to avoid NaN)
avg_non_na <- function(x) {
  vals <- x[!is.na(x)]
  if (length(vals) == 0) NA_real_ else mean(vals)
}

# ------------------------------------------------------------------------------
# create_4yr_averages
# ------------------------------------------------------------------------------
# Helper function to create 4-year averages (assumes Period_End column already exists)
# Filters data to only include years within specified 4-year periods
# Aggregates numeric columns by Country Name and Period_End
create_4yr_averages <- function(data) {
  # Filter to only include years within the specified 4-year periods
  data_filtered <- data[!is.na(Period_End), ]
  
  # If no data matches, return empty data.table with same structure
  if (nrow(data_filtered) == 0) {
    return(data.table())
  }
  
  # Identify column types
  grouping_cols <- c("Country Name", "Country Code")
  grouping_cols <- grouping_cols[grouping_cols %in% names(data_filtered)]
  all_cols <- names(data_filtered)
  numeric_cols <- setdiff(all_cols, c(grouping_cols, "Year", "Period_End"))
  
  # Perform aggregation
  if ("Country Code" %in% names(data_filtered)) {
    # With Country Code column
    result <- data_filtered[, c(
      list(Year = Period_End[1],
           `Country Code` = {
             vals <- `Country Code`[!is.na(`Country Code`)]
             if (length(vals) == 0) NA_character_ else vals[1]
           }),
      lapply(.SD, avg_non_na)
    ), by = .(`Country Name`, Period_End), .SDcols = numeric_cols]
  } else {
    # Without Country Code column
    result <- data_filtered[, c(
      list(Year = Period_End[1]),
      lapply(.SD, avg_non_na)
    ), by = .(`Country Name`, Period_End), .SDcols = numeric_cols]
  }
  
  # Remove the Period_End column (Year now contains the period ending year)
  result[, Period_End := NULL]
  
  return(result)
}

