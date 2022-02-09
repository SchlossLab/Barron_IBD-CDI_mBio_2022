source("code/log_smk.R")
rmarkdown::render(snakemake@input[["Rmd"]],
  output_format = snakemake@params[["format"]],
  output_dir = snakemake@params[["output_dir"]]
)
