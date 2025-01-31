require(readxl)
require(ggplot2)
require(dplyr)
require(stringr)

indices_df <- readxl::read_xlsx('data/interim/indices_df.xlsx')

indices_df |>
  group_by(year) |>
  summarise(n())

indices_df |>
  mutate(location = stringr::str_sub(loc_code, start = 2),
         index = 1) |>
  ggplot(aes(x = location, y = ADI, color = year)) +
  geom_boxplot() +
  ggtitle(paste("Boxplots for habitat", stringr::str_sub(indices_df$loc_code, end = 2))) +
  xlab("Survey station") + ylab("Acoustic diversity index (ADI)")

ggsave('results/boxplot_ADI.png')  

indices_df |>
  mutate(location = stringr::str_sub(loc_code, start = 2),
         index = 1) |>
  ggplot(aes(x = location, y = ACI, color = year)) +
  geom_boxplot() +
  ggtitle(paste("Boxplots for habitat", stringr::str_sub(indices_df$loc_code, end = 2))) +
  xlab("Survey station") + ylab("Acoustic complexity index (ACI)")


ggsave('results/boxplot_ACI.png')  

