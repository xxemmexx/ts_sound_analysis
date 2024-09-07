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
  ggtitle("Boxplots for habitat F3") +
  xlab("Survey station") + ylab("Acoustic diversity index (ADI)")


ggsave('results/boxplots_F3.png')  

