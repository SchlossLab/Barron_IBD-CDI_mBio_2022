library(tidyverse)
library(patchwork)
blues <- RColorBrewer::brewer.pal(name='Blues', n = 9)
greens <- RColorBrewer::brewer.pal(name='Greens', n = 9)

sens_dat <- read_csv(snakemake@input[['csv']])

auroc_step <- sens_dat %>%
    filter(seed == 100) %>%
  ggplot(aes(x = fpr,y = sensitivity, color = test_group)) +
  geom_step() +
  theme_bw() +
  labs(x="False Positive Rate",
       y="True Positive Rate") +
  geom_abline(intercept = 0,lty="dashed",color="grey50") +
  #scale_color_grey() +
  theme(legend.position = 'none')

summarize_roc <- function(test_group_val,
                          dat = sens_dat,
                          xcol = specificity,
                          ycol = sensitivity)  {
    dat %>%
        filter(test_group == test_group_val) %>%
    mutate(specificity = round(specificity, 2)) %>%
    group_by(specificity) %>%
    summarise(mean_sensitivity = mean({{ ycol }}),
              sd_sensitivity = sd({{ ycol }})) %>%
    mutate(upper_sens = mean_sensitivity + sd_sensitivity,
           lower_sens = mean_sensitivity - sd_sensitivity) %>%
    mutate(
        upper_sens = case_when(upper_sens > 1 ~ 1,
                               TRUE ~ upper_sens),
        lower_sens = case_when(upper_sens < 0 ~ 0,
                               TRUE ~ lower_sens),
        test_group = test_group_val
    )
}
test_groups <- sens_dat %>% pull(test_group) %>% unique()
roc_dat <- test_groups %>% map_dfr(summarize_roc)

# sensitivity vs specificity
auroc <- roc_dat %>% #filter(test_group == 'fmt_1') %>%
    ggplot(aes(x = specificity, y = mean_sensitivity,
             ymin = lower_sens, ymax = upper_sens)) +
    #geom_ribbon(aes(fill = test_group), alpha = 0.4) +
    geom_line(aes(color = test_group), alpha = 1) +
    coord_equal() +
    geom_abline(intercept = 1, slope = 1, linetype="dashed", color="grey50") +
    scale_y_continuous(expand = c(0,0), limits = c(-0.01,1.01)) +
    scale_x_reverse(expand = c(0,0), limits = c(1.01,-0.01)) +
    labs(x = 'Specificity', y = 'Sensitivity') +
    #guides(color = guide_legend(nrow = 1,title=""),
    #       fill = guide_legend(nrow = 1,title="")) +
    theme_bw() +
    theme(plot.margin = unit(x = c(0, 0, 0, 0), units = "pt"),
          legend.title = element_blank())

summarize_prc <- function(test_group_val,
                          dat = sens_dat,
                          xcol = recall,
                          ycol = precision)  {
    dat %>%
        filter(test_group == test_group_val) %>%
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
                          TRUE ~ lower),
        test_group = test_group_val
    )
}
prc_dat <- test_groups %>% map_dfr(summarize_prc)
# precision vs recall
auprc <- prc_dat %>%
    ggplot(aes(x = recall, y = mean_precision,
             ymin = lower, ymax = upper)) +
    #geom_ribbon(aes(fill = test_group), alpha = 0.4) +
    geom_line(aes(color = test_group), alpha = 1) +
    coord_equal() +
    geom_abline(intercept = 1, slope = 1, linetype="dashed", color="grey50") +
    scale_y_continuous(expand = c(0,0), limits = c(-0.01,1.01)) +
    scale_x_continuous(expand = c(0,0), limits = c(-0.01,1.01)) +
    labs(x = 'Recall', y = 'Precision') +
    theme_bw() +
    theme(plot.margin = unit(x = c(0, 0, 0, 7), units = "pt"),
          legend.position = 'none')

auc_plots <- auroc + auprc
ggsave(plot = auc_plots, filename = snakemake@output[['plot']],
       dpi = 200, units = 'in', width = 6, height = 5)
