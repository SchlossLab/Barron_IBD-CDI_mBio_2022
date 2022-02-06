library(tidyverse)
library(patchwork)
blues <- RColorBrewer::brewer.pal(name='Blues', n = 9)
greens <- RColorBrewer::brewer.pal(name='Greens', n = 9)

dat <- read_csv(snakemake@input[['csv']]) %>%
    mutate(seed = as.character(seed))

auroc_step <- dat %>%
  ggplot(aes(x = fpr,y = sensitivity, color = seed)) +
  geom_step() +
  theme_bw() +
  labs(x="False Positive Rate",
       y="True Positive Rate") +
  geom_abline(intercept = 0,lty="dashed",color="grey50") +
  scale_color_grey() +
  theme(legend.position = 'none')

# sensitivity vs specificity
auroc <- dat %>%
    mutate(specificity = round(specificity, 2)) %>%
    group_by(specificity) %>%
    summarise(mean_sensitivity = mean(sensitivity),
              sd_sensitivity = sd(sensitivity)) %>%
    mutate(upper_sens = mean_sensitivity + sd_sensitivity,
           lower_sens = mean_sensitivity - sd_sensitivity) %>%
    mutate(
        upper_sens = case_when(upper_sens > 1 ~ 1,
                               TRUE ~ upper_sens),
        lower_sens = case_when(upper_sens < 0 ~ 0,
                               TRUE ~ lower_sens)
    ) %>%
    ggplot(aes(x = specificity, y = mean_sensitivity,
             ymin = lower_sens, ymax = upper_sens)) +
    geom_ribbon(fill = blues[3]) +
    geom_line(color = blues[9]) +
    coord_equal() +
    geom_abline(intercept = 1, slope = 1, linetype="dashed", color="grey50") +
    scale_y_continuous(expand = c(0,0), limits = c(-0.01,1.01)) +
    scale_x_reverse(expand = c(0,0), limits = c(1.01,-0.01)) +
    labs(x = 'Specificity', y = 'Sensitivity') +
    guides(color = guide_legend(nrow = 1,title=""),
           fill = guide_legend(nrow = 1,title="")) +
    theme_bw() +
    theme(plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"))

# precision vs recall
auprc <- dat %>%
    rename(recall = sensitivity) %>%
    mutate(recall = round(recall, 2)) %>%
    group_by(recall) %>%
    summarise(mean_precision = mean(precision),
              sd_precision = sd(precision)) %>%
    mutate(upper = mean_precision + sd_precision,
           lower = mean_precision - sd_precision) %>%
    mutate(
        upper = case_when(upper > 1 ~ 1,
                          TRUE ~ upper),
        lower = case_when(upper < 0 ~ 0,
                          TRUE ~ lower)
    ) %>%
    ggplot(aes(x = recall, y = mean_precision,
             ymin = lower, ymax = upper)) +
    geom_ribbon(fill = greens[3]) +
    geom_line(color = greens[9]) +
    coord_equal() +
    geom_abline(intercept = 1, slope = 1, linetype="dashed", color="grey50") +
    scale_y_continuous(expand = c(0,0), limits = c(-0.01,1.01)) +
    scale_x_reverse(expand = c(0,0), limits = c(1.01,-0.01)) +
    labs(x = 'Recall', y = 'Precision') +
    guides(color = guide_legend(nrow = 1,title=""),
           fill = guide_legend(nrow = 1,title="")) +
    theme_bw() +
    theme(plot.margin = unit(x = c(0, 0, 0, 7), units = "pt"))

auc_plots <- auroc + auprc
ggsave(plot = auc_plots, filename = snakemake@output[['plot']],
       dpi = 200, units = 'in', width = 6, height = 5)
