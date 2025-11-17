library(tidyverse)

# --- Define files and their indicator names manually ---
file_info <- tibble(
  file = c("Literacy.csv", "Life.csv", "Schooling.csv", "Obesity.csv"),
  indicator = c("Literacy rate", "Life expectancy", "Schooling years", "Obesity rate")
)

# --- Function to clean and reshape each file ---
load_and_tidy <- function(fpath, indicator_label) {
  df <- read_csv(fpath, show_col_types = FALSE)
  
  # Clean column names
  names(df) <- names(df) |>
    trimws() |>
    str_replace_all("ï\\.\\.", "") |>
    str_replace_all("[^A-Za-z0-9_]", "")
  
  # Identify year columns
  year_cols <- names(df)[str_detect(names(df), "^[0-9]{4}$")]
  
  if (length(year_cols) == 0) {
    # handle already-long format
    if (all(c("Country", "Year", "Value") %in% names(df))) {
      df_long <- df
    } else {
      stop(paste("No year columns found in", fpath))
    }
  } else {
    # convert wide → long
    df_long <- df %>%
      pivot_longer(
        cols = all_of(year_cols),
        names_to = "Year",
        values_to = "Value"
      ) %>%
      mutate(Year = as.integer(Year))
  }
  
  # Keep only relevant columns and add indicator label
  df_long %>%
    select(Country, Year, Value) %>%
    mutate(
      Indicator = indicator_label,
      Source = basename(fpath),
      Value = as.numeric(Value)
    )
}

# --- Process all files and combine them ---
all_data <- map2_dfr(file_info$file, file_info$indicator, load_and_tidy)

# --- Filter out years before 2009 ---
all_data <- all_data %>% filter(Year >= 2009)

# --- Save clean, stacked data ---
write_csv(all_data, "merged_data_clean.csv")
