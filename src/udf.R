getDummyTibble <- function() {
  tibble::tibble(file = 'sample')
}

getFileInfoTibble <- function(aFilename) {
  filenameComponents <- stringr::str_split(aFilename, pattern = "_")
  
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

generateOneMinFilesFromLongRecording <- function(aPathToFile, outputFolder = "data/interim/minute_files/") {
  
  print(noquote(paste0("Inferring number of one-minute files in ", aPathToFile)))
  
  times <- dplyr::tibble(
    start_time = getVectorOfStartTimes(aPathToFile)
    ) |>
    dplyr::mutate(end_time = lead(start_time)) |>
    dplyr::mutate(end_time = ifelse(is.na(end_time), Inf, end_time))
  
  totalFiles <- nrow(times)
  
  for(i in 1:totalFiles) {
    
    print(noquote(paste0("Exporting one-minute file: ", i, "/", totalFiles)))
    
    tuneR::readWave(aPathToFile, 
                    from = times$start_time[[i]], 
                    to = times$end_time[[i]],
                    units = "seconds"
    ) |>
      tuneR::writeWave(paste0(outputFolder, 
                              paste0('audio_secs_', 
                                     times$start_time[[i]], 
                                     '-', 
                                     times$end_time[[i]], 
                                     '.wav'))
      )
  }
  
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
    
    idx_values[acoustic_index] <- summary$median_value
    
  }
  
  print(noquote("Done!"))
  
  idx_values |> 
    tibble::as_tibble_row()
}

generateSummaryFromRecordings <- function(inputDir) {
  
  recordings <- list.files(inputDir)
  summaryAllFiles <- getDummyTibble()
  
  for(filename in recordings) {
    generateOneMinFilesFromLongRecording(paste0(inputDir, filename))
    
    medianAcousticIndices <- computeMedianAcousticIndices()
    
    summaryAcousticIndices <- filename |> 
      getFileInfoTibble() |>
      dplyr::bind_cols(medianAcousticIndices)
    
    summaryAllFiles <- summaryAllFiles |>
      dplyr::bind_rows(summaryAcousticIndices)
  }
  
  summaryAllFiles |>
    dplyr::filter(file != 'sample') 
}