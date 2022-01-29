source("code/log_smk.R")
library(tidyverse)

read_bench <- function(filename) {
    read_tsv(filename) %>%
        mutate(
            groups_colname = str_replace(filename, "^benchmarks/runs/group-(.*)/trainfrac-(.*)/run_ml.(.*)_(.*).txt", '\\1'),
            train_frac = str_replace(filename, "^benchmarks/runs/group-(.*)/trainfrac-(.*)/run_ml.(.*)_(.*).txt", "\\2"),
            method = str_replace(filename, "^benchmarks/runs/group-(.*)/trainfrac-(.*)/run_ml.(.*)_(.*).txt", "\\3"),
            seed = str_replace(filename, "^benchmarks/runs/group-(.*)/trainfrac-(.*)/run_ml.(.*)_(.*).txt", "\\4")
        )
}

dat <- snakemake@input[["tsv"]] %>%
    lapply(read_bench) %>%
    bind_rows()
head(dat)
write_csv(dat, snakemake@output[['csv']])
