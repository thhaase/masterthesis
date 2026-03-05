library(arrow)
library(data.table)
library(ggplot2)
library(irr)

setwd("~/Github/masterthesis/analysis")

compute_f1 <- function(a, b) {
  complete <- !is.na(a) & !is.na(b) # there are only 10 NAs from the LLM output
  a <- a[complete]
  b <- b[complete]
  tp <- sum(a == 1 & b == 1)
  fp <- sum(a == 0 & b == 1)
  fn <- sum(a == 1 & b == 0)
  prec <- tp / max(tp + fp, 1)
  rec <- tp / max(tp + fn, 1)
  fifelse(prec + rec == 0, 0, 2 * prec * rec / (prec + rec))
}
d_raw <- fread("../data/full.csv.zip")

d_annotated <- read_parquet(
  "../data/full_to_annotate_annotated_populism.parquet"
) |> setDT() |>
  _[, `:=`(
    elite_binary = as.integer(elite_score < 0),
    people_binary = as.integer(people_score > 0)
  )]

all_raters <- rbindlist(list(
  d_raw[, .(id, text, username, elite, centr)],
  d_annotated[, .(id, text, username = "LLM", elite = elite_binary, centr = people_binary)]
)) |>
  _[paste(id, text) %in% intersect(
    d_raw[, unique(paste(id, text))],
    d_annotated[, unique(paste(id, text))]
  )]

pairwise_long <- CJ(r1 = all_raters[, unique(username)], r2 = all_raters[, unique(username)])[r1 < r2] |>
  _[, {
    merged <- all_raters[username == r1, .(id, text, e1 = elite, c1 = centr)][
      all_raters[username == r2, .(id, text, e2 = elite, c2 = centr)],
      on = .(id, text), nomatch = NULL
    ]
    .(
      f1_elite = compute_f1(merged$e1, merged$e2),
      f1_people = compute_f1(merged$c1, merged$c2),
      pair_type = fifelse(r1 != "LLM" & r2 != "LLM", "Expert - Expert", "LLM - Expert")
    )
  }, by = .(r1, r2)] |>
  melt(
    id.vars = c("r1", "r2", "pair_type"),
    measure.vars = c("f1_elite", "f1_people"),
    variable.name = "dimension", value.name = "f1"
  ) |>
  _[, dimension := fifelse(dimension == "f1_elite", "Anti-Elitism", "People-Centrism")]

ggplot(pairwise_long, aes(x = pair_type, y = f1, fill = pair_type)) +
  geom_boxplot(width = 0.5, alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.12, size = 2, alpha = 0.6) +
  facet_wrap(~dimension) +
  scale_fill_manual(values = c("Expert - Expert" = "steelblue4", "LLM - Expert" = "tomato2")) +
  labs(
    title = "Pairwise F1 Scores: LLM vs. Expert Agreement",
    subtitle = "F1 Scores for each Combination of 5 Raters and Qwen3-235B LLM",
    x = NULL, y = "F1 Score",
    caption = "Data form Bundestag Speeches used to train the PopBERT Classifier\nQwen3s Rating collapsed from 7-Level Likertscale to Binary Scores for Comparison"
  ) +
  scale_y_continuous(limits = c(0,1), breaks = 1:10/10) +
  theme_bw() +
  theme(legend.position = "none",
        strip.text = element_text(face = "bold", size = 11),
        plot.title = element_text(face = "bold"),
        panel.grid.major.x = element_blank())

ggsave("../images/prompt-validation-pairwise-f1.png", width = 8, height = 5, dpi = 600)




d_raw[, .(
  elite_gold = as.integer(mean(elite) >= 0.5),
  centr_gold = as.integer(mean(centr) >= 0.5)
), by = .(id, text)][
  d_annotated, on = .(id, text), nomatch = NULL
] |> _[complete.cases(elite_binary, people_binary)] |>
  _[, .(
    elite_f1 = compute_f1(elite_gold, elite_binary),
    elite_prec = sum(elite_gold == 1 & elite_binary == 1) / max(sum(elite_binary == 1), 1),
    elite_rec = sum(elite_gold == 1 & elite_binary == 1) / max(sum(elite_gold == 1), 1),
    people_f1 = compute_f1(centr_gold, people_binary),
    people_prec = sum(centr_gold == 1 & people_binary == 1) / max(sum(people_binary == 1), 1),
    people_rec = sum(centr_gold == 1 & people_binary == 1) / max(sum(centr_gold == 1), 1)
  )] |>
  _[, data.table(
    dimension = rep(c("Anti-Elitism", "People-Centrism"), each = 3),
    metric = rep(c("F1", "Precision", "Recall"), 2),
    value = c(elite_f1, elite_prec, elite_rec, people_f1, people_prec, people_rec)
  )] |>
ggplot(aes(x = metric, y = value, fill = metric, alpha = metric)) +
  geom_col(width = 0.8) +
  geom_text(aes(label = sprintf("%.2f", value)), vjust = -0.5, size = 4) +
  facet_wrap(~dimension) +
  scale_fill_manual(values = c(F1 = "tomato", Precision = "steelblue4", Recall = "steelblue4")) +
  labs(
    title = "F1 Scores: Qwen3-235B LLM vs. Expert-Majority Vote",
    subtitle = "",
    x = NULL, y = "Score",
    caption = "Data form Bundestag Speeches used to train the PopBERT Classifier\nQwen3s Rating collapsed from 7-Level Likertscale to Binary Scores for Comparison"
  ) +
  scale_alpha_manual(values = c(F1 = 1, Precision = 0.75, Recall = 0.75), guide = "none") +
  scale_y_continuous(limits = c(0,1), breaks = 1:10/10) +
  theme_bw() +
  theme(plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold", size = 11),
        axis.text.x = element_text(size = 10),
        panel.grid.major.x = element_blank(),
        legend.position = "none")

ggsave("../images/prompt-validation-majority-f1.png", width = 7, height = 5, dpi = 600)
