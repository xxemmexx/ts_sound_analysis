The ts_sound_analysis reporsitory contains three basic steps necessary to read, process and visualise Acoustic Complexity Indices (ACI) and Acoustic Diversity Indices (ADI) from raw audio recording typically collected by volunteers at Terrasylvestris.

Audio recordings that serve as input to the routine should be placed in data/interim.

The scripts should then be run in the following order: 1) analysis.R, 2) make_interim_dataframes.R and finally 3) plot_it.R

We encourage inspection of intermediate results. However, once you are certain that the scripts operate in a well-orchestrated manner, you could, of course, write a script of your own where you then source these three scripts one after the other. 
Chaining these scripts will result in a fully-automated routine where the input are the recordings, and the single output thereof are boxplots displaying ACI and ADI values for specific field stations and years.
