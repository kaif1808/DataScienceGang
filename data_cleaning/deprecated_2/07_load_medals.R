# ==============================================================================
# Load Medals Data
# ==============================================================================
# Loads and filters Olympic medal tally history data
# Also loads and appends Paris 2024 medals data

library(data.table)

load_medals <- function(data_path = "data/Olympic_Medal_Tally_History.csv", 
                       min_year = 2012,
                       paris_medals_path = "2024olympics/medals_total.csv") {
  # Load historical medals data
  medals <- fread(data_path)
  medals <- medals[year >= min_year]
  
  # Load Paris 2024 medals data
  paris_medals <- fread(paris_medals_path)
  
  # Transform Paris medals to match historical medals structure
  # Rename columns to match standard format
  setnames(paris_medals, 
           c("country_code", "Gold Medal", "Silver Medal", "Bronze Medal", "Total"),
           c("country_noc", "gold", "silver", "bronze", "total"))
  
  # Remove country_long column if it exists (not needed)
  if ("country_long" %in% names(paris_medals)) {
    paris_medals[, country_long := NULL]
  }
  
  # Add required columns for Paris 2024
  paris_medals[, year := 2024L]
  paris_medals[, edition := "Paris 2024"]
  paris_medals[, edition_id := "2024"]
  
  # Ensure medal columns are numeric
  paris_medals[, gold := as.numeric(gold)]
  paris_medals[, silver := as.numeric(silver)]
  paris_medals[, bronze := as.numeric(bronze)]
  paris_medals[, total := as.numeric(total)]
  
  # Append Paris medals to historical medals
  # Use rbindlist with fill=TRUE to handle any column mismatches
  medals <- rbindlist(list(medals, paris_medals), use.names = TRUE, fill = TRUE)
  
  return(medals)
}

