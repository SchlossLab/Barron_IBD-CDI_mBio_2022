source('code/plotting-functions.R')

metadat <- readxl::read_excel('data/raw/ml_metadata.xlsx') %>%
    rename(sample = group)

# performance box
perf_box_plot <- read_csv('results/performance_results.csv') %>% plot_perf_box()

# ROC
sens_dat <- read_csv('results/sensspec.csv')
roc_plot <- sens_dat %>% calc_roc() %>% plot_roc()

# PRC
prc_plot <- sens_dat %>% calc_prc() %>% plot_prc()

# feature importance
feat_dat <- read_csv('results/feature-importance_results.csv')
tax_dat <- schtools::read_tax('data/processed/final.taxonomy.tsv')
top_feats <- get_top_feats(feat_dat, tax_dat, alpha_level = 0.05)
feat_imp_plot <- top_feats %>% plot_feat_imp()

# relative abundance
abs_abun_dat <- data.table::fread('data/raw/sample.final.shared') %>%
    rename(sample = Group) %>%
    right_join(metadat %>% select(sample, pos_cdiff_d1))
abs_abun_dat$total_counts <- rowSums(abs_abun_dat %>% select(starts_with('Otu')))
rel_abun_dat <- abs_abun_dat %>%
    pivot_longer(starts_with("Otu"), names_to = 'otu', values_to = 'count') %>%
    mutate(rel_abun = count / total_counts) %>%
    select(sample, pos_cdiff_d1, otu, rel_abun)
top_feats_rel_abun <- top_feats %>%
    select(otu, label) %>%
    left_join(rel_abun_dat, by = 'otu') %>%
    mutate(cdiff_d1_status = case_when(pos_cdiff_d1 == 'yes' ~ 'pos.',
                                       pos_cdiff_d1 == 'no' ~ 'neg.',
                                       TRUE ~ 'NA'))
smallest_non_zero <- top_feats_rel_abun %>% # find smallest non-zero value
    filter(rel_abun > 0) %>%
    slice_min(rel_abun) %>%
    pull(rel_abun)
rel_abun_plot <- top_feats_rel_abun %>%
    mutate(rel_abun = rel_abun + smallest_non_zero / 10) %>%
    plot_rel_abun() +
    theme(axis.text.y = element_blank())

# put it all together for Figure 5
performance <- perf_box_plot + roc_plot + prc_plot +
    plot_annotation(tag_levels = 'A')
features <- plot_grid(feat_imp_plot, rel_abun_plot,
                      rel_widths = c(1, 0.6),
                      align = 'h', axis = 'l', nrow = 1,
                      labels = c('D', 'E'),
                      label_fontfamily = "sans",
                      label_fontface = "plain",
                      label_size = 12)
fig5 <- plot_grid(performance, features,
                  rel_heights = c(0.4, 1), ncol = 1)
ggsave(plot = fig5, filename = 'figures/Figure5.pdf', dpi = 300,
       width = 174, height = 189, units = 'mm')