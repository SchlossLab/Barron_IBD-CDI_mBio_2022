source("code/log_smk.R")
library(tidyverse)

perf_plot <- snakemake@input[["csv"]] %>%
  read_csv() %>%
    select(cv_metric_AUC, AUC, prAUC, groups, train_frac) %>%
    pivot_longer(c(cv_metric_AUC, AUC, prAUC), names_to = 'metric') %>%
    ggplot(aes(x = groups, y = value, color = metric)) +
    facet_wrap('train_frac') +
    geom_boxplot() +
    scale_color_brewer(palette = "Dark2") +
    theme_bw()
ggsave(snakemake@output[["plot"]], plot = perf_plot)
