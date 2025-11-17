# Load necessary libraries
library(dplyr)
library(tidyr)

# --- Step 1A: Load Your Real Data ---

# Define your base path
base_path <- "/Users/rayyaankazi/Desktop/DataScienceGang/DataScienceGang/Rayyaan_Data"

# Load the file that needs reshaping
Obesity_v2 <- read.csv(file.path(base_path, "Obesity_v2.csv"))

# Load the files already in the correct wide format
Life_v2 <- read.csv(file.path(base_path, "Life_v2.csv"))
Schooling_v2 <- read.csv(file.path(base_path, "Schooling_v2.csv"))
Literacy_v2 <- read.csv(file.path(base_path, "Literacy_v2.csv"))


# --- Step 1B: FIX THE DATA TYPES ---
# This is the new, crucial step.
# We convert all columns EXCEPT Country, Code, and Indicator to numeric.

Life_v2 <- Life_v2 %>%
  mutate(across(!c(country, code, indicator), as.numeric))

Schooling_v2 <- Schooling_v2 %>%
  mutate(across(!c(country, code, indicator), as.numeric))

Literacy_v2 <- Literacy_v2 %>%
  mutate(across(!c(country, code, indicator), as.numeric))

# ------------------------------------


# --- Step 2: Reshape Obesity_v2 from Long to Wide ---

# This step remains the same.
# We assume 'Year' and 'Value' are the correct column names
# in your Obesity_v2.csv file.
obesity_wide <- Obesity_v2 %>%
  pivot_wider(
    id_cols = c(country, code, indicator), # Columns to keep
    names_from = Year,                   # Column with year values
    values_from = Value                  # Column with data values
  )


# --- Step 3: Combine (Stack) All Datasets ---

# This will now work because all year columns
# in all data frames are numeric.

all_data_merged <- bind_rows(
  obesity_wide,
  Life_v2,
  Schooling_v2,
  Literacy_v2
)

# --- Optional: View Your Results ---

print("Reshaped Obesity Data:")
print(head(obesity_wide))

print("Final Merged Data:")
print(head(all_data_merged))

# --- Optional: Save Your Final Merged File ---

# write.csv(
#   all_data_merged,
#   file.path(base_path, "final_merged_data.csv"),
#   row.names = FALSE
# )