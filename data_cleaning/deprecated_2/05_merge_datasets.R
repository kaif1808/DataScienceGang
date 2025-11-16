# ==============================================================================
# Merge Datasets
# ==============================================================================
# Merges the three wide-format datasets (rayyaan, amaani, ellie) by Country Name and Year

library(data.table)

merge_datasets <- function(rayyaan_wide, amaani_wide, ellie_wide) {
  # Standardize column names if older files used "Country"
  if ("Country" %in% names(rayyaan_wide)) {
    setnames(rayyaan_wide, "Country", "Country Name")
  }
  if ("Country" %in% names(amaani_wide)) {
    setnames(amaani_wide, "Country", "Country Name")
  }
  if ("Country" %in% names(ellie_wide)) {
    setnames(ellie_wide, "Country", "Country Name")
  }
  
  # Merge all three datasets by Country Name and Year
  # Start with rayyaan_wide, then merge amaani_wide, then ellie_wide
  merged_data <- merge(rayyaan_wide, amaani_wide, by = c("Country Name", "Year"), all = TRUE)
  merged_data <- merge(merged_data, ellie_wide, by = c("Country Name", "Year"), all = TRUE)
  
  # Remove rows with missing Country Name
  merged_data <- merged_data[!is.na(`Country Name`), ]
  
  return(merged_data)
}

