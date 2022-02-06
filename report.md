Exploratory Report
================
2022-02-05

Machine learning algorithms used include: rf. Models were trained with
100 different random partitions of the data into training and testing
sets using 5-fold cross validation.

## Model Performance

<img src="figures/performance_box.png" width="50%" />
<img src="figures/group-experiment_trainfrac-0.65_rf_ROC-curves.png" width="80%" />

## Hyperparameter Performance

<img src="figures/group-experiment/trainfrac-0.65/hp_performance_rf.png" width="50%" />

## Memory Usage & Runtime

<img src="figures/benchmarks.png" width="50%" />

Each model training run was given 12 cores for parallelization.

## Feature Importance

<img src="figures/plot-feats-histograms-1.png" width="50%" /><img src="figures/plot-feats-histograms-2.png" width="50%" /><img src="figures/plot-feats-histograms-3.png" width="50%" />

### Performance differences

<img src="figures/feature-importance.png" width="50%" />
