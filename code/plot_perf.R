source("code/log_smk.R")
library(tidyverse)

perf_plot <- snakemake@input[["csv"]] %>%
  read_csv() %>%
    select(cv_metric_AUC, AUC, prAUC, groups, train_frac) %>%
    rename(`train AUROC` = cv_metric_AUC,
           `test AUROC` = AUC,
           `test AUPRC` = prAUC) %>%
    pivot_longer(-c(groups, train_frac), names_to = 'metric') %>%
    mutate(metric = factor(metric,
                           levels = c("test AUPRC", "test AUROC", "train AUROC"))) %>%
    ggplot(aes(x = value, y = metric)) +
    geom_vline(xintercept = 0.5, linetype = 'dashed') +
    geom_boxplot() +
    xlim(0.5, 1) +
    labs(x='Performance', y='') +
    theme_bw() +
    theme(plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"))
ggsave(snakemake@output[["plot"]], plot = perf_plot,
       device = 'tiff', dpi=300, units = 'in', width = 4, height = 4)
