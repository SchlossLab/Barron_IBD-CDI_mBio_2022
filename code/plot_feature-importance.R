source(here::here('code', 'log_smk.R'))
library(here)
library(tidyverse)

alpha_level <- 0.05
feat_dat <- read_csv(here('results', 'feature-importance_results.csv')) %>%
    rename(feature = names)

nseeds <- feat_dat %>% pull(seed) %>% unique() %>% length()

signif_feats <- feat_dat %>%
    filter(pvalue < alpha_level) %>%
    group_by(feature) %>%
    summarize(frac_sig = n() / nseeds) %>%
    filter(frac_sig > 0.5)

feats <- feat_dat %>%
    filter(feature %in% signif_feats$feature) %>%
    group_by(feature) %>%
    summarise(mean_auroc = mean(perf_metric),
              sd_auroc = sd(perf_metric),
              mean_diff = mean(perf_metric_diff),
              median_diff = median(perf_metric_diff),
              sd_diff = sd(perf_metric_diff),
              lowerq = quantile(perf_metric_diff)[2],
              upperq = quantile(perf_metric_diff)[4]) %>%
    filter(mean_diff < 0) %>%
    inner_join(signif_feats, by = 'feature') %>%
    arrange(mean_diff)

top_feats <- feats %>%
    slice_min(n = 20, order_by = mean_diff) %>%
    mutate(feature = fct_reorder(as.factor(feature), -mean_diff))

feat_imp_plot <- top_feats %>%
    mutate(percent_models_signif = frac_sig * 100) %>%
    ggplot(aes(x = mean_diff, y = feature, color = percent_models_signif)) +
    geom_vline(xintercept = 0, linetype = 'dashed') +
    geom_pointrange(aes(xmin = mean_diff - sd_diff, xmax = mean_diff + sd_diff)) +
    scale_color_continuous(type = 'viridis', name = '% models') +
    xlim(-0.01, 0.005) +
    labs(y = '', x = 'Mean difference in AUROC') +
    theme_bw()

ggsave(filename = here('figures', 'feature-importance.png'),
       plot = feat_imp_plot)
