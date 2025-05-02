# Requirements -----------------------------------------------------------------
require(tuneR)
require(soundecology)
require(seewave)
require(tidyr)
require(ggplot2)
require(dplyr)
require(rgl)
require(purrr)
require(furrr)
require(future)

# Parallelisation --------------------------------------------------------------

input_folder <- "data/raw/recordings/"
output_folder <- "data/processed"

sound_files <- list.files(input_folder)

sample_file <- paste0(input_folder, '/', sound_files[[1]])

#---


times <- dplyr::tibble(
  start_time = getVectorOfStartTimes(sample_file)
) |>
  dplyr::mutate(end_time = lead(start_time)) |>
  dplyr::mutate(end_time = ifelse(is.na(end_time), Inf, end_time))

totalFiles <- nrow(times)



sample_file <- list.files(input_folder, full.names = TRUE)[[1]]


system.time(
purrr::map2(times$start_time, times$end_time, \(x, y) exportAudioExtract(x, y, aPathToFile = sample_file))
)


system.time(
with(future::plan(multisession, workers = 3), {
  furrr::future_map2(times$start_time, times$end_time, \(x, y) exportAudioExtract(x, y, aPathToFile = sample_file))
})
)

one_minute_file <- list.files('data/interim/minute_files', full.names = TRUE)[[1]]

audio_file <- tuneR::readWave(one_minute_file)

testAR <- seewave::AR('data/interim/minute_files/', datatype="files")

system.time(
testVec <- purrr::map_dbl(one_minute_files, \(x) computeNDSI(x))
)

testVec |> median(na.rm = TRUE)

system.time(
  with(future::plan(multisession, workers = 3), {
    testVecFurrr <- furrr::future_map_dbl(one_minute_files, \(x) computeNDSI(x))
  })
)


# Acoustic indices -------------------------------------------------------------
input_folder <- "data/raw/recordings/"
output_folder <- "data/processed"

sound_files <- list.files(input_folder)

sample_file <- paste0(input_folder, '/', sound_files[[1]])

sample_one_min_sound_file <- tuneR::readWave(sample_file, 
                                     from = 60, 
                                     to = 120, 
                                     units = "seconds"
                                     )






bands <- meanspec(sample_one_min_sound_file, f=8000, plot=FALSE) |>
  seewave::fbands()

soundscapespec(sample_one_min_sound_file, plot=TRUE, col="darkgreen")

spectro3D(sample_one_min_sound_file, norm = TRUE)

# Spectrogramme ----------------------------------------------------------------
input_folder <- "data/raw/recordings/"
output_folder <- "data/processed"

sound_files <- list.files(input_folder)

sample_file <- paste0(input_folder, '/', sound_files[[1]])

sample_one_min_sound_file <- tuneR::readWave(sample_file, 
                                             from = 60, 
                                             to = 100, 
                                             units = "seconds"
                                             )


v <- ggspectro(sample_one_min_sound_file) +
  geom_tile(aes(fill = amplitude)) + 
  stat_contour()

v

sample_sound_down <- tuneR::downsample(sample_sound_file, 10000)

win_len <- 0.005 * sample_sound_down@samp.rate
hop_len <- 0.002 * sample_sound_down@samp.rate
overlap <- ((win_len - hop_len) / win_len) * 100

spectrogramme <- seewave::spectro(sample_sound_down, 
                                  wl = win_len,
                                  ovlp = overlap,
                                  fastdisp = TRUE,
                                  plot = F)


# set the colnames and rownames
colnames(spectrogramme$amp) <- spectrogramme$time
rownames(spectrogramme$amp) <- spectrogramme$freq

spect_df <-
  spectrogramme$amp |>
  # coerce the row names to a column
  as_tibble(rownames = "freq") |>
  # pivot to long format
  pivot_longer(
    # all columns except freq
    -freq, 
    names_to = "time", 
    values_to = "amp"
  ) |>
  # since they were names before,
  # freq and time need conversion to numeric
  mutate(
    freq = as.numeric(freq),
    time = as.numeric(time)
  )


dyn = -50
spect_df_floor <- spect_df |> 
  mutate(
    amp_floor = case_when(
      amp < dyn ~ dyn,
      TRUE ~ amp  
    )
  )

extract_spec <- spect_df_floor |>
  slice(1:80000)

my_plot <- extract_spec |> 
  ggplot(aes(time, freq)) +
  geom_raster(aes(fill = amp_floor)) +
  guides(fill = "none") +
  labs(
    x = "time (s)",
    y = "frequency (kHz)",
    title = "spectrogram raster plot"
  )

ggsave("my_plot.jpg", my_plot)


file_name <- tools::file_path_sans_ext(basename(sound_files[[3]]))

filenameComponents <- stringr::str_split(file_name, pattern = "_")

sound_files[[3]] |>
  tools::file_path_sans_ext() |>
  stringr::str_split(pattern = "_")



