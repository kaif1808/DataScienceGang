# ==============================================================================
# Process Amaani_2.csv
# ==============================================================================
# Converts Amaani_2.csv from long format to wide format with series name sanitization

library(data.table)

process_amaani <- function(data_path = "fresh_data/Amaani_2.csv", 
                              mapping_path = "series_names.csv") {
  amaani_long <- fread(data_path)
  
  # The new data has: Country Name, Country Code, Series Name, Time, Value
  # Rename Time to Year for consistency
  setnames(amaani_long, "Time", "Year")
  
  # Filter out empty rows (where Country Name or Series Name is empty)
  amaani_long <- amaani_long[`Country Name` != "" & `Series Name` != ""]
  
  # Handle non-numeric values: convert empty strings and ".." to NA
  amaani_long[, Value := ifelse(Value == "" | Value == "..", NA_character_, as.character(Value))]
  
  # Convert Value to numeric
  amaani_long[, Value := as.numeric(Value)]
  
  # Remove any rows with missing Country Name, Year, Series Name, or Country Code
  amaani_long <- amaani_long[!is.na(`Country Name`) & !is.na(Year) & 
                             !is.na(`Series Name`) & !is.na(`Country Code`)]
  
  # Check for and handle duplicate Country-Year-Series Name combinations
  duplicates_amaani <- amaani_long[, .N, by = .(`Country Name`, Year, `Country Code`, `Series Name`)][N > 1]
  if (nrow(duplicates_amaani) > 0) {
    # Aggregate duplicates by taking the mean of values
    amaani_long <- amaani_long[, .(Value = {
      vals <- Value[!is.na(Value)]
      if (length(vals) == 0) NA_real_ else mean(vals)
    }), by = .(`Country Name`, Year, `Country Code`, `Series Name`)]
  }
  
  # Sanitize Series Names to create valid R column names
  # Load the predefined mapping from series_names.csv
  series_name_mapping <- fread(mapping_path)
  
  # Merge the clean names back to the main data
  amaani_long <- merge(amaani_long, series_name_mapping, by = "Series Name", all.x = TRUE)
  
  # For any Series Names not in the mapping, create a clean name
  amaani_long[is.na(Series_Name_clean), Series_Name_clean := gsub("[^A-Za-z0-9_]", "_", `Series Name`)]
  
  # Convert from long to wide format using sanitized column names
  amaani_wide <- dcast(amaani_long, 
                       formula = `Country Name` + Year + `Country Code` ~ Series_Name_clean, 
                       value.var = "Value",
                       fun.aggregate = function(x) {
                         vals <- x[!is.na(x)]
                         if (length(vals) == 0) NA_real_ else mean(vals)
                       })
  
  return(amaani_wide)
}
