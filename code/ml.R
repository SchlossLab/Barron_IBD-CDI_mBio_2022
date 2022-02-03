source("code/log_smk.R")
library(dplyr)

doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads[[1]])
group_colname <- snakemake@wildcards[['group_colname']]
train_frac <- as.numeric(snakemake@wildcards[['train_frac']])

data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed
groups_vctr <- readxl::read_excel(snakemake@input[['meta']]) %>%
    pull(group_colname)

ml_results <- mikropml::run_ml(
  dataset = data_processed,
  method = snakemake@wildcards[["method"]],
  outcome_colname = snakemake@params[['outcome_colname']],
  find_feature_importance = TRUE,
  kfold = as.numeric(snakemake@params[['kfold']]),
  seed = as.numeric(snakemake@wildcards[["seed"]]),
  groups = groups_vctr,
  training_frac = train_frac
)

saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
readr::write_csv(ml_results$test_data, snakemake@output[['test']])
readr::write_csv(ml_results$performance %>%
                     mutate(groups = group_colname,
                            train_frac = train_frac),
                 snakemake@output[["perf"]])
readr::write_csv(ml_results$feature_importance %>%
                     mutate(groups = group_colname,
                            train_frac = train_frac),
                 snakemake@output[["feat"]])
