source("code/log_smk.R")
library(tidyverse)

pattern <- "^benchmarks/group-(.*)/trainfrac-(.*)/runs/run_ml.(.*)_testgroup-(.*)_(.*).txt"
read_bench <- function(filename) {
    read_tsv(filename) %>%
        mutate(
            groups_colname = str_replace(filename, pattern, '\\1'),
            train_frac = str_replace(filename, pattern, "\\2"),
            method = str_replace(filename, pattern, "\\3"),
            test_group = str_replace(filename, pattern, '\\4'),
            seed = str_replace(filename, pattern, "\\5")
        )
}

dat <- snakemake@input[["tsv"]] %>%
    lapply(read_bench) %>%
    bind_rows()
head(dat)
write_csv(dat, snakemake@output[['csv']])
