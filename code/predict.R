library(tidyverse)

model <- read_rds(snakemake@input[['model']])
test_dat <- read_csv(snakemake@input[['test']])

probs <- predict(model,
                 newdata = test_dat,
                 type="prob") %>%
    mutate(actual = test_dat$pos_cdiff_d1)


get_senspec <- function(dat){

  total <- dat %>%
    count(actual) %>%
    pivot_wider(names_from="actual", values_from="n")

  dat %>%
    arrange(desc(yes)) %>%
    mutate(is_pos = actual == "yes") %>%
    mutate(tp = cumsum(is_pos),
           fp = cumsum(!is_pos),
           sensitivity = tp / total$yes,
           fpr = fp / total$no) %>%
    mutate(specificity = 1- fpr,
           precision = tp / (tp + fp))
}
get_senspec(probs) %>%
    mutate(seed = snakemake@wildcards[['seed']],
           ml_method = snakemake@wildcards[['ml_method']],
           groups = snakemake@wildcards[['group_colname']],
           train_frac = snakemake@wildcards[['train_frac']],
           test_group = snakemake@wildcards[['test_group']]) %>%
    write_csv(snakemake@output[['csv']])
