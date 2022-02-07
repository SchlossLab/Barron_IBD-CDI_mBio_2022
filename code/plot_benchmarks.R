source("code/log_smk.R")
library(tidyverse)

dat <- read_csv(snakemake@input[['csv']],
                col_types = cols(
                  s = col_double(),
                  `h:m:s` = col_time(format = "%H:%M:%S"),
                  max_rss = col_double(),
                  max_vms = col_double(),
                  max_uss = col_double(),
                  max_pss = col_double(),
                  io_in = col_double(),
                  io_out = col_double(),
                  mean_load = col_double(),
                  cpu_time = col_double(),
                  method = col_character(),
                  seed = col_double(),
                  groups_colanme = col_character()
                )) %>%
  mutate(runtime_mins = s / 60,
         memory_gb = max_rss / 1024) %>%
  pivot_longer(c(runtime_mins, memory_gb), names_to = 'metric')

bench_plot <- dat %>%
  ggplot(aes(groups_colname, value, color = test_group)) +
  geom_boxplot() +
  facet_wrap(metric ~ ., scales = 'free', ncol = 1) +
  theme_classic() +
  labs(y = "", x = "") +
  coord_flip()
ggsave(snakemake@output[["plot"]], plot = bench_plot,
       height = 4, width = 4, units = 'in')
