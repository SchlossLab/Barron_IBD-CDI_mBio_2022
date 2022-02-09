source("code/plotting-functions.R")

sens_dat <- read_csv(snakemake@input[["csv"]])
metadat <- readxl::read_excel("data/raw/ml_metadata.xlsx") %>%
  rename(sample = group)

auroc_step <- sens_dat %>%
  filter(seed == 100) %>%
  ggplot(aes(x = fpr, y = sensitivity, color = test_group)) +
  geom_step() +
  theme_bw() +
  labs(
    x = "False Positive Rate",
    y = "True Positive Rate"
  ) +
  geom_abline(intercept = 0, lty = "dashed", color = "grey50") +
  # scale_color_grey() +
  theme(legend.position = "none")

cdiff_tally <- metadat %>% group_by(pos_cdiff_d1) %>% tally()
npos <- cdiff_tally %>% filter(pos_cdiff_d1 == 'yes') %>% pull(n)
ntot <- cdiff_tally %>% pull(n) %>% sum()
baseline_prec <- npos / ntot
prc_plot <- sens_dat %>%
  calc_prc() %>%
  plot_prc(baseline_prec = baseline_prec)

auc_plots <- plot_roc(calc_roc(sens_dat)) + prc_plot
ggsave(
  plot = auc_plots, filename = snakemake@output[["plot"]],
  dpi = 200, units = "in", width = 6, height = 5
)
