configfile: 'config/config.yml'

outcome_colname = config['outcome_colname']
ml_methods = config['ml_methods']
kfold = config['kfold']
ncores = config['ncores']
nseeds = config['nseeds']

groups = config['groups']
training_fracs = config['training_fracs']

start_seed = 100
seeds = range(start_seed, start_seed + nseeds)

rule targets:
    input:
        'report.md',
        'docs/ml-sections.pdf',
        'docs/ml-sections.html'

rule join_metadata:
    input:
        R='code/join_metadata.R',
        meta='data/raw/ml_metadata.xlsx',
        dat='data/raw/sample.final.shared'
    output:
        dat='data/processed/otu_day0.csv'
    script:
        'code/join_metadata.R'

rule csv2tsv:
    input:
        csv='data/raw/final.taxonomy.csv'
    output:
        tsv='data/processed/final.taxonomy.tsv'
    shell:
        """
        R -e 'library(tidyverse)
              read_csv("{input.csv}") %>% write_tsv("{output.tsv}")
             '
        """

rule preprocess_data:
    input:
        R="code/preproc.R",
        csv=rules.join_metadata.output.dat
    output:
        rds='data/processed/dat_preproc.Rds'
    log:
        "log/preprocess_data.txt"
    benchmark:
        "benchmarks/preprocess_data.txt"
    params:
        outcome_colname=outcome_colname
    threads: ncores
    script:
        "code/preproc.R"

rule run_ml:
    input:
        R="code/ml.R",
        meta='data/raw/ml_metadata.xlsx',
        rds=rules.preprocess_data.output.rds
    output:
        model="results/runs/group-{group_colname}/trainfrac-{train_frac}/{method}_{seed}_model.Rds",
        test="results/runs/group-{group_colname}/trainfrac-{train_frac}/{method}_{seed}_test-data.csv",
        perf="results/runs/group-{group_colname}/trainfrac-{train_frac}/{method}_{seed}_performance.csv",
        feat="results/runs/group-{group_colname}/trainfrac-{train_frac}/{method}_{seed}_feature-importance.csv"
    log:
        "log/runs/group-{group_colname}/trainfrac-{train_frac}/run_ml.{method}_{seed}.txt"
    benchmark:
        "benchmarks/runs/group-{group_colname}/trainfrac-{train_frac}/run_ml.{method}_{seed}.txt"
    params:
        outcome_colname=outcome_colname,
        kfold=kfold
    threads: ncores
    script:
        "code/ml.R"

rule predict:
    input:
        R='code/predict.R',
        model=rules.run_ml.output.model,
        test=rules.run_ml.output.test
    output:
        csv="results/runs/group-{group_colname}/trainfrac-{train_frac}/{method}_{seed}_sensspec.csv"
    script:
        'code/predict.R'

rule combine_sensspec:
    input:
        R='code/bind_rows.R',
        csv=expand("results/runs/group-{{group_colname}}/trainfrac-{{train_frac}}/{{method}}_{seed}_sensspec.csv", seed = seeds)
    output:
        csv="results/group-{group_colname}/trainfrac-{train_frac}/{method}_sensspec.csv"
    script:
        'code/bind_rows.R'

rule combine_results:
    input:
        R="code/combine_results.R",
        csv=expand("results/runs/group-{group_colname}/trainfrac-{train_frac}/{method}_{seed}_{{type}}.csv",
                   method = ml_methods, seed = seeds, group_colname = groups,
                   train_frac = training_fracs)
    output:
        csv='results/{type}_results.csv'
    log:
        "log/combine_results_{type}.txt"
    script:
        "code/combine_results.R"

rule combine_hp_performance:
    input:
        R='code/combine_hp_perf.R',
        rds=expand('results/runs/group-{{group_colname}}/trainfrac-{{train_frac}}/{{method}}_{seed}_model.Rds', seed=seeds)
    output:
        rds='results/group-{group_colname}/trainfrac-{train_frac}/hp_performance_results_{method}.Rds'
    log:
        "log/group-{group_colname}/trainfrac-{train_frac}/combine_hp_perf_{method}.txt"
    script:
        "code/combine_hp_perf.R"

rule combine_benchmarks:
    input:
        R='code/combine_benchmarks.R',
        tsv=expand(rules.run_ml.benchmark,
                   method = ml_methods,
                   seed = seeds,
                   group_colname = groups,
                   train_frac = training_fracs)
    output:
        csv='results/benchmarks_results.csv'
    log:
        'log/combine_benchmarks.txt'
    script:
        'code/combine_benchmarks.R'

rule plot_performance:
    input:
        R="code/plot_perf.R",
        csv='results/performance_results.csv'
    output:
        plot='figures/performance_box.png'
    log:
        "log/plot_performance.txt"
    script:
        "code/plot_perf.R"

rule plot_roc_curves:
    input:
        R="code/plot_roc.R",
        csv=rules.combine_sensspec.output.csv
    output:
        plot="figures/group-{group_colname}_trainfrac-{train_frac}_{method}_ROC-curves.png"
    script:
        "code/plot_roc.R"

rule plot_feature_importance:
    input:
        R='code/plot_feature-importance.R',
        feat='results/feature-importance_results.csv',
        tax='data/processed/final.taxonomy.tsv'
    output:
        plot='figures/feature-importance.png'
    log: "log/plot_feature-importance.txt"
    script:
        'code/plot_feature-importance.R'

rule plot_hp_performance:
    input:
        R='code/plot_hp_perf.R',
        rds=rules.combine_hp_performance.output.rds,
    output:
        plot='figures/group-{group_colname}/trainfrac-{train_frac}/hp_performance_{method}.png'
    log:
        'log/group-{group_colname}/trainfrac-{train_frac}/plot_hp_perf_{method}.txt'
    script:
        'code/plot_hp_perf.R'

rule plot_benchmarks:
    input:
        R='code/plot_benchmarks.R',
        csv=rules.combine_benchmarks.output.csv
    output:
        plot='figures/benchmarks.png'
    log:
        'log/plot_benchmarks.txt'
    script:
        'code/plot_benchmarks.R'

rule render_report:
    input:
        Rmd='report.Rmd',
        R='code/render.R',
        perf_plot=rules.plot_performance.output.plot,
        feat_plot=rules.plot_feature_importance.output.plot,
        hp_plot=expand(rules.plot_hp_performance.output.plot,
                       method = ml_methods,
                       group_colname = groups,
                       train_frac = training_fracs),
        bench_plot=rules.plot_benchmarks.output.plot,
        roc_plots=expand(rules.plot_roc_curves.output.plot,
                         method = ml_methods,
                         group_colname = groups,
                         train_frac = training_fracs)
    output:
        doc='report.md'
    log:
        "log/render_report.txt"
    params:
        nseeds=nseeds,
        ml_methods=ml_methods,
        ncores=ncores,
        kfold=kfold
    script:
        'code/render.R'

rule render_writeup:
    input:
        Rmd='paper/ml-sections.Rmd'
    output:
        'docs/ml-sections.html',
        'docs/ml-sections.pdf'
    shell:
        """
        R -e 'rmarkdown::render("{input.Rmd}",
                                 output_format = "all",
                                 output_dir = "docs/"
                                 )'
        """


rule clean:
    input:
        rules.render_report.output,
        rules.plot_performance.output.plot,
        rules.plot_benchmarks.output.plot
    shell:
        '''
        rm -rf {input}
        '''
