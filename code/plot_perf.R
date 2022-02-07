source("code/log_smk.R")
library(tidyverse)
perf_dat <- read_csv(snakemake@input[["csv"]])
perf_plot <- perf_dat %>%
    rename(`train AUROC` = cv_metric_AUC,
           `test AUROC` = AUC,
           `test AUPRC` = prAUC) %>%
    pivot_longer(c(`train AUROC`, `test AUROC`, `test AUPRC`),
                 names_to = 'metric') %>%
    mutate(metric = factor(metric,
                           levels = c("test AUPRC", "test AUROC", "train AUROC"))) %>%
    ggplot(aes(x = value, y = metric, color = test_group)) +
    geom_vline(xintercept = 0.5, linetype = 'dashed') +
    geom_boxplot() +
    xlim(0.5, 1) +
    labs(x='Performance', y='') +
    theme_bw() +
    theme(plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"))
ggsave(snakemake@output[["plot"]], plot = perf_plot,
       device = 'png', dpi=200, units = 'in', width = 4, height = 4)
