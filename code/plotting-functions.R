library(cowplot)
library(ggtext)
library(patchwork)
library(tidyverse)

blues <- RColorBrewer::brewer.pal(name = "Blues", n = 9)
greens <- RColorBrewer::brewer.pal(name = "Greens", n = 9)

calc_roc <- function(sens_dat) {
  sens_dat %>%
    mutate(specificity = round(specificity, 2)) %>%
    group_by(specificity) %>%
    summarise(
      mean_sensitivity = mean(sensitivity),
      sd_sensitivity = sd(sensitivity)
    ) %>%
    mutate(
      upper_sens = mean_sensitivity + sd_sensitivity,
      lower_sens = mean_sensitivity - sd_sensitivity
    ) %>%
    mutate(
      upper_sens = case_when(
        upper_sens > 1 ~ 1,
        TRUE ~ upper_sens
      ),
      lower_sens = case_when(
        upper_sens < 0 ~ 0,
        TRUE ~ lower_sens
      )
    )
}

calc_prc <- function(sens_dat) {
  sens_dat %>%
    rename(recall = sensitivity) %>%
    mutate(recall = round(recall, 2)) %>%
    group_by(recall) %>%
    summarise(
      mean_precision = mean(precision),
      sd_precision = sd(precision)
    ) %>%
    mutate(
      upper = mean_precision + sd_precision,
      lower = mean_precision - sd_precision
    ) %>%
    mutate(
      upper = case_when(
        upper > 1 ~ 1,
        TRUE ~ upper
      ),
      lower = case_when(
        upper < 0 ~ 0,
        TRUE ~ lower
      )
    )
}

# sensitivity vs specificity
plot_roc <- function(roc_dat) {
  roc_dat %>%
    ggplot(aes(
      x = specificity, y = mean_sensitivity,
      ymin = lower_sens, ymax = upper_sens
    )) +
    geom_ribbon(fill = blues[3]) +
    geom_line(color = blues[9]) +
    coord_equal() +
    geom_abline(intercept = 1, slope = 1, linetype = "dashed", color = "grey50") +
    scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
    scale_x_reverse(expand = c(0, 0), limits = c(1.01, -0.01)) +
    labs(x = "Specificity", y = "Sensitivity") +
    theme_bw() +
    theme(
      plot.margin = unit(x = c(0, 8, 0, 0), units = "pt"),
      legend.title = element_blank()
    )
}

# precision vs recall
plot_prc <- function(prc_dat, baseline_precision) {
  prc_dat %>%
    ggplot(aes(
      x = recall, y = mean_precision,
      ymin = lower, ymax = upper
    )) +
    geom_ribbon(fill = greens[3]) +
    geom_line(color = greens[9]) +
    coord_equal() +
    geom_hline(yintercept = baseline_precision, linetype = "dashed", color = "grey50") +
    scale_y_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
    scale_x_continuous(expand = c(0, 0), limits = c(-0.01, 1.01)) +
    labs(x = "Recall", y = "Precision") +
    theme_bw() +
    theme(
      plot.margin = unit(x = c(0, 5, 0, 0), units = "pt"),
      legend.position = "none"
    )
}

plot_perf_box <- function(perf_dat, baseline_prc = 0.3387097) {
  perf_dat <- perf_dat %>%
    rename(
      `train AUROC` = cv_metric_AUC,
      `test AUROC` = AUC,
      `test AUPRC` = prAUC
    ) %>%
    pivot_longer(c(`train AUROC`, `test AUROC`, `test AUPRC`),
      names_to = "metric"
    ) %>%
    mutate(metric = factor(metric,
      levels = c("test AUPRC", "test AUROC", "train AUROC")
    )) %>%
    mutate(metric_short = factor(case_when(str_detect(metric, 'ROC') ~ 'ROC',
                                    str_detect(metric, 'PRC') ~ 'PRC',
                                    TRUE ~ 'NA'), levels = c('ROC', 'PRC'))
           )
  xlims <- c(min(baseline_prc, 0.5), 1)
  roc <- perf_dat %>% filter(str_detect(metric, 'ROC')) %>%
    ggplot(aes(x = value, y = metric)) +
    geom_boxplot() +
    geom_vline(aes(xintercept = 0.5),
               linetype = "dashed", color = "grey50") +
    xlim(xlims) +
    theme_bw() +
    theme(
      plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_blank()
    )
  prc <- perf_dat %>% filter(str_detect(metric, 'PRC')) %>%
    ggplot(aes(x = value, y = metric)) +
    geom_boxplot() +
    geom_vline(aes(xintercept = baseline_prc),
               linetype = "dashed", color = "grey50") +
    xlim(xlims) +
    labs(x = "Performance", y = "") +
    theme_bw() +
    theme(
      plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
      axis.title.y = element_blank()
    )
  plot_grid(roc, prc, axis = 'bottom', align = 'hv', nrow = 2,
            rel_heights = c(1, 0.5))
}

get_top_feats <- function(test_dat, tax_dat, alpha_level = 0.05) {
  feat_dat <- feat_dat %>%
    rename(otu = names)
  tax_dat <- tax_dat %>%
    rename(otu = OTU) %>%
    mutate(label = str_replace(tax_otu_label, "(^\\w+) (.*)", "_\\1_ \\2"))

  nseeds <- feat_dat %>%
    pull(seed) %>%
    unique() %>%
    length()
  ngroups <- feat_dat %>%
    pull(test_group) %>%
    unique() %>%
    length()

  signif_feats <- feat_dat %>%
    filter(pvalue < alpha_level) %>%
    group_by(otu) %>%
    summarize(frac_sig = n() / (nseeds * ngroups))

  feats <- feat_dat %>%
    group_by(otu) %>%
    summarise(
      mean_auroc = mean(perf_metric),
      sd_auroc = sd(perf_metric),
      mean_diff = mean(perf_metric_diff),
      median_diff = median(perf_metric_diff),
      sd_diff = sd(perf_metric_diff),
      lowerq = quantile(perf_metric_diff)[2],
      upperq = quantile(perf_metric_diff)[4]
    ) %>%
    inner_join(signif_feats, by = c("otu")) %>%
    left_join(tax_dat %>% select(otu, label), by = "otu") %>%
    ungroup() %>%
    arrange(mean_diff)

  top_20 <- feats %>%
    filter(mean_diff > 0) %>%
    slice_max(n = 20, order_by = mean_diff) %>%
    pull(otu)

  return(feats %>%
    filter(otu %in% top_20) %>%
    mutate(
      label = fct_reorder(as.factor(label), mean_diff),
      percent_models_signif = frac_sig * 100
    ))
}

plot_feat_imp <- function(top_feats) {
  top_feats %>%
    ggplot(aes(
      x = -mean_diff, y = label,
      color = percent_models_signif
    )) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_pointrange(aes(
      xmin = -mean_diff - sd_diff,
      xmax = -mean_diff + sd_diff
    )) +
    scale_color_continuous(type = "viridis", name = "% models") +
    labs(y = "", x = "Mean decrease in AUROC") +
    theme_bw() +
    theme(
      axis.text.y = element_markdown(),
      axis.title.y = element_blank(),
      legend.position = "bottom",
      legend.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
      plot.margin = unit(x = c(17, 8, 0, 2), units = "pt")
    )
}

plot_rel_abun <- function(rel_abun_dat) {
  rel_abun_dat %>%
    ggplot(aes(rel_abun, label, color = cdiff_d1_status)) +
    geom_boxplot() +
    scale_x_log10() +
    scale_color_brewer(palette = "Set1") +
    labs(x = "log10 Relative Abundance", y = "") +
    guides(color = guide_legend(title = "Day 1 _C. difficile_")) +
    theme_bw() +
    theme() +
    theme(
      axis.text.y = element_markdown(),
      axis.title.y = element_blank(),
      legend.title = element_markdown(),
      legend.position = "bottom",
      legend.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
      plot.margin = unit(x = c(17, 5, 0, 0), units = "pt")
    )
}
