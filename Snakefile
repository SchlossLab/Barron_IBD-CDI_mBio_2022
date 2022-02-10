configfile: 'config/config.yml'

outcome_colname = config['outcome_colname']
ml_methods = config['ml_methods']
kfold = config['kfold']
ncores = config['ncores']
nseeds = config['nseeds']

groups = config['groups']
test_groups = config['test_groups']
training_fracs = config['training_fracs']

start_seed = 100
seeds = range(start_seed, start_seed + nseeds)

rule targets:
    input:
        'docs/report.html',
        'docs/ml-sections.pdf'

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
        model="results/group-{group_colname}/trainfrac-{train_frac}/runs/{method}_testgroup-{test_group}_{seed}_model.Rds",
        test="results/group-{group_colname}/trainfrac-{train_frac}/runs/{method}_testgroup-{test_group}_{seed}_test-data.csv",
        perf="results/group-{group_colname}/trainfrac-{train_frac}/runs/{method}_testgroup-{test_group}_{seed}_performance.csv",
        feat="results/group-{group_colname}/trainfrac-{train_frac}/runs/{method}_testgroup-{test_group}_{seed}_feature-importance.csv"
    log:
        "log/group-{group_colname}/trainfrac-{train_frac}/runs/run_ml.{method}_testgroup-{test_group}_{seed}.txt"
    benchmark:
        "benchmarks/group-{group_colname}/trainfrac-{train_frac}/runs/run_ml.{method}_testgroup-{test_group}_{seed}.txt"
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
        csv="results/group-{group_colname}/trainfrac-{train_frac}/runs/{method}_testgroup-{test_group}_{seed}_sensspec.csv"
    script:
        'code/predict.R'

rule combine_sensspec:
    input:
        R='code/bind_rows.R',
        csv=expand("results/group-{group_colname}/trainfrac-{train_frac}/runs/{method}_testgroup-{test_group}_{seed}_sensspec.csv",
                   group_colname = groups, train_frac = training_fracs,
                   method = ml_methods, seed = seeds, test_group = test_groups)
    output:
        csv="results/sensspec.csv"
    script:
        'code/bind_rows.R'

rule combine_results:
    input:
        R="code/combine_results.R",
        csv=expand("results/group-{group_colname}/trainfrac-{train_frac}/runs/{method}_testgroup-{test_group}_{seed}_{{type}}.csv",
                    group_colname = groups, train_frac = training_fracs,
                    method = ml_methods, test_group = test_groups,
                    seed = seeds
                    )
    output:
        csv='results/{type}_results.csv'
    log:
        "log/combine_results_{type}.txt"
    script:
        "code/combine_results.R"

rule combine_hp_performance:
    input:
        R='code/combine_hp_perf.R',
        rds=expand('results/group-{{group_colname}}/trainfrac-{{train_frac}}/runs/{{method}}_testgroup-{{test_group}}_{seed}_model.Rds', seed=seeds)
    output:
        rds='results/group-{group_colname}/trainfrac-{train_frac}/hp_performance_results_{method}_testgroup-{test_group}.Rds'
    log:
        "log/group-{group_colname}/trainfrac-{train_frac}/combine_hp_perf_{method}_testgroup-{test_group}.txt"
    script:
        "code/combine_hp_perf.R"

rule combine_benchmarks:
    input:
        R='code/combine_benchmarks.R',
        tsv=expand(rules.run_ml.benchmark,
                   method = ml_methods,
                   seed = seeds,
                   group_colname = groups,
                   test_group = test_groups,
                   train_frac = training_fracs)
    output:
        csv='results/benchmarks_results.csv'
    log:
        'log/combine_benchmarks.txt'
    script:
        'code/combine_benchmarks.R'

rule plot_performance:
    input:
        R="code/plot_perf_box.R",
        fcns='code/plotting-functions.R',
        csv='results/performance_results.csv'
    output:
        plot='figures/performance_box.png'
    log:
        "log/plot_performance.txt"
    script:
        "code/plot_perf_box.R"

rule plot_roc_curves:
    input:
        R="code/plot_perf_curves.R",
        fcns='code/plotting-functions.R',
        csv=rules.combine_sensspec.output.csv
    output:
        plot="figures/ROC-PRC-curves.png"
    script:
        "code/plot_perf_curves.R"

rule plot_feature_importance:
    input:
        R='code/plot_feature-importance.R',
        fcns='code/plotting-functions.R',
        feat='results/feature-importance_results.csv',
        tax='data/processed/final.taxonomy.tsv'
    output:
        plot='figures/feature-importance.png',
        csv='results/top_20_features.csv'
    log: "log/plot_feature-importance.txt"
    script:
        'code/plot_feature-importance.R'

rule plot_hp_performance:
    input:
        R='code/plot_hp_perf.R',
        rds=rules.combine_hp_performance.output.rds,
    output:
        plot='figures/group-{group_colname}/trainfrac-{train_frac}/hp_performance_{method}_testgroup-{test_group}.png'
    log:
        'log/group-{group_colname}/trainfrac-{train_frac}/plot_hp_perf_{method}_testgroup-{test_group}.txt'
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
        Rmd='notebooks/report.Rmd',
        R='code/render.R',
        perf_plot=rules.plot_performance.output.plot,
        feat_plot=rules.plot_feature_importance.output.plot,
        bench_plot=rules.plot_benchmarks.output.plot,
        roc_plots=expand(rules.plot_roc_curves.output.plot,
                         method = ml_methods,
                         group_colname = groups,
                         train_frac = training_fracs)
    output:
        doc='docs/report.html'
    log:
        "log/render_report.txt"
    params:
        format='html_document',
        output_dir='docs/',
        nseeds=nseeds,
        ml_methods=ml_methods,
        ncores=ncores,
        kfold=kfold
    script:
        'code/render.R'

rule make_figure_5:
    input:
        R='code/make-figure-5.R',
        fcns='code/plotting-functions.R',
        figs=[rules.plot_performance.output,
              rules.plot_roc_curves.output,
              rules.plot_feature_importance.output]
    output:
        pdf='figures/Figure5.pdf'
    script:
        'code/make-figure-5.R'

rule render_writeup:
    input:
        Rmd='notebooks/ml-sections.Rmd',
        R='code/render.R',
        fig=rules.make_figure_5.output.pdf
    output:
        'docs/ml-sections.pdf'
    params:
        format='all',
        output_dir='docs/'
    script:
        'code/render.R'

rule clean:
    input:
        rules.render_report.output,
        rules.plot_performance.output.plot,
        rules.plot_benchmarks.output.plot,
        rules.plot_roc_curves.output.plot,
        rules.make_figure_5.output,
        rules.render_writeup.output
    shell:
        '''
        rm -rf {input}
        '''
