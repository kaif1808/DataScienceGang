# ==============================================================================
# Load ellie_2.csv
# ==============================================================================
# Loads ellie_2.csv which is already in wide format

library(data.table)

load_ellie <- function(data_path = "fresh_data/ellie_2.csv") {
  ellie_wide <- fread(data_path)
  
  # Ensure Year column exists and is integer
  if ("Year" %in% names(ellie_wide)) {
    ellie_wide[, Year := as.integer(Year)]
  }
  
  return(ellie_wide)
}
