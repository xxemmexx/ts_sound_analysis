getDummyTibble <- function() {
  tibble::tibble(file = 'sample')
}

getFileInfoTibble <- function(aFilename) {
  
  filenameComponents <- aFilename |>
    tools::file_path_sans_ext() |>
    str_split(pattern = "_")
  
  tibble::tibble(file = aFilename,
                 location = filenameComponents[[1]][[1]],
                 year = as.numeric(filenameComponents[[1]][[2]]), 
                 month = as.numeric(filenameComponents[[1]][[3]]), 
                 day = as.numeric(filenameComponents[[1]][[4]])
                 )
}

getVectorOfStartTimes <- function(aPathToFile) {
  audio <- tuneR::readWave(aPathToFile, header=TRUE)
  audioDuration <- round(audio$samples / audio$sample.rate, 2)
  
  return((0:(floor(audioDuration/60)-1))*60)
}

exportAudioExtract <- function(fromTime, toTime, aPathToFile, outputDir = "data/interim/minute_files/") {
  
  tuneR::readWave(aPathToFile, 
                  from = fromTime, 
                  to = toTime,
                  units = "seconds"
  ) |>
    tuneR::writeWave(paste0(outputDir, 
                            paste0('audio_secs_', 
                                   fromTime, 
                                   '-', 
                                   toTime, 
                                   '.wav'))
    )
}

generateOneMinFilesFromLongRecording <- function(aPathToFile, outputFolder = "data/interim/minute_files/") {
  
  times <- dplyr::tibble(
    start_time = getVectorOfStartTimes(aPathToFile)
    ) |>
    dplyr::mutate(end_time = lead(start_time)) |>
    dplyr::mutate(end_time = ifelse(is.na(end_time), Inf, end_time))
  
  
  print(noquote(paste0("File ", basename(aPathToFile), ' is being split...')))
  
  with(future::plan(multisession, workers = 3), {
    
    furrr::future_map2(times$start_time, 
                       times$end_time, 
                       \(x, y) exportAudioExtract(x, y, aPathToFile = aPathToFile),
                       .progress = TRUE
                       )
  })
  
  print(noquote(paste0(nrow(times), ' one-minute files have been created')))
  
}

computeMedianAcousticIndices <- function(inputDir = "data/interim/minute_files/") {
  
  indices <- c("acoustic_complexity", "acoustic_diversity", "acoustic_evenness", "bioacoustic_index", "H")
  idx_values <- rep(NA, length(indices))
  names(idx_values) <- indices
  
  output_file <- "data/interim/{acoustic_index}_results.csv"
  
  for(index in indices) {
    
    acoustic_index <- index
    
    soundecology::multiple_sounds(directory = inputDir, 
                                  resultfile = str_glue(output_file), 
                                  soundindex = acoustic_index, 
                                  no_cores = -1)
    
    one_min_files_values <- readr::read_csv(str_glue(output_file), 
                                            show_col_types = FALSE
                                            ) 
    
    if(acoustic_index %in% c("acoustic_diversity", "acoustic_evenness")) {
      one_min_files_values <- one_min_files_values |>
        dplyr::filter(DB_THRESHOLD == 50)
    }
    
    summary <- one_min_files_values |>
      dplyr::summarise(median_value = median(LEFT_CHANNEL, na.rm = TRUE))
    
    idx_values[acoustic_index] <- summary$median_value |> round(digits = 2)
    
  }
  
  idx_values |> 
    tibble::as_tibble_row()
}

computeNDSI <- function(aPathToFile) {
  
  soundscape <- tuneR::readWave(aPathToFile) |>
    seewave::soundscapespec(plot = FALSE)
  
  ndsi_value_result <- tryCatch({
    
    seewave::NDSI(soundscape, max = TRUE)
    
  }, error = function(e) {
    
    NA
    
  })
  
  ndsi_value_result
}

computeMedianNDSI <- function(inputDir = "data/interim/minute_files/") {
  
  one_minute_files <- list.files(inputDir, full.names = TRUE)
  
  print(noquote(paste0("Computing NDSI of ", length(one_minute_files), " input files using 3 cores")))
  
  with(future::plan(multisession, workers = 3), {
    
    ndsi_values <- furrr::future_map_dbl(one_minute_files, 
                                         \(x) computeNDSI(x))
    
  })
  
  medianNDSI <- ndsi_values |>
    median(na.rm = TRUE) |>
    round(digits = 2)
  
  tibble::tibble(ndsi = medianNDSI)
    
}

generateSummaryFromRecordings <- function(inputDir) {
  
  recordings <- list.files(inputDir)
  summaryAllFiles <- getDummyTibble()
  
  for(filename in recordings) {
    generateOneMinFilesFromLongRecording(paste0(inputDir, filename))
    
    medianAcousticIndices <- computeMedianAcousticIndices()
    medianNDSI <- computeMedianNDSI()
    
    print(noquote(paste0("All indices have been computed for file ", filename)))
    
    summaryAcousticIndices <- filename |> 
      getFileInfoTibble() |>
      dplyr::bind_cols(medianAcousticIndices) |>
      dplyr::bind_cols(medianNDSI)
    
    summaryAllFiles <- summaryAllFiles |>
      dplyr::bind_rows(summaryAcousticIndices)
  }
  
  cleanUpInterimFiles()
  
  print(noquote("Done!"))
  
  summaryAllFiles |>
    dplyr::filter(file != 'sample') 
}

cleanUpInterimFiles <- function() {
  
  interim_one_min_files <- list.files('data/interim/minute_files',
                                      pattern = "\\.[Ww][Aa][Vv]$",
                                      full.names = TRUE)
  
  single_file_indices <- list.files('data/interim/',
                                    pattern = "\\.[c][s][v]$",
                                    full.names = TRUE)
  
  remInterim <- lapply(interim_one_min_files, file.remove) 
  remIndices <- lapply(single_file_indices, file.remove) 
  
  print(noquote("Intermediate outputs have been removed"))
}