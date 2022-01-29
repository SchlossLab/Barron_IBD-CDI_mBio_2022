ML Results
================
2022-01-29

Machine learning algorithms used include: rf. Models were trained with
10 different random partitions of the data into training and testing
sets using 5-fold cross validation.

## Model Performance

<img src="figures/performance.png" width="60%" />

## Hyperparameter Performance

<img src="figures/group-cage/trainfrac-0.8/hp_performance_rf.png" width="60%" /><img src="figures/group-cage/trainfrac-0.7/hp_performance_rf.png" width="60%" /><img src="figures/group-cage/trainfrac-0.65/hp_performance_rf.png" width="60%" /><img src="figures/group-experiment/trainfrac-0.8/hp_performance_rf.png" width="60%" /><img src="figures/group-experiment/trainfrac-0.7/hp_performance_rf.png" width="60%" /><img src="figures/group-experiment/trainfrac-0.65/hp_performance_rf.png" width="60%" />

## Memory Usage & Runtime

<img src="figures/benchmarks.png" width="60%" />

Each model training run was given 4 cores for parallelization.
