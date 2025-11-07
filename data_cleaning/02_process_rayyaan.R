# ==============================================================================
# Process rayyaan_data.csv
# ==============================================================================
# Converts rayyaan_data.csv from long format to wide format

library(data.table)

process_rayyaan <- function(data_path = "data/rayyaan_data.csv") {
  # Read the long format panel data
  rayyaan_long <- fread(data_path)
  
  # Remove the Source column if it exists
  if ("Source" %in% names(rayyaan_long)) rayyaan_long[, Source := NULL]
  
  # Convert Value to numeric, handling NA values properly
  rayyaan_long[, Value := as.numeric(Value)]
  
  # Remove any rows with missing Indicator
  rayyaan_long <- rayyaan_long[!is.na(Indicator)]
  
  # Check for and handle duplicate Country-Year-Indicator combinations
  # If duplicates exist, take the mean (or you can use first/last)
  duplicates <- rayyaan_long[, .N, by = .(Country, Year, Indicator)][N > 1]
  if (nrow(duplicates) > 0) {
    # Aggregate duplicates by taking the mean of values
    # Return NA if all values are NA (to avoid NaN)
    rayyaan_long <- rayyaan_long[, .(Value = {
      vals <- Value[!is.na(Value)]
      if (length(vals) == 0) NA_real_ else mean(vals)
    }), by = .(Country, Year, Indicator)]
  }
  
  # Convert from long to wide format
  # Each unique Indicator value becomes a separate column
  # Use aggregate function to preserve NA values without creating NaN
  rayyaan_wide <- dcast(rayyaan_long, Country + Year ~ Indicator, value.var = "Value", 
                        fun.aggregate = function(x) {
                          vals <- x[!is.na(x)]
                          if (length(vals) == 0) NA_real_ else mean(vals)
                        })
  
  return(rayyaan_wide)
}

