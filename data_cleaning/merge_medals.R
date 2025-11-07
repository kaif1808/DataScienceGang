# ==============================================================================
# Merge with Medals Data
# ==============================================================================
# Merges merged_data with medals data using name and code matching

library(data.table)

merge_medals <- function(merged_data, medals) {
  # Standardize medals column names to match merged_data format
  medals_standardized <- copy(medals)
  setnames(medals_standardized, c("country", "country_noc", "year"), 
           c("Country Name", "Country Code", "Year"))
  
  # Create a copy of merged_data to track which rows have been matched
  merged_data_with_medals <- copy(merged_data)
  merged_data_with_medals[, matched := FALSE]
  
  # First merge: Match by (Country Name, Year)
  # Merge medals data where Country Name and Year match
  merged_by_name <- merge(merged_data_with_medals, 
                          medals_standardized[, .(`Country Name`, Year, gold, silver, bronze, total, edition, edition_id)],
                          by = c("Country Name", "Year"), 
                          all.x = TRUE, 
                          all.y = FALSE)
  
  # Mark rows that were matched
  merged_by_name[!is.na(gold), matched := TRUE]
  
  # Identify unmatched rows (where matched is still FALSE and Country Code exists)
  unmatched_rows <- merged_by_name[matched == FALSE & !is.na(`Country Code`), ]
  
  # Second merge: For unmatched rows, try matching by (Country Code, Year)
  if (nrow(unmatched_rows) > 0) {
    # Get the unmatched rows without the medal columns
    unmatched_base <- unmatched_rows[, setdiff(names(unmatched_rows), 
                                                c("gold", "silver", "bronze", "total", "edition", "edition_id", "matched")), 
                                     with = FALSE]
    
    # Merge unmatched rows by Country Code and Year
    unmatched_merged <- merge(unmatched_base,
                              medals_standardized[, .(`Country Code`, Year, gold, silver, bronze, total, edition, edition_id)],
                              by = c("Country Code", "Year"),
                              all.x = TRUE,
                              all.y = FALSE)
    
    # Mark newly matched rows
    unmatched_merged[!is.na(gold), matched := TRUE]
    
    # Get rows that were matched by code (to update in main dataset)
    matched_by_code <- unmatched_merged[matched == TRUE, ]
    
    # Update the main dataset with code-based matches
    # Remove the unmatched rows and add back the code-matched ones
    merged_by_name <- merged_by_name[matched == TRUE | is.na(`Country Code`), ]
    merged_by_name <- rbindlist(list(merged_by_name, matched_by_code), use.names = TRUE, fill = TRUE)
    
    # Also add back unmatched rows that still didn't match (for completeness)
    still_unmatched <- unmatched_merged[matched == FALSE, ]
    if (nrow(still_unmatched) > 0) {
      merged_by_name <- rbindlist(list(merged_by_name, still_unmatched), use.names = TRUE, fill = TRUE)
    }
  }
  
  # Remove the temporary matched column
  merged_by_name[, matched := NULL]
  
  # Ensure medal columns exist (add them as NA if they don't exist from merge)
  medal_cols_expected <- c("gold", "silver", "bronze", "total", "edition", "edition_id")
  for (col in medal_cols_expected) {
    if (!col %in% names(merged_by_name)) {
      merged_by_name[, (col) := NA]
    }
  }
  
  # Handle potential duplicate rows (if a country-year appears multiple times in medals)
  # Aggregate medal counts if there are duplicates
  if (anyDuplicated(merged_by_name, by = c("Country Name", "Year")) > 0) {
    # Identify all columns
    all_cols <- names(merged_by_name)
    grouping_cols <- c("Country Name", "Year")
    if ("Country Code" %in% all_cols) {
      grouping_cols <- c(grouping_cols, "Country Code")
    }
    
    # Identify medal columns (sum these)
    medal_cols <- c("gold", "silver", "bronze", "total")
    medal_cols <- medal_cols[medal_cols %in% all_cols]
    
    # Identify other columns to aggregate
    other_cols <- setdiff(all_cols, c(grouping_cols, medal_cols, "edition", "edition_id"))
    
    # Identify edition columns
    edition_cols <- c("edition", "edition_id")
    edition_cols <- edition_cols[edition_cols %in% all_cols]
    
    # Build aggregation list - do all aggregations in one step
    agg_cols <- c(medal_cols, other_cols, edition_cols)
    
    # Perform aggregation for all columns at once
    if (length(agg_cols) > 0) {
      # Aggregate medal columns by summing
      if (length(medal_cols) > 0) {
        medal_agg <- merged_by_name[, lapply(.SD, function(x) sum(x, na.rm = TRUE)), 
                                    .SDcols = medal_cols, 
                                    by = grouping_cols]
      } else {
        medal_agg <- unique(merged_by_name[, .SD, .SDcols = grouping_cols], by = grouping_cols)
      }
      
      # Aggregate other columns
      if (length(other_cols) > 0) {
        other_agg <- merged_by_name[, lapply(.SD, function(x) {
          if (is.numeric(x)) mean(x, na.rm = TRUE) else x[1]
        }), .SDcols = other_cols, by = grouping_cols]
      } else {
        other_agg <- unique(merged_by_name[, .SD, .SDcols = grouping_cols], by = grouping_cols)
      }
      
      # Aggregate edition columns (take first)
      if (length(edition_cols) > 0) {
        edition_agg <- merged_by_name[, lapply(.SD, function(x) x[1]), 
                                      .SDcols = edition_cols, 
                                      by = grouping_cols]
      } else {
        edition_agg <- unique(merged_by_name[, .SD, .SDcols = grouping_cols], by = grouping_cols)
      }
      
      # Merge all aggregations together - ensure medal columns are preserved
      if (length(medal_cols) > 0 && ncol(medal_agg) > length(grouping_cols)) {
        merged_by_name <- medal_agg[other_agg, on = grouping_cols]
      } else {
        merged_by_name <- other_agg
        # Add medal columns back if they were missing
        for (col in medal_cols) {
          if (!col %in% names(merged_by_name)) {
            merged_by_name[, (col) := NA_real_]
          }
        }
      }
      
      if (length(edition_cols) > 0 && ncol(edition_agg) > length(grouping_cols)) {
        merged_by_name <- merged_by_name[edition_agg, on = grouping_cols]
      } else {
        # Add edition columns back if they were missing
        for (col in edition_cols) {
          if (!col %in% names(merged_by_name)) {
            merged_by_name[, (col) := NA_character_]
          }
        }
      }
    } else {
      # If no columns to aggregate, just get unique combinations
      merged_by_name <- unique(merged_by_name, by = grouping_cols)
    }
  }
  
  return(merged_by_name)
}

