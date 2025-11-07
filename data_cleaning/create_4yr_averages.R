# ==============================================================================
# Create 4-Year Averages
# ==============================================================================
# Creates 4-year averages for merged_data with overlapping cycles

library(data.table)
source("data_cleaning/utils.R")

create_4yr_averages_pipeline <- function(merged_data) {
  # Preserve original merged_data before averaging
  merged_data_original <- copy(merged_data)
  
  # Cycle 1: Standard 4-year periods (2009-2012→2012, 2013-2016→2016, 2017-2020→2020, 2021-2024→2024)
  # Create a copy with modified period assignment logic
  data_cycle1 <- copy(merged_data_original)
  data_cycle1[, Period_End := ifelse(Year >= 2009 & Year <= 2012, 2012,
                                     ifelse(Year >= 2013 & Year <= 2016, 2016,
                                            ifelse(Year >= 2017 & Year <= 2020, 2020,
                                                   ifelse(Year >= 2021 & Year <= 2024, 2024, NA_integer_))))]
  merged_data_cycle1 <- create_4yr_averages(data_cycle1)
  
  # Cycle 2: Offset 2-year periods (2011-2014→2014, 2015-2018→2018, 2019-2022→2022, 2023-2026→2026)
  # Create a copy with modified period assignment logic
  data_cycle2 <- copy(merged_data_original)
  data_cycle2[, Period_End := ifelse(Year >= 2011 & Year <= 2014, 2014,
                                     ifelse(Year >= 2015 & Year <= 2018, 2018,
                                            ifelse(Year >= 2019 & Year <= 2022, 2022,
                                                   ifelse(Year >= 2023 & Year <= 2026, 2026, NA_integer_))))]
  merged_data_cycle2 <- create_4yr_averages(data_cycle2)
  
  # Combine both cycles into a single dataset
  merged_data <- rbindlist(list(merged_data_cycle1, merged_data_cycle2), use.names = TRUE, fill = TRUE)
  
  # Ensure Year is integer
  merged_data[, Year := as.integer(Year)]
  
  return(merged_data)
}

