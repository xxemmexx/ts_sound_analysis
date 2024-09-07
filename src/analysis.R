# Requirements -----------------------------------------------------------------
require(tuneR)
require(soundecology)
require(seewave)

# Globals ----------------------------------------------------------------------
input_folder <- "data/raw"
output_folder <- "data/processed"


audio_files <- list.files(input_folder, pattern = "\\.[Ww][Aa][Vv]$", full.names = TRUE)

analyze_and_save <- function(filepath, output_folder) {
  cat("Processing file:", filepath, "\n")
  
  soundfile <- tryCatch(readWave(filepath), error = function(e) e)
  if (inherits(soundfile, "error")) {
    cat("Error reading file:", filepath, "\n", soundfile$message, "\n")
    return(NULL)
  }
  
  file_name <- tools::file_path_sans_ext(basename(filepath))
  min_freq <- 0
  max_freq <- min(10000, soundfile@samp.rate / 2 - 1)
  
  aci_result <- tryCatch({
    aci <- acoustic_complexity(soundfile, min_freq = min_freq, max_freq = max_freq)
    cat("ACI calculated:\n")
    print(aci)
    aci$AciTotAll_left
  }, error = function(e) {
    cat("Error calculating ACI for:", filepath, "\n", e$message, "\n")
    NA
  })
  
  # ndsi_result <- tryCatch({
  #   cat("Calculating NDSI for:", filepath, "\n")
  #   spectrum <- spec(soundfile@left, f = soundfile@samp.rate, plot = FALSE)
  #   biophony_range <- which(spectrum$f >= 2000 & spectrum$f <= 8000)
  #   anthrophony_range <- which(spectrum$f >= 1000 & spectrum$f <= 2000)
  #   B <- mean(spectrum$amp[biophony_range])
  #   A <- mean(spectrum$amp[anthrophony_range])
  #   ndsi <- (B - A) / (B + A)
  #   cat("NDSI calculated:\n", ndsi, "\n")
  #   ndsi
  # }, error = function(e) {
  #   cat("Error calculating NDSI for:", filepath, "\n", e$message, "\n")
  #   "No anthropogenic sounds detected or other error."
  # })
  # 
  # bioacoustic_result <- tryCatch({
  #   bioacoustic <- bioacoustic_index(soundfile)
  #   cat("Bioacoustic Index calculated:\n")
  #   print(bioacoustic)
  #   bioacoustic$left_area
  # }, error = function(e) {
  #   cat("Error calculating Bioacoustic Index for:", filepath, "\n", e$message, "\n")
  #   NA
  # })
  
  adi_result <- tryCatch({
    adi <- acoustic_diversity(soundfile)
    cat("ADI calculated:\n")
    print(adi)
    adi$adi_left
  }, error = function(e) {
    cat("Error calculating ADI for:", filepath, "\n", e$message, "\n")
    NA
  })
  
  # aei_result <- tryCatch({
  #   aei <- acoustic_evenness(soundfile)
  #   cat("AEI calculated:\n")
  #   print(aei)
  #   aei$aei_left
  # }, error = function(e) {
  #   cat("Error calculating AEI for:", filepath, "\n", e$message, "\n")
  #   NA
  # })
  # 
  # results_text <- paste(
  #   "ACI: ", aci_result, "\n",
  #   "NDSI: ", ndsi_result, "\n",
  #   "Bioacoustic Index: ", bioacoustic_result, "\n",
  #   "ADI: ", adi_result, "\n",
  #   "AEI: ", aei_result, "\n",
  #   sep = ""
  # )
  
  results_text <- paste(
    "ACI: ", aci_result, "\n",
    "ADI: ", adi_result, "\n",
    sep = ""
  )
  
  results_df <- data.frame(
    File = file_name,
    ACI = aci_result,
    ADI = adi_result
  )
  
  # output_txt_path <- file.path(output_folder, paste0(file_name, "_indices.txt"))
  # write(results_text, file = output_txt_path)
  # cat("Results saved to:", output_txt_path, "\n")
  
  output_csv_path <- file.path(output_folder, paste0(file_name, "_indices.csv"))
  write.csv2(results_df, file = output_csv_path, row.names = FALSE)
  cat("Results successfully saved to:", output_csv_path, "\n")
}

for (file in audio_files) {
  analyze_and_save(file, output_folder)
}
cat("Processing completed.\n")


