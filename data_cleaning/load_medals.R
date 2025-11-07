# ==============================================================================
# Load Medals Data
# ==============================================================================
# Loads and filters Olympic medal tally history data

library(data.table)

load_medals <- function(data_path = "data/Olympic_Medal_Tally_History.csv", 
                       min_year = 2012) {
  medals <- fread(data_path)
  medals <- medals[year >= min_year]
  return(medals)
}

