source(here::here('code', 'log_smk.R'))
library(ggtext)
library(tidyverse)

alpha_level <- 0.05
feat_dat <- read_csv('results/feature-importance_results.csv') %>%
    rename(otu = names)
tax_dat <- schtools::read_tax('data/processed/final.taxonomy.tsv') %>%
    rename(otu = OTU) %>%
    mutate(label = str_replace(tax_otu_label, '(^\\w+) (.*)', '_\\1_ \\2'))

nseeds <- feat_dat %>% pull(seed) %>% unique() %>% length()
ngroups <- feat_dat %>% pull(test_group) %>% unique() %>% length()

signif_feats <- feat_dat %>%
    filter(pvalue < alpha_level) %>%
    group_by(otu, test_group) %>%
    summarize(frac_sig = n() / nseeds)# %>% filter(frac_sig > 0.4)

feats <- feat_dat %>%
    group_by(otu, test_group) %>%
    summarise(mean_auroc = mean(perf_metric),
              sd_auroc = sd(perf_metric),
              mean_diff = mean(perf_metric_diff),
              median_diff = median(perf_metric_diff),
              sd_diff = sd(perf_metric_diff),
              lowerq = quantile(perf_metric_diff)[2],
              upperq = quantile(perf_metric_diff)[4]) %>%
    inner_join(signif_feats, by = c('otu', 'test_group')) %>%
    left_join(tax_dat %>% select(otu, label), by = 'otu') %>%
    ungroup() %>%
    arrange(mean_diff)

top_20 <- feats %>%
    filter(frac_sig > 0.5, mean_diff > 0) %>%
    slice_max(n = 20, order_by = mean_diff) %>%
    pull(otu)

feat_imp_plot <- feats %>%
    filter(otu %in% top_20) %>%
    mutate(label = fct_reorder(as.factor(label), mean_diff),
           percent_models_signif = frac_sig * 100) %>%
    ggplot(aes(x = -mean_diff, y = label,
               color = percent_models_signif, shape = test_group)) +
    geom_vline(xintercept = 0, linetype = 'dashed') +
    geom_pointrange(aes(xmin = -mean_diff - sd_diff,
                        xmax = -mean_diff + sd_diff)) +
    facet_wrap('test_group', nrow = 1)+#, scales = 'free_y') +
    scale_color_continuous(type = 'viridis', name = '% models') +
    labs(y = '', x = 'Mean decrease in AUROC') +
    theme_bw() +
    theme(axis.text.y = element_markdown(),
          legend.position = 'bottom',
          legend.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
          plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"))

ggsave(filename = snakemake@output[['plot']], plot = feat_imp_plot,
       device = 'png', dpi = 200, units = 'in', width = 9, height = 5)
