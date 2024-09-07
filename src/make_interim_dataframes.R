# Requirements -----------------------------------------------------------------
require(dplyr)
require(readr)
require(stringr)
require(writexl)

# Requirements -----------------------------------------------------------------
interim_df <- tibble(loc_code = NA, year = NA, month = NA, day = NA, ACI = NA, ADI = NA)

csv_files <- list.files('data/processed', full.names = TRUE)

for(csv in csv_files) {
  test_file <- readr::read_csv2(csv)
  
  components <- stringr::str_split(test_file$File, pattern = "_")
  
  interim_df <- interim_df |>
    add_row(loc_code = components[[1]][[1]], 
            year = components[[1]][[2]], 
            month = components[[1]][[3]], 
            day = components[[1]][[4]], 
            ACI = test_file$ACI, ADI = test_file$ADI)
}


interim_df |>
  filter(!is.na(loc_code)) |>
  writexl::write_xlsx('data/interim/indices_df.xlsx')

