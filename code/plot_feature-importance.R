source(here::here("code", "log_smk.R"))
source(here::here("code", "plotting-functions.R"))

feat_dat <- read_csv(snakemake@input[['feat']])
tax_dat <- schtools::read_tax(snakemake@input[['tax']])

top_feats <- get_top_feats(feat_dat, tax_dat, alpha_level = 0.05)
feat_imp_plot <- top_feats %>%
  plot_feat_imp()

ggsave(
  filename = snakemake@output[["plot"]], plot = feat_imp_plot,
  device = "png", dpi = 300, units = "in", width = 9, height = 5
)
top_feats %>% write_csv(snakemake@output[['csv']])
