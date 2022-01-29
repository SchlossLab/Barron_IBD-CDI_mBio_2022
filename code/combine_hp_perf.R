source("code/log_smk.R")
library(dplyr)

models <- lapply(snakemake@input[["rds"]], function(x) readRDS(x))
hp_perf <- mikropml::combine_hp_performance(models) %>%
    mutate(method = snakemake@wildcards[["method"]],
           groups = snakemake@wildcards[["group_colname"]])
saveRDS(hp_perf, file = snakemake@output[["rds"]])
