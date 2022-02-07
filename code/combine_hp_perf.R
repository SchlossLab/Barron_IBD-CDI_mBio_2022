source("code/log_smk.R")

models <- lapply(snakemake@input[["rds"]], function(x) readRDS(x))
hp_perf <- mikropml::combine_hp_performance(models)
hp_perf$method <- snakemake@wildcards[["method"]]
hp_perf$groups <- snakemake@wildcards[["group_colname"]]
hp_perf$test_group <- snakemake@wildcards[['test_group']]
hp_perf$train_frac <- snakemake@wildcards[["train_frac"]]
saveRDS(hp_perf, file = snakemake@output[["rds"]])
