# Requirements -----------------------------------------------------------------
require(tuneR)
require(soundecology)
require(seewave)

# Globals ----------------------------------------------------------------------
input_folder <- "data/interim"
output_folder <- "data/processed"

sound_files <- list.files(input_folder)

sample_file <- paste0(input_folder, '/', sound_files[[1]])

sample_sound_file <- tuneR::readWave(sample_file)

min_freq <- 0
max_freq <- min(10000, sample_sound_file@samp.rate / 2 - 1)

soundecology::acoustic_complexity(sample_sound_file, min_freq = min_freq, max_freq = max_freq)




file_name <- tools::file_path_sans_ext(basename(filepath))


aci_result <- tryCatch({
  aci <- acoustic_complexity(soundfile, min_freq = min_freq, max_freq = max_freq)
  cat("ACI calculated:\n")
  print(aci)
  aci$AciTotAll_left
}, error = function(e) {
  cat("Error calculating ACI for:", filepath, "\n", e$message, "\n")
  NA
})