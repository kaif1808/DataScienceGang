library(tidyverse)
setwd("/Users/rayyaankazi/Desktop/DataScienceGang/DataScienceGang/Rayyaan_data")

# 1. Load datasets
Literacy_v2  <- read_csv("Literacy_v2.csv", show_col_types = FALSE)
Life_v2      <- read_csv("Life_v2.csv", show_col_types = FALSE)
Obesity_v2   <- read_csv("Obesity_v2.csv", show_col_types = FALSE)
Schooling_v2 <- read_csv("Schooling_v2.csv", show_col_types = FALSE)

# 2. Function to convert wide -> long for a dataset
convert_wide_to_long <- function(df, indicator_name) {
  # Assume first column = country, second column = code (if present)
  id_cols <- names(df)[1:2]
  
  # Remaining columns are years / measurements
  value_cols <- setdiff(names(df), id_cols)
  
  df_long <- df %>%
    pivot_longer(
      cols = all_of(value_cols),
      names_to = "year",
      values_to = "value"
    ) %>%
    mutate(indicator = indicator_name) %>%
    select(all_of(id_cols), indicator, value)
  
  # rename id columns to standard
  colnames(df_long)[1:2] <- c("country", "code")
  
  return(df_long)
}

# 3. Convert each dataset
literacy_long  <- convert_wide_to_long(Literacy_v2, "Literacy")
life_long      <- convert_wide_to_long(Life_v2, "Life Expectancy")
schooling_long <- convert_wide_to_long(Schooling_v2, "Schooling")
obesity_long   <- convert_wide_to_long(Obesity_v2, "Obesity")

# 4. Stack all indicators together
merged_data_v2 <- bind_rows(literacy_long, life_long, schooling_long, obesity_long) %>%
  relocate(country, code, indicator, value)

# 5. Save
write_csv(merged_data_v2, "merged_data_v2.csv")
