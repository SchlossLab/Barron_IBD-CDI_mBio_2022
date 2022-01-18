library(data.table)
library(here)
library(readxl)
library(tidyverse)

metadata <- read_excel(here('data', 'raw', 'ml_metadata.xlsx'))
otudata <- fread(here('data', 'raw', 'sample.final.shared'))

dat <- inner_join(metadata %>% select(pos_cdiff_d1, group),
                  otudata %>% rename(group = Group) %>% select(-label, numOtus),
                  by = "group")

fwrite(dat %>% select(pos_cdiff_d1, starts_with('Otu')),
       file = here('data', 'processed', 'otu_d0.csv'))

saveRDS(dat %>% pull(cage),
        file = here('data', 'processed', 'cages.Rds'))
