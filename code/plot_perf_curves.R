source("code/plotting-functions.R")

sens_dat <- read_csv(snakemake@input[["csv"]])

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

auc_plots <- plot_roc(calc_roc(sens_dat)) + plot_prc(calc_prc(sens_dat))

ggsave(
  plot = auc_plots, filename = snakemake@output[["plot"]],
  dpi = 200, units = "in", width = 6, height = 5
)
