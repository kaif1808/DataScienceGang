# ==============================================================================
# Load ellie_data.csv
# ==============================================================================
# Loads ellie_data.csv which is already in wide format

library(data.table)

load_ellie <- function(data_path = "data/ellie_data.csv") {
  ellie_wide <- fread(data_path)
  return(ellie_wide)
}

