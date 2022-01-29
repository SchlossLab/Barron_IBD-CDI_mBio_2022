source("code/log_smk.R")
library(tidyverse)

read_bench <- function(filename) {
    read_tsv(filename) %>%
        mutate(
            groups_colname = str_replace(filename, "^benchmarks/runs/group-(.*)/run_ml.(.*)_(.*).txt", '\\1'),
            method = str_replace(filename, "^benchmarks/runs/group-(.*)/run_ml.(.*)_(.*).txt", "\\2"),
            seed = str_replace(filename, "^benchmarks/runs/group-(.*)/run_ml.(.*)_(.*).txt", "\\3")
        )
}

dat <- snakemake@input[["tsv"]] %>%
    lapply(read_bench) %>%
    bind_rows()
head(dat)
write_csv(dat, snakemake@output[['csv']])
