# Deprecated Files

This directory contains deprecated code and documentation that has been superseded by the current pipeline.

## Contents

### Old Processing Scripts
- `02_process_rayyaan.R` - Original rayyaan processor (for old data format)
- `03_process_amaani.R` - Original amaani processor (for old data format)
- `04_load_ellie.R` - Original ellie loader (for old data format)
- `10_main.R` - Original main pipeline (for old data format)

### Old Standalone Scripts
- `dataimport.R` - Ad-hoc data import script
- `data_sorting.r` - Data sorting utilities
- `eda_olympic.R` - Exploratory data analysis
- `ellie.ipynb` - Jupyter notebook experiments
- `install.R` - Package installation script

### Old Documentation
- `README_v2.md` - Documentation for v2 transition
- `test_pipeline_v2.R` - Test script for v2 pipeline
- `ADAPTATION_SUMMARY.md` - Summary of v1→v2 changes
- `QUICK_REFERENCE.md` - Quick reference for v1 vs v2

## Current Pipeline

The current, active pipeline is located in `data_cleaning/` and includes:
- Enhanced 4-year averaging with lagged variables
- Support for fresh_data/ files
- Streamlined naming (no _v2 suffixes)
- Complete documentation in `data_cleaning/README.md`

## Migration Notes

If you need to use these old files:
1. The old data format is incompatible with current scripts
2. Function names have changed (no _v2 suffix)
3. Data paths have changed (data/ → fresh_data/)
4. Lagged variables feature not available in old version

## Date Deprecated
November 16, 2025
