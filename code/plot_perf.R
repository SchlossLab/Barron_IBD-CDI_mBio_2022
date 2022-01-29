source("code/log_smk.R")
library(tidyverse)

perf_plot <- snakemake@input[["csv"]] %>%
  read_csv() %>%
    select(cv_metric_AUC, AUC, prAUC, groups) %>%
    pivot_longer(c(-groups), names_to = 'metric') %>%
    ggplot(aes(x = train_frac, y = value, color = metric)) +
    facet('groups') +
    geom_boxplot() +
    scale_color_brewer(palette = "Dark2") +
    theme_bw()
ggsave(snakemake@output[["plot"]], plot = perf_plot)
