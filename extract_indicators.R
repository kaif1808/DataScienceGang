# Script to extract separate data tables for each unique indicator value
# from merged_data_clean.csv

library(data.table)

# Read the merged data file
merged_data <- fread("rayyaan_data.csv")

# Define the indicator values
indicators <- c("Literacy rate", "Life expectancy", "Schooling years", "Obesity rate")

# Extract separate data tables for each indicator
for (indicator in indicators) {
  # Filter data for the current indicator
  indicator_data <- merged_data[Indicator == indicator]
  
  # Create a variable name from the indicator (remove spaces, make valid R name)
  var_name <- gsub(" ", "_", tolower(indicator))
  var_name <- gsub("_rate", "", var_name)  # Remove "rate" suffix for cleaner names
  
  # Assign to a data table with a descriptive name
  assign(paste0(var_name, "_data"), indicator_data)
  
  # Print summary information
  cat(sprintf("\n%s:\n", indicator))
  cat(sprintf("  Rows: %d\n", nrow(indicator_data)))
  cat(sprintf("  Variable name: %s_data\n", var_name))
  cat(sprintf("  Countries: %d\n", length(unique(indicator_data$Country))))
  cat(sprintf("  Years: %d to %d\n", min(indicator_data$Year, na.rm = TRUE), 
              max(indicator_data$Year, na.rm = TRUE)))
}

# Display available data tables
cat("\n\nAvailable data tables:\n")
cat("  - literacy_data\n")
cat("  - life_expectancy_data\n")
cat("  - schooling_years_data\n")
cat("  - obesity_data\n")

# Merge all indicator data tables by Country and Year
cat("\n\nMerging data tables by Country and Year...\n")

# Start with literacy data, selecting only Country, Year, and Value columns
merged_indicators <- literacy_data[, .(Country, Year, Literacy_rate = Value)]

# Merge with life expectancy data
merged_indicators <- merge(merged_indicators, 
                          life_expectancy_data[, .(Country, Year, Life_expectancy = Value)],
                          by = c("Country", "Year"), 
                          all = TRUE)

# Merge with schooling years data
merged_indicators <- merge(merged_indicators, 
                          schooling_years_data[, .(Country, Year, Schooling_years = Value)],
                          by = c("Country", "Year"), 
                          all = TRUE)

# Merge with obesity data
merged_indicators <- merge(merged_indicators, 
                          obesity_data[, .(Country, Year, Obesity_rate = Value)],
                          by = c("Country", "Year"), 
                          all = TRUE)

# Print summary of merged data
cat("\nMerged indicators data table:\n")
cat(sprintf("  Total rows: %d\n", nrow(merged_indicators)))
cat(sprintf("  Unique countries: %d\n", length(unique(merged_indicators$Country))))
cat(sprintf("  Year range: %d to %d\n", min(merged_indicators$Year, na.rm = TRUE), 
            max(merged_indicators$Year, na.rm = TRUE)))
cat(sprintf("  Columns: %s\n", paste(names(merged_indicators), collapse = ", ")))

# Optional: Save each data table to separate CSV files
# Uncomment the following lines if you want to save them as CSV files
# for (indicator in indicators) {
#   var_name <- gsub(" ", "_", tolower(indicator))
#   var_name <- gsub("_rate", "", var_name)
#   fwrite(get(paste0(var_name, "_data")), 
#          file = paste0(var_name, "_data.csv"))
# }

# Optional: Save merged indicators data table
# Uncomment the following line if you want to save the merged table
# fwrite(merged_indicators, file = "merged_indicators_by_country_year.csv")