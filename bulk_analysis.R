# Requirements -----------------------------------------------------------------
require(tuneR)
require(soundecology)
require(dplyr)
require(stringr)

source('src/udf.R')

# Globals ----------------------------------------------------------------------

input_raw_recording <- "data/raw/recordings/"
output_filename <- "data/processed/acoustic_indices.csv"

# Analysis ---------------------------------------------------------------------

generateSummaryFromRecordings(input_raw_recording) |>
  readr::write_csv(output_filename)
 
print(noquote("Thx!"))
