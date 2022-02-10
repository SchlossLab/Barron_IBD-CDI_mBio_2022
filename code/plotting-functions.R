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
      plot.margin = unit(x = c(2, 8, 0, 0), units = "pt"),
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
      plot.margin = unit(x = c(2, 5, 0, 0), units = "pt"),
      legend.position = "none"
    )
}

plot_perf_box <- function(perf_dat, baseline_prc = 0.3387097) {
  perf_dat_long <- perf_dat %>%
    rename(
      `training AUROC` = cv_metric_AUC,
      `testing AUROC` = AUC,
      `testing AUPRC` = prAUC
    ) %>%
    pivot_longer(c(`training AUROC`, `testing AUROC`, `testing AUPRC`),
      names_to = "metric"
    ) %>%
    mutate(metric = factor(metric,
      levels = c("testing AUPRC", "testing AUROC", "training AUROC")
    )) %>%
    mutate(metric_short = factor(case_when(str_detect(metric, 'ROC') ~ 'ROC',
                                    str_detect(metric, 'PRC') ~ 'PRC',
                                    TRUE ~ 'NA'), levels = c('ROC', 'PRC'))
           )
  xlims <- c(min(baseline_prc, 0.5), 1)
  roc <- perf_dat_long %>% filter(str_detect(metric, 'ROC')) %>%
    ggplot(aes(x = value, y = metric)) +
    geom_boxplot() +
    geom_vline(aes(xintercept = 0.5),
               linetype = "dashed", color = "grey50") +
    scale_y_discrete(labels=function(x){sub("\\s", "\n", x)}) +
    xlim(xlims) +
    theme_bw() +
    theme(
      plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank()
    )
  prc <- perf_dat_long %>% filter(str_detect(metric, 'PRC')) %>%
    ggplot(aes(x = value, y = metric)) +
    geom_boxplot() +
    geom_vline(aes(xintercept = baseline_prc),
               linetype = "dashed", color = "grey50") +
    scale_y_discrete(labels=function(x){sub("\\s", "\n", x)}) +
    xlim(xlims) +
    labs(x = "Performance", y = "") +
    theme_bw() +
    theme(
      plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
      axis.title.y = element_blank()
    )
  roc / prc + plot_layout(heights = c(1, 0.5))
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
      mutate(perf_decrease = -perf_metric_diff) %>%
    summarise(
      mean_auroc = mean(perf_metric),
      sd_auroc = sd(perf_metric),
      mean_diff = mean(perf_metric_diff),
      median_diff = median(perf_metric_diff),
      sd_diff = sd(perf_metric_diff),
      mean_decrease = mean(perf_decrease),
      sd_decrease = sd(perf_decrease),
      se_decrease = sd_decrease / sqrt(n()),
      lowerq = quantile(perf_decrease)[2],
      upperq = quantile(perf_decrease)[4],
      iqr = upperq - lowerq,
      lower_whisker = lowerq + 1.5 * lowerq,
      upper_whisker = upperq - 1.5 * upperq
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
  # legend title is incorrectly aligned. known issue: https://github.com/tidyverse/ggplot2/issues/2465
  top_feats %>%
    ggplot(aes(
      x = mean_decrease,
      y = label,
      color = percent_models_signif
    )) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_pointrange(aes(xmin = lower_whisker, xmax = upper_whisker)) +
    scale_color_continuous(type = "viridis", name = "% models") +
    labs(y = "", x = "Decrease in AUROC") +
    guides(color = guide_colorbar(label.position = "bottom", # https://github.com/tidyverse/ggplot2/issues/2465
                                title.position = "left", title.vjust = 0.8)
           ) +
    theme_bw() +
    theme(
      axis.text.y = element_markdown(size = 10),
      axis.title.y = element_blank(),
      legend.title = element_text(size = 9,
                                  margin = margin(0, 0, 0, 0, "pt")),
      legend.title.align = 0.5,
      legend.text = element_text(size = 8),
      legend.position = "bottom",
      legend.justification = 'left',
      legend.box.just = 'left',
      legend.box.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
      legend.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
      plot.margin = unit(x = c(17, 8, 0, 2), units = "pt")
    )
}

mean_iqr <- function(x) {
    return(data.frame(y = mean(x),
                      ymin = quantile(x)[2],
                      ymax = quantile(x)[4])
           )
}

mean_sd <- function(x) {
    return(data.frame(y = mean(x),
                      ymin = mean(x) - sd(x),
                      ymax = mean(x) + sd(x))
           )
}

mean_whisker <- function(x) {
    meanx <- mean(x)
    lowerq <- quantile(x)[2]
    upperq <- quantile(x)[4]
    iqr <- upperq - lowerq
    return(data.frame(y = meanx,
                      ymin = meanx - lowerq * 1.5,
                      ymax = meanx + upperq * 1.5)
           )
}

capwords <- function(s, strict = FALSE) {
    cap <- function(s) paste(toupper(substring(s, 1, 1)),
                  {s <- substring(s, 2); if(strict) tolower(s) else s},
                             sep = "", collapse = " " )
    sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))
}

greys <- RColorBrewer::brewer.pal(name = 'Greys', n = 9)
c(No=greys[7], Yes=greys[4])

plot_rel_abun <- function(top_feats_rel_abun) {
  top_feats_rel_abun %>% mutate(pos_cdiff_d1 = capwords(pos_cdiff_d1)) %>%
    ggplot(aes(rel_abun_c, label, color = pos_cdiff_d1)) +
    stat_summary(fun.data = mean_whisker,
                 geom = 'pointrange',
                 position = position_dodge(width = 0.5)) +
    scale_x_log10() +
    scale_color_manual(values = c(No=greys[7], Yes=greys[4])) +
    labs(x = expression('Relative Abundance ('*log[10]+1*")")) +
    guides(color = guide_legend(title = "Positive for \n_C. difficile_")) +
    theme_bw() +
    theme(
      axis.text.y = element_markdown(size = 8),
      axis.title.y = element_blank(),
      legend.title = element_markdown(size = 9),
      legend.text = element_text(size = 8),
      legend.position = "bottom",
      legend.spacing.x = unit(0.5, "pt"),
      legend.box.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
      legend.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
      plot.margin = unit(x = c(17, 5, 0, 0), units = "pt")
    )
}
