# ==============================================================================
# Compare Countries
# ==============================================================================
# Optional diagnostic script to compare country name-code pairs between datasets
# Extracts unique pairs from merged_data and medals, finds matches, and identifies discrepancies

library(data.table)

compare_countries <- function(merged_data, medals) {
  # Extract unique pairs from merged_data
  if ("Country Code" %in% names(merged_data)) {
    # Extract unique Country Name-Country Code pairs
    country_pairs_merged <- unique(merged_data[, .(`Country Name`, `Country Code`)], 
                                   by = c("Country Name", "Country Code"))
  } else {
    # If Country Code doesn't exist, extract just unique Country Names
    country_pairs_merged <- unique(merged_data[, .(`Country Name`)])
    country_pairs_merged[, `Country Code` := NA_character_]
  }
  
  # Remove rows with missing country names
  country_pairs_merged <- country_pairs_merged[!is.na(`Country Name`), ]
  
  # Sort by Country Name for easier comparison
  setorder(country_pairs_merged, `Country Name`)
  
  # Extract unique pairs from medals
  country_pairs_medals <- unique(medals[, .(country, country_noc)], 
                                 by = c("country", "country_noc"))
  
  # Rename columns to match merged_data format for consistency
  setnames(country_pairs_medals, c("country", "country_noc"), 
           c("Country Name", "Country Code"))
  
  # Remove rows with missing country names
  country_pairs_medals <- country_pairs_medals[!is.na(`Country Name`), ]
  
  # Sort by Country Name for easier comparison
  setorder(country_pairs_medals, `Country Name`)
  
  # Find matches by Country Name (regardless of code)
  # Get the intersection of country names from both tables
  matched_names <- intersect(country_pairs_merged$`Country Name`, 
                             country_pairs_medals$`Country Name`)
  
  # Find matches by Country Code (only where codes are not NA)
  # Get non-NA codes from both tables
  codes_merged <- country_pairs_merged[!is.na(`Country Code`), `Country Code`]
  codes_medals <- country_pairs_medals[!is.na(`Country Code`), `Country Code`]
  
  # Find matching codes
  matched_codes <- intersect(codes_merged, codes_medals)
  
  # Get all Country Names associated with matched codes (from both tables)
  matched_names_by_code_merged <- country_pairs_merged[`Country Code` %in% matched_codes & 
                                                        !is.na(`Country Code`), `Country Name`]
  matched_names_by_code_medals <- country_pairs_medals[`Country Code` %in% matched_codes & 
                                                        !is.na(`Country Code`), `Country Name`]
  
  # Combine all matched names (by name OR by code) - union of all matches
  all_matched_names <- unique(c(matched_names, matched_names_by_code_merged, 
                                matched_names_by_code_medals))
  
  # Remove matches from both tables (keep only discrepancies)
  country_pairs_merged_unmatched <- country_pairs_merged[!`Country Name` %in% all_matched_names, ]
  country_pairs_medals_unmatched <- country_pairs_medals[!`Country Name` %in% all_matched_names, ]
  
  # Return comparison results
  return(list(
    merged_countries = country_pairs_merged,
    medals_countries = country_pairs_medals,
    matched_names = matched_names,
    matched_codes = matched_codes,
    all_matched_names = all_matched_names,
    unmatched_merged = country_pairs_merged_unmatched,
    unmatched_medals = country_pairs_medals_unmatched
  ))
}

