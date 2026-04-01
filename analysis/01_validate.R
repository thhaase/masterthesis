rm(list = ls())d
library(arrow)
library(tidyverse)
library(irr)
setwd("~/Github/masterthesis/analysis")

compute_f1 <- function(rater_a, rater_b) {
  both_rated <- !is.na(rater_a) & !is.na(rater_b)
  rater_a <- rater_a[both_rated]
  rater_b <- rater_b[both_rated]
  
  both_positive   <- sum(rater_a == 1 & rater_b == 1)
  only_b_positive <- sum(rater_a == 0 & rater_b == 1)
  only_a_positive <- sum(rater_a == 1 & rater_b == 0)
  
  precision <- both_positive / max(both_positive + only_b_positive, 1)
  recall    <- both_positive / max(both_positive + only_a_positive, 1)
  
  if (precision + recall == 0) 0 else 2 * precision * recall / (precision + recall)
}

d_raw <- read_csv("../data/full.csv.zip", show_col_types = FALSE)

d_annotated <- read_parquet("../data/full_to_annotate_annotated_populism.parquet") |>
  mutate(
    elite_binary  = as.integer(elite_score < 0),
    people_binary = as.integer(people_score > 0)
  )

all_raters <- bind_rows(
  d_raw |> select(id, text, username, elite, centr),
  d_annotated |> transmute(id, text, username = "LLM", elite = elite_binary, centr = people_binary)
) |>
  semi_join(d_raw, by = c("id", "text")) |>
  semi_join(d_annotated, by = c("id", "text"))

wide_elite <- all_raters |>
  select(id, text, username, elite) |>
  pivot_wider(names_from = username, values_from = elite)

wide_people <- all_raters |>
  select(id, text, username, centr) |>
  pivot_wider(names_from = username, values_from = centr)

raters <- setdiff(names(wide_elite), c("id", "text"))
expert_raters <- setdiff(raters, "LLM")
pairs <- combn(raters, 2, simplify = FALSE)

# --- Plot 1: Pairwise F1 ---

map_dfr(pairs, \(p) {
  tibble(
    r1 = p[1], r2 = p[2],
    pair_type = if_else(r1 != "LLM" & r2 != "LLM", "Expert - Expert", "LLM - Expert"),
    dimension = c("Anti-Elitism", "People-Centrism"),
    f1 = c(
      compute_f1(wide_elite[[p[1]]], wide_elite[[p[2]]]),
      compute_f1(wide_people[[p[1]]], wide_people[[p[2]]])
    )
  )
}) |>
  ggplot(aes(x = pair_type, y = f1, fill = pair_type)) +
  geom_boxplot(width = 0.5, alpha = 0.8, outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 2, alpha = 0.7) +
  facet_wrap(~dimension) +
  entoptic::scale_fill_entoptic_d(option = "firstlight", begin = 0.1, end = 0.5) +
  labs(
    title = "Pairwise F1 Scores: LLM vs. Expert Agreement",
    subtitle = "F1 Scores for each Combination of 5 Raters and Qwen3-235B LLM",
    x = NULL, y = "F1 Score",
    caption = "Data form Bundestag Speeches used to train the PopBERT Classifier\nQwen3s Rating collapsed from 7-Level Likertscale to Binary Scores for Comparison"
  ) +
  scale_y_continuous(limits = c(0, 1), breaks = 0:10 / 10) +
  theme_bw() +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 11),
    plot.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank()
  )

ggsave("../images/prompt-validation-pairwise-f1.png", width = 8, height = 4.5, dpi = 600)


map_dfr(pairs, \(p) {
  tibble(
    r1 = p[1], r2 = p[2],
    pair_type = if_else(r1 != "LLM" & r2 != "LLM", "Expert - Expert", "LLM - Expert"),
    dimension = c("Anti-Elitism", "People-Centrism"),
    f1 = c(
      compute_f1(wide_elite[[p[1]]], wide_elite[[p[2]]]),
      compute_f1(wide_people[[p[1]]], wide_people[[p[2]]])
    )
  )
}) |>
  ggplot(aes(x = pair_type, y = f1, fill = pair_type)) +
  geom_boxplot(width = 0.5, alpha = 0.8, outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 2, alpha = 0.7) +
  facet_wrap(~dimension) +
  entoptic::scale_fill_entoptic_d(option = "firstlight", begin = 0.1, end = 0.5) +
  labs(
    #title = "Pairwise F1 Scores: LLM vs. Expert Agreement",
    #subtitle = "F1 Scores for each Combination of 5 Raters and Qwen3-235B LLM",
    x = NULL, y = "F1 Score",
    #caption = "Data form Bundestag Speeches used to train the PopBERT Classifier\nQwen3s Rating collapsed from 7-Level Likertscale to Binary Scores for Comparison"
  ) +
  scale_y_continuous(limits = c(0, 1), breaks = 0:10 / 10) +
  theme_bw() +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 11),
    plot.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank()
  )
ggsave("../images/prompt-validation-pairwise-f1-no-labs.png", width = 8, height = 3.7, dpi = 600)




map_dfr(pairs, \(p) {
  tibble(
    r1 = p[1], r2 = p[2],
    pair_type = if_else(r1 != "LLM" & r2 != "LLM", "Expert - Expert", "LLM - Expert"),
    dimension = c("Anti-Elitism", "People-Centrism"),
    accuracy = c(
      mean(wide_elite[[p[1]]] == wide_elite[[p[2]]], na.rm = TRUE),
      mean(wide_people[[p[1]]] == wide_people[[p[2]]], na.rm = TRUE)
    )
  )
}) |>
  ggplot(aes(x = pair_type, y = accuracy, fill = pair_type)) +
  geom_boxplot(width = 0.5, alpha = 0.8, outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 2, alpha = 0.7) +
  facet_wrap(~dimension) +
  entoptic::scale_fill_entoptic_d(option = "firstlight", begin = 0.1, end = 0.5) +
  labs(x = NULL, y = "Accuracy") +
  scale_y_continuous(limits = c(0, 1), breaks = 0:10 / 10) +
  theme_bw() +
  theme(
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 11),
    plot.title = element_text(face = "bold"),
    panel.grid.major.x = element_blank()
  )
ggsave("../images/prompt-validation-pairwise-accuracy.png", width = 8, height = 3.7, dpi = 600)


# --- Plot 2: Majority-vote F1 ---

gold_vs_llm <- function(wide, label) {
  wide |>
    mutate(gold = as.integer(rowMeans(pick(all_of(expert_raters)), na.rm = TRUE) >= 0.5)) |>
    filter(!is.na(LLM)) |>
    summarise(
      F1        = compute_f1(gold, LLM),
      Precision = sum(gold == 1 & LLM == 1) / max(sum(LLM == 1), 1),
      Recall    = sum(gold == 1 & LLM == 1) / max(sum(gold == 1), 1)
    ) |>
    pivot_longer(everything(), names_to = "metric", values_to = "value") |>
    mutate(dimension = label)
}

bind_rows(
  gold_vs_llm(wide_elite, "Anti-Elitism"),
  gold_vs_llm(wide_people, "People-Centrism")
) |>
  ggplot(aes(x = metric, y = value, fill = metric, alpha = metric)) +
  geom_col(width = 0.8) +
  geom_text(aes(label = sprintf("%.2f", value)), vjust = -0.5, size = 4) +
  facet_wrap(~dimension) +
  entoptic::scale_fill_entoptic_d(option = "firstlight", end = 0.75) +
  labs(
    title = "F1 Scores: Qwen3-235B LLM vs. Expert-Majority Vote",
    subtitle = "",
    x = NULL, y = "Score",
    caption = "Data form Bundestag Speeches used to train the PopBERT Classifier\nQwen3s Rating collapsed from 7-Level Likertscale to Binary Scores for Comparison"
  ) +
  scale_alpha_manual(values = c(F1 = 1, Precision = 0.75, Recall = 0.75), guide = "none") +
  scale_y_continuous(limits = c(0, 1), breaks = 0:10 / 10) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", size = 11),
    axis.text.x = element_text(size = 10),
    panel.grid.major.x = element_blank(),
    legend.position = "none"
  )

ggsave("../images/prompt-validation-majority-f1.png", width = 7, height = 5, dpi = 600)
