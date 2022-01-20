library(tidyverse)

metadata <- readxl::read_excel(snakemake@input[['meta']])
otudata <- data.table::fread(snakemake@input[['dat']])

dat <- inner_join(metadata,
                  otudata %>% rename(group = Group),
                  by = "group")

data.table::fwrite(dat %>% select(pos_cdiff_d1, starts_with('Otu')),
       file = snakemake@output[['dat']])

