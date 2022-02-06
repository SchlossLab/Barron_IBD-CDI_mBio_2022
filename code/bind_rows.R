library(tidyverse)
snakemake@input[['csv']] %>%
    purrr::map_dfr(read_csv) %>%
    write_csv(snakemake@output[['csv']])
