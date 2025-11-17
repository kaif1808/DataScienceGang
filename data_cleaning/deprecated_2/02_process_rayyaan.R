# ==============================================================================
# Process rayyaan_2.csv
# ==============================================================================
# Converts rayyaan_2.csv from wide format (years as columns) to long format,
# then returns wide format with indicators as columns

library(data.table)

process_rayyaan <- function(data_path = "fresh_data/rayyaan_2.csv") {
  # Read the data
  rayyaan_raw <- fread(data_path)
  # Handle files where the header row was ingested as the first data row (all
  # columns named V1, V2, ...). This happens because the header line in
  # rayyaan_2.csv is split across multiple physical lines.
  if (all(grepl("^V\\d+$", names(rayyaan_raw)))) {
    header_vals <- rayyaan_raw[1, lapply(.SD, function(x) trimws(as.character(x)))]
    setnames(rayyaan_raw, unname(unlist(header_vals, use.names = FALSE)))
    rayyaan_raw <- rayyaan_raw[-1]
  }
  
  # The data has: country, code, indicator, and year columns (1992-2024)
  # We need to convert to long format first, then to wide format
  
  # Get year column names (all columns except country, code, indicator)
  year_cols <- setdiff(names(rayyaan_raw), c("country", "code", "indicator"))
  
  # Convert from wide to long format
  rayyaan_long <- melt(rayyaan_raw, 
                       id.vars = c("country", "code", "indicator"),
                       measure.vars = year_cols,
                       variable.name = "Year",
                       value.name = "Value")
  
  # Convert Year to numeric (remove quotes if any)
  rayyaan_long[, Year := as.integer(as.character(Year))]
  
  # Convert Value to numeric
  rayyaan_long[, Value := as.numeric(Value)]
  
  # Remove any rows with missing indicator
  rayyaan_long <- rayyaan_long[!is.na(indicator)]
  
  # Check for and handle duplicate Country-Year-Indicator combinations
  duplicates <- rayyaan_long[, .N, by = .(country, Year, indicator)][N > 1]
  if (nrow(duplicates) > 0) {
    # Aggregate duplicates by taking the mean of values
    rayyaan_long <- rayyaan_long[, .(Value = {
      vals <- Value[!is.na(Value)]
      if (length(vals) == 0) NA_real_ else mean(vals)
    }, code = code[1]), by = .(country, Year, indicator)]
  }
  
  # Convert from long to wide format
  # Each unique indicator value becomes a separate column
  rayyaan_wide <- dcast(rayyaan_long, 
                        country + code + Year ~ indicator, 
                        value.var = "Value", 
                        fun.aggregate = function(x) {
                          vals <- x[!is.na(x)]
                          if (length(vals) == 0) NA_real_ else mean(vals)
                        })
  
  # Rename columns to match expected format
  setnames(rayyaan_wide, c("country", "code"), c("Country Name", "Country Code"))
  
  return(rayyaan_wide)
}
