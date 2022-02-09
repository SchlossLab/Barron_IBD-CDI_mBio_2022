source(here::here('code', 'log_smk.R'))
source(here::here('code', 'plotting-functions.R'))

feat_dat <- read_csv('results/feature-importance_results.csv')
tax_dat <- schtools::read_tax('data/processed/final.taxonomy.tsv')

feat_imp_plot <- get_top_feats(feat_dat, tax_dat, alpha_level = 0.05) %>%
    plot_feat_imp()

ggsave(filename = snakemake@output[['plot']], plot = feat_imp_plot,
       device = 'png', dpi = 300, units = 'in', width = 9, height = 5)
