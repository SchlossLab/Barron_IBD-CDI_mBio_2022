source("code/log_smk.R")

doFuture::registerDoFuture()
future::plan(future::multicore, workers = snakemake@threads[[1]])

data_processed <- readRDS(snakemake@input[["rds"]])$dat_transformed
groups_vctr <- readxl::read_excel(snakemake@input[['meta']]) %>%
    pull(snakemake@wildcards[['group_colname']])

ml_results <- mikropml::run_ml(
  dataset = data_processed,
  method = snakemake@wildcards[["method"]],
  outcome_colname = snakemake@params[['outcome_colname']],
  find_feature_importance = FALSE,
  kfold = as.numeric(snakemake@params[['kfold']]),
  seed = as.numeric(snakemake@wildcards[["seed"]]),
  groups = groups_vctr
)

saveRDS(ml_results$trained_model, file = snakemake@output[["model"]])
readr::write_csv(ml_results$performance, snakemake@output[["perf"]])
