ML Results
================
2022-01-28

Machine learning algorithms used include: rf. Models were trained with
100 different random partitions of the data into training and testing
sets using 5-fold cross validation.

## Model Performance

<img src="figures/performance.png" width="60%" />

## Hyperparameter Performance

<img src="figures/group-cage/hp_performance_rf.png" width="60%" /><img src="figures/group-experiment/hp_performance_rf.png" width="60%" />

## Memory Usage & Runtime

<img src="figures/benchmarks.png" width="60%" />

Each model training run was given 12 cores for parallelization.
