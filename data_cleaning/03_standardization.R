# 03_standardization.R
#
# Purpose: This module standardizes country names and preprocesses Olympic medal data
# for consistent matching across different data sources. It implements country name
# normalization, applies manual override mappings, and performs type conversions
# to prepare data for medal outcome prediction modeling.
#
# Standardization Function Overview:
# The standardize_country_name() function normalizes country names by:
# - Converting to lowercase and trimming whitespace
# - Removing common prefixes/suffixes like "the"
# - Stripping parenthetical notes (e.g., "(Republic of)")
# - Replacing special characters with spaces
# - Removing extra whitespace
# This creates a standardized version for fuzzy matching across datasets.
#
# Manual Override Application:
# Manual overrides are applied to olympic_windows data to correct known mapping issues.
# The process preserves original values while allowing targeted corrections for countries
# that don't match automatically. Overrides are stored in country_manual_overrides.csv
# and can be updated as new mapping issues are discovered.
#
# Preprocessing Steps:
# 1. Standardize country names in olympic_windows data
# 2. Apply manual country name and NOC code overrides
# 3. Standardize and convert medal data types
# 4. Calculate the latest edition ID for Paris 2024 assignment
# 5. Transform Paris 2024 medal data to match historical format
#
# Dependencies:
# - Requires data loaded by 01_data_loading.R (olympic_windows, medals, paris_medals_raw)
# - Requires mappings loaded by 02_noc_mapping.R (manual_country_map)
#
# Outputs: The following variables are assigned to the global environment:
# - olympic_windows_prepped: Olympic windows data with standardized names and manual overrides
# - medals: Processed historical medal data with standardized names and proper types
# - paris_medals: Transformed Paris 2024 medal data matching historical format
# - latest_edition_id: Latest edition ID from historical data (used for Paris 2024)
#
# Usage: Source this script after 01_data_loading.R and 02_noc_mapping.R to prepare
# standardized data for medal prediction modeling.

# Load required libraries
library(stringr)

# -----------------------------------------------------------------------------
# Standardize identifiers and numeric columns ---------------------------------
# -----------------------------------------------------------------------------

# Helper function to standardize country names for matching
# This function normalizes country names to enable consistent matching across datasets
# by removing variations in formatting, punctuation, and common prefixes/suffixes.
#
# Parameters:
#   name: Character string representing a country name
#
# Returns:
#   Standardized country name as a lowercase string with normalized formatting
#
# Processing steps:
# 1. Trim leading/trailing whitespace
# 2. Convert to lowercase
# 3. Remove "the" prefix or suffix
# 4. Remove parenthetical notes (e.g., "(Republic of)")
# 5. Replace special characters with spaces
# 6. Remove extra whitespace
standardize_country_name <- function(name) {
  name |>
    str_trim() |>                           # Remove leading/trailing whitespace
    str_to_lower() |>                       # Convert to lowercase for case-insensitive matching
    # Remove common prefixes/suffixes
    str_remove("^the\\s+") |>               # Remove "the" at start
    str_remove(",\\s*the$") |>              # Remove ", the" at end
    str_remove("\\s+\\(.*\\)$") |>          # Remove parenthetical notes like "(Republic of)"
    str_replace_all("[^a-z0-9]", " ") |>    # Replace special chars with space
    str_squish()                            # Remove extra whitespace
}

# Process olympic_windows: standardize country names and prepare for manual overrides
# Rename country_code to country_noc for consistency, trim strings, convert year to integer,
# and add standardized country name column for matching
olympic_windows <- olympic_windows |>
  rename(country_noc = country_code) |>     # Rename for consistency with other datasets
  mutate(
    country = str_trim(country),            # Trim country name
    country_noc = str_trim(country_noc),    # Trim NOC code
    year = as.integer(year),                # Ensure year is integer
    country_std = standardize_country_name(country)  # Add standardized name for matching
  )

# Create olympic_windows_prepped: apply manual country overrides
# This step applies manual corrections for countries that don't match automatically.
# The process preserves original values (country_source, country_noc_source) while
# allowing targeted corrections via the manual_country_map lookup table.
olympic_windows_prepped <- olympic_windows |>
  mutate(
    country_source = country,               # Preserve original country name
    country_noc_source = country_noc        # Preserve original NOC code
  ) |>
  left_join(                                # Join with manual override table
    manual_country_map,
    by = c(
      "country_source" = "source_country",
      "country_noc_source" = "source_country_noc"
    )
  ) |>
  mutate(
    country = coalesce(target_country, country),        # Use override if available, else original
    country_noc = coalesce(target_country_noc, country_noc),  # Same for NOC code
    manual_mapping_note = mapping_note                   # Preserve override reason
  ) |>
  select(-target_country, -target_country_noc, -mapping_note)  # Clean up temporary columns

# Process medals: standardize country names and convert data types
# Trim NOC codes, convert year to integer, convert medal counts to integers,
# and add standardized country name for matching
medals <- medals |>
  mutate(
    country_noc = str_trim(country_noc),    # Trim NOC code
    year = as.integer(year),                # Ensure year is integer
    across(c(gold, silver, bronze, total), as.integer),  # Convert medal counts to integers
    country_std = standardize_country_name(country)      # Add standardized name
  )

# Calculate latest_edition_id: find the highest edition ID from historical medals
# This is used to assign the next edition ID to Paris 2024 data
latest_edition_id <- medals |>
  summarise(max_id = max(edition_id, na.rm = TRUE)) |>  # Get maximum edition ID
  pull(max_id)

# Handle case where no valid edition IDs exist (set to 0)
if (!is.finite(latest_edition_id)) {
  latest_edition_id <- 0L
}

# Process paris_medals_raw: transform Paris 2024 data to match historical format
# Rename columns to standard format, trim NOC codes, convert medal counts to integers,
# standardize country names using country_long field, and add required metadata fields
paris_medals <- paris_medals_raw |>
  rename(                                   # Rename columns to match historical format
    country_noc = country_code,
    gold = `Gold Medal`,
    silver = `Silver Medal`,
    bronze = `Bronze Medal`,
    total = Total
  ) |>
  mutate(
    country_noc = str_trim(country_noc),    # Trim NOC code
    across(c(gold, silver, bronze, total), as.integer),  # Convert medal counts to integers
    country_std = standardize_country_name(country_long)  # Standardize using country_long
  ) |>
  transmute(                                 # Select and add required columns
    edition = "2024 Summer Olympics",       # Add edition name
    edition_id = latest_edition_id + 1L,    # Assign next edition ID
    year = 2024L,                           # Set year
    country = country_long,                 # Use full country name
    country_std,                            # Include standardized name
    country_noc,                            # Include NOC code
    gold, silver, bronze, total             # Include medal counts
  )