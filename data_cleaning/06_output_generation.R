# 06_output_generation.R
#
# Purpose: This module handles the final output generation for the Olympic medal prediction pipeline.
# It writes the processed medal model input data to CSV, identifies unmatched countries that could not
# be mapped to Olympic records, performs fuzzy string matching to suggest potential matches, generates
# a mapping backlog for manual review, creates a country reference table, and performs cleanup of
# intermediate variables. The module ensures all final outputs are properly documented and saved.
#
# Output Files Generated:
# - medals_model_input.csv: Final dataset combining macroeconomic predictors with medal outcomes,
#   ready for modeling. Contains one row per country-year with medal counts (gold, silver, bronze, total).
# - medal_match_gaps.csv: List of countries from macroeconomic data that could not be matched to any
#   Olympic medal records. These represent potential data gaps or mapping issues requiring investigation.
# - potential_matches.csv: Results of fuzzy string matching between unmatched countries and existing
#   Olympic countries. Uses Jaro-Winkler distance to suggest the top 3 closest matches for each unmatched
#   country, aiding in manual mapping decisions.
# - country_mapping_backlog.csv: Structured backlog of unmatched countries formatted for manual mapping.
#   Excludes countries already handled by manual overrides, providing a clean list for data stewards.
# - medal_country_reference.csv: Comprehensive reference table of all countries that have appeared in
#   Olympic medal records, including both historical and 2024 Paris data.
#
# Fuzzy Matching Algorithm:
# The fuzzy matching uses the Jaro-Winkler string distance metric (method = "jw") implemented via
# the stringdist package. This algorithm is particularly effective for country name matching because:
# - It accounts for character transpositions (common in name variations)
# - It gives higher weight to matches at the beginning of strings (important for country names)
# - It handles partial matches and abbreviations well
# - For each unmatched country, the top 3 closest matches are retained based on distance score
# - Lower distance scores indicate better matches (0 = perfect match, 1 = no similarity)
#
# Cleanup Process:
# The module removes intermediate variables that are no longer needed after output generation,
# keeping only the essential final datasets. This prevents memory bloat and ensures clean
# execution in modular pipelines.
#
# Data Sources Integration:
# - medal_model_input: Final joined dataset from country joining process
# - olympic_windows_prepped: Processed macroeconomic indicators with standardized identifiers
# - medals_with_paris: Combined historical and Paris 2024 medal data
# - manual_country_map: Existing manual country mapping overrides
#
# Outputs: Returns a list containing:
# - medals: The final medal model input dataset
# - unmatched: Countries that could not be matched to Olympic records
# - mapping_backlog: Structured backlog for manual mapping review
# - reference: Country reference table for Olympic medal data
#
# Dependencies:
# - Requires processed data from all preceding modules (01-05)
# - data.table: For efficient CSV writing (fwrite)
# - stringdist: For fuzzy string matching algorithms
# - dplyr: For data manipulation operations
# - readr: For CSV writing operations
#
# Usage: Source this script after completing the country joining process to generate final outputs
# and prepare the data for modeling or further analysis.

# Load required libraries
library(data.table)  # For efficient CSV writing with fwrite
library(stringdist)  # For fuzzy string matching algorithms
library(dplyr)       # For data manipulation
library(readr)       # For CSV writing

# Define output file paths (consistent with main pipeline)
manual_map_path <- "../data/country_manual_overrides.csv"
mapping_backlog_path <- "../data/country_mapping_backlog.csv"
country_reference_path <- "../data/medal_country_reference.csv"

# -----------------------------------------------------------------------------
# Write final medal model input to CSV ---------------------------------------
# -----------------------------------------------------------------------------

# Write the final modeling dataset to CSV for external use or archiving
# This dataset combines macroeconomic predictors with Olympic medal outcomes
fwrite(medal_model_input, "../data/medals_model_input.csv")

# -----------------------------------------------------------------------------
# Identify unmatched countries ------------------------------------------------
# -----------------------------------------------------------------------------

# Identify countries from macroeconomic data that have no corresponding Olympic medal records
# This helps identify data gaps or mapping issues that need resolution

# Get unique countries from the processed macroeconomic windows
countries_in_windows <- olympic_windows_prepped |>
  distinct(country, country_noc)

# Get unique countries from the combined medal data
countries_in_medals <- medals_with_paris |>
  distinct(country, country_noc)

# Find countries that exist in macroeconomic data but not in medal records
unmatched_countries <- countries_in_windows |>
  anti_join(countries_in_medals, by = "country_noc") |>  # Anti-join to find unmatched
  left_join(
    olympic_windows_prepped |>
      select(country, country_noc, country_source, country_noc_source) |>
      distinct(),
    by = c("country", "country_noc")
  ) |>
  select(
    country_source,      # Original country name from source data
    country_noc_source,  # Original NOC code from source data
    country,             # Processed country name
    country_noc          # Processed NOC code
  ) |>
  distinct() |>          # Remove duplicates
  arrange(country_source)  # Sort for easier review

# Write unmatched countries to CSV for analysis and manual review
fwrite(unmatched_countries, "../data/medal_match_gaps.csv")

# -----------------------------------------------------------------------------
# Perform fuzzy string matching for potential matches -----------------------
# -----------------------------------------------------------------------------

# Use fuzzy string matching to suggest potential country matches for unmatched countries
# This helps identify likely mapping candidates that can be manually verified

# Prepare unique unmatched countries for matching
unmatched_unique <- unmatched_countries |>
  select(unmatched_country = country_source, unmatched_noc = country_noc_source) |>
  distinct()

# Prepare unique countries from medal data as potential matches
medals_unique <- medals_with_paris |>
  select(potential_country = country, potential_noc = country_noc) |>
  distinct()

# Initialize empty dataframe for storing potential matches
potential_matches <- data.frame()

# Perform fuzzy matching for each unmatched country
# Uses Jaro-Winkler distance which is effective for name matching
for (i in 1:nrow(unmatched_unique)) {
  unmatched <- unmatched_unique[i, ]

  # Calculate string distances between unmatched country and all potential matches
  distances <- stringdist::stringdist(unmatched$unmatched_country, medals_unique$potential_country, method = "jw")

  # Add distances to potential matches dataframe
  medals_with_dist <- medals_unique |>
    mutate(distance = distances)

  # Select top 3 closest matches (lowest distance = best match)
  top3 <- medals_with_dist |>
    arrange(distance) |>  # Sort by distance (ascending)
    head(3)               # Take top 3

  # Add unmatched country info and select relevant columns
  top3 <- top3 |>
    mutate(unmatched_country = unmatched$unmatched_country,
           unmatched_noc = unmatched$unmatched_noc) |>
    select(unmatched_country, unmatched_noc, potential_country, potential_noc, distance)

  # Append to results
  potential_matches <- bind_rows(potential_matches, top3)
}

# Write potential matches to CSV for manual review and mapping decisions
write_csv(potential_matches, "../data/potential_matches.csv")

# -----------------------------------------------------------------------------
# Generate mapping backlog ---------------------------------------------------
# -----------------------------------------------------------------------------

# Create a structured backlog of countries needing manual mapping
# Excludes countries already handled by manual overrides to avoid duplication

country_mapping_backlog <- unmatched_countries |>
  select(
    source_country = country_source,
    source_country_noc = country_noc_source
  ) |>
  distinct() |>  # Remove duplicates
  anti_join(     # Exclude countries already manually mapped
    manual_country_map,
    by = c("source_country", "source_country_noc")
  ) |>
  mutate(        # Add empty columns for manual mapping
    target_country = NA_character_,
    target_country_noc = NA_character_,
    notes = NA_character_
  ) |>
  arrange(source_country)  # Sort for easier processing

# Write mapping backlog to CSV for manual review and updates
write_csv(country_mapping_backlog, mapping_backlog_path)

# -----------------------------------------------------------------------------
# Create country reference ---------------------------------------------------
# -----------------------------------------------------------------------------

# Create a comprehensive reference table of all countries in Olympic medal records
# This serves as a lookup table for country names and NOC codes

country_reference <- medals_with_paris |>
  distinct(country, country_noc) |>  # Get unique country-NOC combinations
  arrange(country)                   # Sort alphabetically

# Write country reference to CSV
fwrite(country_reference, country_reference_path)

# -----------------------------------------------------------------------------
# Perform variable cleanup ---------------------------------------------------
# -----------------------------------------------------------------------------

# Remove intermediate variables to clean up the workspace
# Keeps only essential final outputs and prevents memory bloat
rm(list = c(
  "unmatched_unique",    # Temporary variable for fuzzy matching
  "medals_unique",       # Temporary variable for fuzzy matching
  "potential_matches"    # Intermediate results of fuzzy matching
))

# -----------------------------------------------------------------------------
# Return final results list --------------------------------------------------
# -----------------------------------------------------------------------------

# Return a list containing all final outputs for use by calling scripts
# This provides structured access to the generated datasets
list(
  medals = medal_model_input,        # Final modeling dataset
  unmatched = unmatched_countries,   # Unmatched countries list
  mapping_backlog = country_mapping_backlog,  # Manual mapping backlog
  reference = country_reference      # Country reference table
)