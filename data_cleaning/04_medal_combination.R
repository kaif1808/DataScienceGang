# 04_medal_combination.R
#
# Purpose: This module combines historical Olympic medal data with Paris 2024 medal data
# and creates a standardized subset for analysis. It performs the final data integration
# step before medal outcome prediction modeling.
#
# Combination Logic:
# - Historical medal data (medals) contains records from past Olympic Games with standardized
#   columns: edition, edition_id, year, country, country_std, country_noc, gold, silver, bronze, total
# - Paris 2024 medal data (paris_medals) has been transformed to match the historical format
#   with the same column structure and an assigned edition_id (latest_edition_id + 1)
# - bind_rows() combines these datasets vertically, creating a unified medal dataset
# - The resulting medals_with_paris contains all historical and current Olympic medal records
#
# medals_by_year Subset:
# - Created as a focused subset of medals_with_paris for modeling purposes
# - Includes only essential columns: year, country identifiers, and medal counts
# - Excludes edition and edition_id fields to focus on temporal and geographic patterns
# - Maintains standardized country names (country_std) for consistent matching
#
# Data Schema - medals_with_paris:
# - edition: Character string describing the Olympic Games (e.g., "2024 Summer Olympics")
# - edition_id: Integer identifier for each Olympic edition (sequential)
# - year: Integer year of the Olympic Games
# - country: Full country name as reported in medal data
# - country_std: Standardized country name for matching (lowercase, normalized)
# - country_noc: 3-letter NOC (National Olympic Committee) code
# - gold: Integer count of gold medals won
# - silver: Integer count of silver medals won
# - bronze: Integer count of bronze medals won
# - total: Integer total medal count (gold + silver + bronze)
#
# Data Schema - medals_by_year:
# - year: Integer year of the Olympic Games
# - country: Full country name as reported in medal data
# - country_std: Standardized country name for matching
# - country_noc: 3-letter NOC code
# - gold: Integer count of gold medals won
# - silver: Integer count of silver medals won
# - bronze: Integer count of bronze medals won
# - total: Integer total medal count
#
# Dependencies:
# - Requires medals (processed historical data) from 03_standardization.R
# - Requires paris_medals (transformed Paris 2024 data) from 03_standardization.R
#
# Outputs: The following variables are assigned to the global environment:
# - medals_with_paris: Combined historical and Paris 2024 medal dataset
# - medals_by_year: Subset focused on yearly medal performance by country
#
# Usage: Source this script after 03_standardization.R to create the combined medal
# datasets required for prediction modeling and analysis.

# Load required libraries
library(dplyr)

# -----------------------------------------------------------------------------
# Combine historical medals with Paris 2024 -----------------------------------
# -----------------------------------------------------------------------------

# Combine historical and Paris 2024 medal data using bind_rows
# This creates a unified dataset containing all Olympic medal records
# from historical Games plus the most recent Paris 2024 Olympics
medals_with_paris <- bind_rows(medals, paris_medals)

# Create medals_by_year subset for focused analysis
# This subset includes only the essential columns needed for modeling:
# - year: Olympic year for temporal analysis
# - country identifiers: for geographic analysis
# - medal counts: the prediction targets
medals_by_year <- medals_with_paris |>
  select(year, country, country_std, country_noc, gold, silver, bronze, total)