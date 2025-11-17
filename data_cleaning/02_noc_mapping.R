# 02_noc_mapping.R
#
# Purpose: This module prepares NOC (National Olympic Committee) to ISO country code mappings
# and manual country overrides for the Olympic medal prediction pipeline. It handles the
# standardization of country identifiers across different data sources.
#
# Mapping Logic Overview:
# - NOC codes are 3-letter codes used by the International Olympic Committee (e.g., "USA", "GBR")
# - ISO codes are 3-letter country codes from ISO 3166-1 alpha-3 standard (e.g., "USA", "GBR")
# - While NOC and ISO codes often match, there are historical differences and special cases
# - The module loads current and historical NOC-ISO mappings to handle these variations
# - Manual overrides allow for custom mappings when automated matching fails
#
# Data Sources:
# - ISO_NOC_codes.csv: Current NOC to ISO mappings
# - ISO_NOC_codes_old.csv: Historical NOC to ISO mappings (for legacy data)
# - country_manual_overrides.csv: Manual corrections for problematic country mappings
#
# Processing Steps:
# 1. Load current NOC-ISO mapping, filter valid entries, trim and standardize codes
# 2. Load historical NOC-ISO mapping with similar processing
# 3. Combine current and historical mappings, removing duplicates
# 4. Load or create manual override table for custom mappings
#
# Manual Override Structure:
# The manual_country_map table contains columns:
# - source_country: Original country name from source data
# - source_country_noc: Original NOC code from source data
# - target_country: Corrected country name to use
# - target_country_noc: Corrected NOC code to use
# - mapping_note: Explanation of why the override was needed
#
# Usage: Source this script early in the data cleaning pipeline to establish country
# code mappings before merging datasets. The defined variables will be available
# in the global environment for use by subsequent processing modules.
#
# Outputs: The following tibbles are assigned to the global environment:
# - noc_iso_mapping: Current NOC to ISO code mappings
# - noc_iso_mapping_old: Historical NOC to ISO code mappings
# - noc_iso_all: Combined current and historical mappings (deduplicated)
# - manual_country_map: Manual override mappings for country corrections

# Load required libraries
library(data.table)
library(dplyr)
library(readr)
library(stringr)

# -----------------------------------------------------------------------------
# Load NOC/ISO code mapping tables -------------------------------------------
# -----------------------------------------------------------------------------

# Load current NOC-ISO mapping
# - Select relevant columns: Country name, IOC (NOC) code, ISO code
# - Filter out entries with missing NOC or ISO codes
# - Trim whitespace and limit ISO codes to first 3 characters (standard format)
noc_iso_mapping <- fread("../data/ISO_NOC_codes.csv") |>
   as_tibble() |>
   select(Country, IOC, ISO) |>
   filter(!is.na(IOC), !is.na(ISO)) |>
   mutate(
     IOC = str_trim(IOC),
     ISO = str_sub(ISO, 1, 3),  # Keep only first 3 characters
     ISO = str_trim(ISO)
   )

# Load historical NOC-ISO mapping
# - Similar processing to current mapping
# - Both IOC and ISO codes are limited to 3 characters (historical data may have variations)
noc_iso_mapping_old <- fread("../data/ISO_NOC_codes_old.csv") |>
  as_tibble() |>
  select(Country, IOC, ISO) |>
  filter(!is.na(IOC), !is.na(ISO)) |>
  mutate(
    IOC = str_sub(IOC, 1, 3),  # Keep only first 3 characters
    ISO = str_sub(ISO, 1, 3),  # Keep only first 3 characters
    IOC = str_trim(IOC),
    ISO = str_trim(ISO)
  )

# Combine current and old mappings
# - Bind rows from both tables
# - Keep only unique IOC-ISO pairs
# - Filter out empty strings
noc_iso_all <- bind_rows(noc_iso_mapping, noc_iso_mapping_old) |>
  distinct(IOC, ISO) |>
  filter(IOC != "", ISO != "")

# -----------------------------------------------------------------------------
# Load manual country override mappings ---------------------------------------
# -----------------------------------------------------------------------------

# Define file paths for manual override and related files
manual_map_path <- "../data/country_manual_overrides.csv"

# Load manual country mapping overrides
# - If the file exists, read it
# - If not, create an empty template and save it
# - This allows users to add manual corrections without breaking the pipeline
manual_country_map <- if (file.exists(manual_map_path)) {
  read_csv(manual_map_path, show_col_types = FALSE)
} else {
  # Create empty template with required columns
  manual_template <- tibble(
    source_country = character(),
    source_country_noc = character(),
    target_country = character(),
    target_country_noc = character(),
    mapping_note = character()
  )
  write_csv(manual_template, manual_map_path)
  manual_template
}

# Process manual mapping table
# - Trim whitespace from all text columns
# - Convert empty strings to NA for consistency
manual_country_map <- manual_country_map |>
  mutate(
    across(
      c(source_country, source_country_noc, target_country, target_country_noc),
      ~ {
        trimmed <- str_trim(coalesce(., ""))
        na_if(trimmed, "")
      }
    ),
    mapping_note = str_trim(coalesce(mapping_note, ""))
  )