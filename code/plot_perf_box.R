source("code/log_smk.R")
source("code/plotting-functions.R")

perf_plot <- read_csv(snakemake@input[["csv"]]) %>% plot_perf_box()

ggsave(snakemake@output[["plot"]],
  plot = perf_plot,
  device = "png", dpi = 200, units = "in", width = 4, height = 4
)
