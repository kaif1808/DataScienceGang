library(data.table)
library(dplyr)
library(readr)
library(stringr)
library(stringdist)

rm(list = ls())

# -----------------------------------------------------------------------------
# Load source tables ----------------------------------------------------------
# -----------------------------------------------------------------------------

olympic_windows <- fread("pre_medal.csv") |> as_tibble()
medals <- fread("data/Olympic_Medal_Tally_History.csv") |> as_tibble()
paris_medals_raw <- fread("2024olympics/medals_total.csv") |> as_tibble()
paris_nocs <- fread("2024olympics/nocs.csv") |> as_tibble()  # All participating countries

# Load NOC/ISO code mapping tables
noc_iso_mapping <- fread("ISO_NOC_codes.csv") |> 
  as_tibble() |>
  select(Country, IOC, ISO) |>
  filter(!is.na(IOC), !is.na(ISO)) |>
  mutate(
    IOC = str_trim(IOC),
    ISO = str_sub(ISO, 1, 3),  # Keep only first 3 characters
    ISO = str_trim(ISO)
  )

noc_iso_mapping_old <- fread("ISO_NOC_codes_old.csv") |> 
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
noc_iso_all <- bind_rows(noc_iso_mapping, noc_iso_mapping_old) |>
  distinct(IOC, ISO) |>
  filter(IOC != "", ISO != "")

manual_map_path <- "country_manual_overrides.csv"
mapping_backlog_path <- "country_mapping_backlog.csv"
country_reference_path <- "medal_country_reference.csv"

manual_country_map <- if (file.exists(manual_map_path)) {
  read_csv(manual_map_path, show_col_types = FALSE)
} else {
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

# -----------------------------------------------------------------------------
# Standardise identifiers and numeric columns ---------------------------------
# -----------------------------------------------------------------------------

# Helper function to standardize country names for matching
standardize_country_name <- function(name) {
  name |>
    str_trim() |>
    str_to_lower() |>
    # Remove common prefixes/suffixes
    str_remove("^the\\s+") |>
    str_remove(",\\s*the$") |>
    str_remove("\\s+\\(.*\\)$") |>  # Remove parenthetical notes
    str_replace_all("[^a-z0-9]", " ") |>  # Replace special chars with space
    str_squish()  # Remove extra whitespace
}

olympic_windows <- olympic_windows |>
  rename(country_noc = country_code) |>
  mutate(
    country = str_trim(country),
    country_noc = str_trim(country_noc),
    year = as.integer(year),
    country_std = standardize_country_name(country)
  )

olympic_windows_prepped <- olympic_windows |>
  mutate(
    country_source = country,
    country_noc_source = country_noc
  ) |>
  left_join(
    manual_country_map,
    by = c(
      "country_source" = "source_country",
      "country_noc_source" = "source_country_noc"
    )
  ) |>
  mutate(
    country = coalesce(target_country, country),
    country_noc = coalesce(target_country_noc, country_noc),
    manual_mapping_note = mapping_note
  ) |>
  select(-target_country, -target_country_noc, -mapping_note)

medals <- medals |>
  mutate(
    country_noc = str_trim(country_noc),
    year = as.integer(year),
    across(c(gold, silver, bronze, total), as.integer),
    country_std = standardize_country_name(country)
  )

latest_edition_id <- medals |>
  summarise(max_id = max(edition_id, na.rm = TRUE)) |>
  pull(max_id)

if (!is.finite(latest_edition_id)) {
  latest_edition_id <- 0L
}

paris_medals <- paris_medals_raw |>
  rename(
    country_noc = country_code,
    gold = `Gold Medal`,
    silver = `Silver Medal`,
    bronze = `Bronze Medal`,
    total = Total
  ) |>
  mutate(
    country_noc = str_trim(country_noc),
    across(c(gold, silver, bronze, total), as.integer),
    country_std = standardize_country_name(country_long)
  ) |>
  transmute(
    edition = "2024 Summer Olympics",
    edition_id = latest_edition_id + 1L,
    year = 2024L,
    country = country_long,
    country_std,
    country_noc,
    gold,
    silver,
    bronze,
    total
  )

# -----------------------------------------------------------------------------
# Combine historical medals with Paris 2024 -----------------------------------
# -----------------------------------------------------------------------------

medals_with_paris <- bind_rows(medals, paris_medals)

medals_by_year <- medals_with_paris |>
  select(year, country, country_std, country_noc, gold, silver, bronze, total)

# -----------------------------------------------------------------------------
# Join macro window features with medal outcomes ------------------------------
# -----------------------------------------------------------------------------

# Create a comprehensive list of all countries that participated in Olympics
# This includes both medal winners AND non-winners
all_olympic_participants <- bind_rows(
  # Historical medal winners
  medals_with_paris |> distinct(country_noc),
  # 2024 participating countries (includes non-winners)
  paris_nocs |> select(country_noc = code) |> distinct()
) |> distinct()

# Identify which countries from olympic_windows exist in Olympic records
# (either directly by NOC, via ISO->IOC mapping, or by name)
countries_with_mapping <- olympic_windows_prepped |>
  distinct(country_noc, country_std) |>
  # Check direct NOC match against ALL participants
  left_join(
    all_olympic_participants |> mutate(direct_match = TRUE),
    by = "country_noc"
  ) |>
  # Check ISO->IOC mapping
  left_join(
    noc_iso_all,
    by = c("country_noc" = "ISO")
  ) |>
  left_join(
    all_olympic_participants |> mutate(ioc_match = TRUE),
    by = c("IOC" = "country_noc")
  ) |>
  # Check standardized name match
  left_join(
    medals_with_paris |> distinct(country_std) |> mutate(name_match = TRUE),
    by = "country_std"
  ) |>
  # A country has a valid mapping if ANY of the three methods found it
  mutate(has_mapping = !is.na(direct_match) | !is.na(ioc_match) | !is.na(name_match)) |>
  filter(has_mapping) |>
  select(country_noc)

# Now perform the actual medal join, keeping only countries with valid mappings
medal_model_input <- olympic_windows_prepped |>
  # FIRST: Filter to only countries that exist in Olympic records
  semi_join(countries_with_mapping, by = "country_noc") |>
  # THEN: Join medal data using the three-stage approach
  # Step 1: Try direct NOC match
  left_join(
    medals_by_year, 
    by = c("year", "country_noc"),
    suffix = c("", "_noc_direct")
  ) |>
  # Step 2: For unmatched, try ISO -> IOC mapping
  left_join(
    noc_iso_all,
    by = c("country_noc" = "ISO")
  ) |>
  left_join(
    medals_by_year |>
      select(year, country_noc, gold_ioc = gold, 
             silver_ioc = silver, bronze_ioc = bronze, total_ioc = total),
    by = c("year", "IOC" = "country_noc")
  ) |>
  # Step 3: For still unmatched, try standardized country name
  left_join(
    medals_by_year |>
      select(year, country_std, gold_name = gold, 
             silver_name = silver, bronze_name = bronze, total_name = total),
    by = c("year", "country_std")
  ) |>
  # Coalesce: use first successful match
  mutate(
    gold = coalesce(gold, gold_ioc, gold_name),
    silver = coalesce(silver, silver_ioc, silver_name),
    bronze = coalesce(bronze, bronze_ioc, bronze_name),
    total = coalesce(total, total_ioc, total_name),
    # Fill remaining NAs with 0 for countries that participated but won no medals
    gold = coalesce(gold, 0L),
    silver = coalesce(silver, 0L),
    bronze = coalesce(bronze, 0L),
    total = coalesce(total, 0L)
  ) |>
  select(-gold_ioc, -silver_ioc, -bronze_ioc, -total_ioc,
         -gold_name, -silver_name, -bronze_name, -total_name, 
         -IOC, -country_noc_direct, -country_std, -country)

fwrite(medal_model_input, "medals_model_input.csv")

# Identify truly unmatched countries: those in olympic_windows but not in medals data at all
# (not just rows with zero medals, but countries that never appear in medal records)
countries_in_windows <- olympic_windows_prepped |>
  distinct(country, country_noc)

countries_in_medals <- medals_with_paris |>
  distinct(country, country_noc)

unmatched_countries <- countries_in_windows |>
  anti_join(countries_in_medals, by = "country_noc") |>
  left_join(
    olympic_windows_prepped |> 
      select(country, country_noc, country_source, country_noc_source) |> 
      distinct(),
    by = c("country", "country_noc")
  ) |>
  select(
    country_source,
    country_noc_source,
    country,
    country_noc
  ) |>
  distinct() |>
  arrange(country_source)

fwrite(unmatched_countries, "medal_match_gaps.csv")

# Fuzzy matching for potential country matches
unmatched_unique <- unmatched_countries |>
  select(unmatched_country = country_source, unmatched_noc = country_noc_source) |>
  distinct()

medals_unique <- medals_with_paris |>
  select(potential_country = country, potential_noc = country_noc) |>
  distinct()

potential_matches <- data.frame()

for (i in 1:nrow(unmatched_unique)) {
  unmatched <- unmatched_unique[i, ]
  distances <- stringdist::stringdist(unmatched$unmatched_country, medals_unique$potential_country, method = "jw")
  medals_with_dist <- medals_unique |>
    mutate(distance = distances)
  top3 <- medals_with_dist |>
    arrange(distance) |>
    head(3)
  top3 <- top3 |>
    mutate(unmatched_country = unmatched$unmatched_country,
           unmatched_noc = unmatched$unmatched_noc) |>
    select(unmatched_country, unmatched_noc, potential_country, potential_noc, distance)
  potential_matches <- bind_rows(potential_matches, top3)
}

write_csv(potential_matches, "potential_matches.csv")

country_mapping_backlog <- unmatched_countries |>
  select(
    source_country = country_source,
    source_country_noc = country_noc_source
  ) |>
  distinct() |>
  anti_join(
    manual_country_map,
    by = c("source_country", "source_country_noc")
  ) |>
  mutate(
    target_country = NA_character_,
    target_country_noc = NA_character_,
    notes = NA_character_
  ) |>
  arrange(source_country)

write_csv(country_mapping_backlog, mapping_backlog_path)

country_reference <- medals_with_paris |>
  distinct(country, country_noc) |>
  arrange(country)

fwrite(country_reference, country_reference_path)

# -----------------------------------------------------------------------------
# Cleanup intermediate variables -----------------------------------------------
# -----------------------------------------------------------------------------
rm(list = c(
  "olympic_windows",
  "medals",
  "paris_medals_raw",
  "manual_country_map",
  "olympic_windows_prepped",
  "latest_edition_id",
  "paris_medals",
  "medals_with_paris",
  "medals_by_year",
  "unmatched_unique",
  "medals_unique",
  "potential_matches"
))

list(
  medals = medal_model_input,
  unmatched = unmatched_countries,
  mapping_backlog = country_mapping_backlog,
  reference = country_reference
)