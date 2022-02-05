get_sens_spec_lookup <- function(data){

  total <- count(data, observed) %>%
    pivot_wider(names_from="observed", values_from="n") %>%
    rename(srn=cancer,healthy=normal)

  data %>%
    arrange(desc(prob_srn)) %>%
    mutate(is_srn = observed == "cancer") %>%
    mutate(tp = cumsum(is_srn),
           fp = cumsum(!is_srn),
           sensitivity = tp / total$srn,
           fpr = fp / total$healthy) %>%
    mutate(specificity = 1- fpr) %>%
    select(sensitivity, specificity, fpr)

}

get_sensitivity <- function(x, lookup){

  if(x > max(lookup$specificity)){
    tibble(specificity = x, sensitivity=0)
  } else {
    lookup %>%
      filter(specificity - x > 0) %>%
      top_n(sensitivity, n=1) %>%
      summarize(specificity = x,
                sensitivity = unique(sensitivity))
  }

}

pool_sens_spec <- function(file_name, specificities){

  load(file_name)

  prob <- predict(model$trained_model, model$test_data, type="prob")

  prob_obs <- bind_cols(prob_srn = prob$cancer,
                        observed=model$test_data$dx)

  sens_spec_lookup <- get_sens_spec_lookup(prob_obs)

  map_dfr(specificities, get_sensitivity, lookup=sens_spec_lookup) %>%
    mutate(model = str_replace(file_name,
                               "data/(.*)_models/rf_model.\\d*.Rdata", "\\1"),
           seed = str_replace(file_name,
                              "data/.*_models/rf_model.(\\d*).Rdata", "\\1"),
    )

}

specificities <- seq(0, 1, 0.01)


rf_otu <- list.files(path="data/otu_models",
                     pattern="rf_model.*.Rdata",
                     full.names=TRUE) %>%
  map_dfr(pool_sens_spec, specificities)
rf_phylum <- list.files(path="data/phylum_models",
                     pattern="rf_model.*.Rdata",
                     full.names=TRUE) %>%
  map_dfr(pool_sens_spec, specificities)
rf <- bind_rows(rf_otu,rf_phylum)
write_csv(rf,"data/pat_rf.csv")

rf %>%
  group_by(model, specificity) %>%
  summarize(
    lquartile = quantile(sensitivity, prob=0.25),
    uquartile = quantile(sensitivity, prob=0.75),
    sensitivity=median(sensitivity),
    .groups="drop") %>%
  ggplot(aes(x=1-specificity, y=sensitivity, fill=model)) +
  geom_abline(intercept=0, slope=1, color="darkgray") +
  geom_ribbon(aes(ymin=lquartile, ymax=uquartile), alpha=0.2) +
  geom_step(aes(color=model)) +
  theme_classic() +
  theme(legend.position=c(0.8, 0.2)) +
  coord_equal()
