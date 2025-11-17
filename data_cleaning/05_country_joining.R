# 05_country_joining.R
#
# Purpose: This module performs country matching and medal data joining logic for the
# Olympic medal prediction pipeline. It implements a sophisticated 3-stage joining process
# to match macroeconomic indicators with Olympic medal outcomes, ensuring comprehensive
# coverage of participating countries while handling various mapping challenges.
#
# Country Matching Strategy Overview:
# The module addresses the challenge of matching countries across different data sources
# (macroeconomic indicators vs. Olympic medal records) using a multi-stage validation approach.
# Countries may be represented differently across datasets due to historical changes,
# naming variations, and different coding standards (NOC vs ISO codes).
#
# 3-Stage Joining Logic:
# Stage 1 - Direct NOC Match: Attempts direct matching using National Olympic Committee (NOC) codes
# Stage 2 - ISO to IOC Mapping: For unmatched countries, converts ISO codes to IOC codes using mapping tables
# Stage 3 - Standardized Name Match: Final fallback using normalized country names for fuzzy matching
#
# Coalesce Priorities:
# The coalesce logic prioritizes matches in the following order:
# 1. Direct NOC match (most reliable - exact code match)
# 2. ISO->IOC mapping match (handles code system differences)
# 3. Standardized name match (handles naming variations)
# 4. Zero-fill for participating countries with no medal wins
#
# Match Validation Steps:
# 1. Create comprehensive list of all Olympic participants (winners + non-winners)
# 2. Identify countries from macroeconomic data that have valid Olympic mappings
# 3. Apply multi-stage validation: direct NOC, ISO->IOC, name matching
# 4. Filter to only countries with confirmed Olympic participation
# 5. Execute 3-stage joining with prioritized coalescing
#
# Data Sources Integration:
# - olympic_windows_prepped: Macroeconomic indicators with standardized country identifiers
# - medals_with_paris: Combined historical and Paris 2024 medal data
# - medals_by_year: Medal data subset focused on yearly performance
# - paris_nocs: Paris 2024 participating countries (includes non-medal winners)
# - noc_iso_all: Combined current and historical NOC-ISO code mappings
#
# Outputs: The following variable is assigned to the global environment:
# - medal_model_input: Final dataset combining macroeconomic predictors with medal outcomes
#
# Dependencies:
# - Requires processed data from 01_data_loading.R, 02_noc_mapping.R, 03_standardization.R, 04_medal_combination.R
#
# Usage: Source this script after the preceding data processing modules to create the
# final modeling dataset for Olympic medal outcome prediction.

# Load required libraries
library(dplyr)

# -----------------------------------------------------------------------------
# Create comprehensive Olympic participants list -------------------------------
# -----------------------------------------------------------------------------

# Create all_olympic_participants: comprehensive list of all countries that have participated in Olympics
# This includes both medal winners AND non-winners, ensuring complete coverage for matching
# Historical medal winners are extracted from medals_with_paris
# Paris 2024 participants (including non-medal winners) are added from paris_nocs
all_olympic_participants <- bind_rows(
  # Historical medal winners (includes countries that won medals in past Games)
  medals_with_paris |> distinct(country_noc),
  # 2024 participating countries (includes non-winners who still participated)
  paris_nocs |> select(country_noc = code) |> distinct()
) |> distinct()

# -----------------------------------------------------------------------------
# Identify countries with valid Olympic mappings ----------------------------
# -----------------------------------------------------------------------------

# Identify countries_with_mapping: determine which countries from macroeconomic data
# have valid mappings to Olympic records using multi-stage validation
#
# Validation stages:
# 1. Direct NOC match: Check if country_noc exists directly in Olympic participants
# 2. ISO->IOC mapping: Convert ISO codes to IOC codes and check for matches
# 3. Name matching: Use standardized country names for final validation
#
# A country has a valid mapping if ANY of the three validation methods succeeds
countries_with_mapping <- olympic_windows_prepped |>
  distinct(country_noc, country_std) |>  # Get unique country identifiers from predictors
  # Stage 1: Check direct NOC match against ALL Olympic participants
  left_join(
    all_olympic_participants |> mutate(direct_match = TRUE),
    by = "country_noc"
  ) |>
  # Stage 2: Check ISO->IOC mapping for additional matches
  left_join(
    noc_iso_all,  # Load NOC-ISO mapping table
    by = c("country_noc" = "ISO")  # Match ISO codes to get corresponding IOC codes
  ) |>
  left_join(
    all_olympic_participants |> mutate(ioc_match = TRUE),  # Flag IOC matches
    by = c("IOC" = "country_noc")  # Check if IOC code exists in participants
  ) |>
  # Stage 3: Check standardized name match for remaining validation
  left_join(
    medals_with_paris |> distinct(country_std) |> mutate(name_match = TRUE),  # Flag name matches
    by = "country_std"  # Match on standardized country names
  ) |>
  # A country has valid mapping if ANY validation method found it
  mutate(has_mapping = !is.na(direct_match) | !is.na(ioc_match) | !is.na(name_match)) |>
  # Filter to only countries that passed validation
  filter(has_mapping) |>
  # Select only the country_noc for filtering in next step
  select(country_noc)

# -----------------------------------------------------------------------------
# Perform 3-stage medal data joining ------------------------------------------
# -----------------------------------------------------------------------------

# Perform the actual medal join using the 3-stage approach with prioritized coalescing
# This creates the final modeling dataset by joining macroeconomic predictors with medal outcomes
medal_model_input <- olympic_windows_prepped |>
  # FIRST: Filter to only countries that exist in Olympic records (validated mappings)
  semi_join(countries_with_mapping, by = "country_noc") |>

  # Stage 1: Try direct NOC match (most reliable - exact code correspondence)
  left_join(
    medals_by_year,
    by = c("year", "country_noc"),
    suffix = c("", "_noc_direct")  # Suffix to avoid column name conflicts
  ) |>

  # Stage 2: For unmatched records, try ISO -> IOC mapping
  # This handles cases where macroeconomic data uses ISO codes but Olympics use IOC codes
  left_join(
    noc_iso_all,  # Get IOC codes corresponding to ISO codes
    by = c("country_noc" = "ISO")
  ) |>
  left_join(
    medals_by_year |>  # Join medal data using IOC codes
      select(year, country_noc, gold_ioc = gold,
             silver_ioc = silver, bronze_ioc = bronze, total_ioc = total),
    by = c("year", "IOC" = "country_noc")
  ) |>

  # Stage 3: For still unmatched records, try standardized country name matching
  # This handles naming variations and historical changes
  left_join(
    medals_by_year |>  # Join medal data using standardized names
      select(year, country_std, gold_name = gold,
             silver_name = silver, bronze_name = bronze, total_name = total),
    by = c("year", "country_std")
  ) |>

  # Coalesce: Combine results from all three stages with clear priority order
  # Priority: Direct NOC match > ISO->IOC mapping > Name match > Zero (for participants)
  mutate(
    gold = coalesce(gold, gold_ioc, gold_name),      # Use first successful match
    silver = coalesce(silver, silver_ioc, silver_name),
    bronze = coalesce(bronze, bronze_ioc, bronze_name),
    total = coalesce(total, total_ioc, total_name),
    # Fill remaining NAs with 0 for countries that participated but won no medals
    gold = coalesce(gold, 0L),
    silver = coalesce(silver, 0L),
    bronze = coalesce(bronze, 0L),
    total = coalesce(total, 0L)
  ) |>

  # Clean up intermediate columns used in joining process
  select(-gold_ioc, -silver_ioc, -bronze_ioc, -total_ioc,
         -gold_name, -silver_name, -bronze_name, -total_name,
         -IOC, -country_noc_direct, -country_std, -country)