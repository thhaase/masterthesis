rm(list = ls())

library(arrow)
library(bit64)
library(tidyverse)
library(igraph)
library(sandwich)
library(lmtest)
library(gtsummary)
library(broom)

setwd("~/Github/masterthesis/analysis")

DPI <- 300

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/nets/g.rds")

# === Extract Ego Networks ===
politician_ids <- which(!is.na(V(g)$politician_name))

ego <- lapply(politician_ids, function(v) {
  eg <- make_ego_graph(g, order = 5, nodes = v, mode = "all")[[1]]
  screen <- V(g)$user_screen_name[v]
  keep <- sapply(strsplit(E(eg)$thread_root_user_screen_name, "\\|"), function(x) screen %in% x)
  subgraph_from_edges(eg, which(keep), delete.vertices = TRUE)
})
names(ego) <- V(g)$politician_name[politician_ids]

parse_pipe_mean <- function(x) {
  sapply(x, function(val) {
    nums <- suppressWarnings(as.numeric(strsplit(as.character(val), "\\|")[[1]]))
    if (all(is.na(nums))) NA_real_ else mean(nums, na.rm = TRUE)
  })
}

# === Build Dyadic Dataset ===
d_dyads <- map_dfr(names(ego), function(nm) {
  
  eg <- ego[[nm]]
  pid <- politician_ids[which(names(ego) == nm)]
  ego_screen <- V(g)$user_screen_name[pid]
  ego_vid <- which(V(eg)$user_screen_name == ego_screen)
  
  if (length(ego_vid) == 0) return(tibble())
  alter_g <- delete_vertices(eg, ego_vid)
  if (ecount(alter_g) == 0) return(tibble())
  
  el <- as_data_frame(alter_g, what = "edges")
  el$politician_name <- nm
  el$populism_binary <- as.numeric(!is.na(V(g)$populism_score[pid]) & V(g)$populism_score[pid] > 0)
  
  as_tibble(el)
})

# === Look up vertex attributes from g ===
from_idx <- match(d_dyads$from, V(g)$name)
to_idx   <- match(d_dyads$to, V(g)$name)

d_dyads$from_followers <- V(g)$user_followers[from_idx]
d_dyads$to_followers   <- V(g)$user_followers[to_idx]
d_dyads$from_tweets    <- V(g)$user_tweets[from_idx]
d_dyads$to_tweets      <- V(g)$user_tweets[to_idx]
d_dyads$from_populism  <- V(g)$populism_score[from_idx]
d_dyads$to_populism    <- V(g)$populism_score[to_idx]
d_dyads$from_sentiment <- V(g)$vader_sentiment_mean[from_idx]
d_dyads$to_sentiment   <- V(g)$vader_sentiment_mean[to_idx]

# === Construct dyadic variables ===
d_dyads <- d_dyads |> 
  mutate(
    weight      = as.numeric(weight),
    thread_size = parse_pipe_mean(thread_size),
    from_followers = as.numeric(from_followers),
    to_followers   = as.numeric(to_followers),
    from_tweets    = as.numeric(from_tweets),
    to_tweets      = as.numeric(to_tweets),
    from_populism  = as.numeric(from_populism),
    to_populism    = as.numeric(to_populism),
    from_sentiment = as.numeric(from_sentiment),
    to_sentiment   = as.numeric(to_sentiment),
    sum_followers  = from_followers + to_followers,
    diff_followers = abs(from_followers - to_followers),
    sum_tweets     = from_tweets + to_tweets,
    diff_tweets    = abs(from_tweets - to_tweets),
    sum_populism   = from_populism + to_populism,
    diff_populism  = abs(from_populism - to_populism),
    sum_sentiment  = from_sentiment + to_sentiment,
    diff_sentiment = abs(from_sentiment - to_sentiment)
  )

# === Diagnostics ===
cat("Dyad dataset:", nrow(d_dyads), "edges across",
    n_distinct(d_dyads$politician_name), "ego networks\n\n")

d_dyads |> 
  group_by(populism_binary) |> 
  summarise(n_egos = n_distinct(politician_name), n_edges = n(), .groups = "drop") |> 
  print()

d_dyads |> 
  summarise(
    na_followers = mean(is.na(sum_followers)),
    na_populism  = mean(is.na(sum_populism)),
    na_sentiment = mean(is.na(sum_sentiment))
  ) |> print()


# ============================================================
# MODELS
# ============================================================

m0 <- lm(weight ~ populism_binary, data = d_dyads)

m1 <- lm(weight ~ populism_binary + 
           sum_followers + diff_followers + 
           sum_tweets + diff_tweets +
           thread_size, 
         data = d_dyads)

m2 <- lm(weight ~ populism_binary + 
           sum_followers + diff_followers + 
           sum_tweets + diff_tweets +
           sum_populism + diff_populism +
           #sum_sentiment + diff_sentiment +
           thread_size, 
         data = d_dyads)

m3 <- lm(weight ~ populism_binary * 
           (sum_followers + diff_followers + 
              sum_tweets + diff_tweets +
              sum_populism + diff_populism +
            #  sum_sentiment + diff_sentiment
            ) +
           thread_size, 
         data = d_dyads)

# === Clustered SEs ===
cc0 <- complete.cases(d_dyads[, c("weight", "populism_binary")])
cc1 <- complete.cases(d_dyads[, c("weight", "populism_binary", 
                                  "sum_followers", "diff_followers",
                                  "sum_tweets", "diff_tweets", "thread_size")])
cc2 <- complete.cases(d_dyads[, c("weight", "populism_binary", 
                                  "sum_followers", "diff_followers",
                                  "sum_tweets", "diff_tweets",
                                  "sum_populism", "diff_populism",
                                  "sum_sentiment", "diff_sentiment", "thread_size")])

cl0 <- vcovCL(m0, cluster = d_dyads$politician_name[cc0])
cl1 <- vcovCL(m1, cluster = d_dyads$politician_name[cc1])
cl2 <- vcovCL(m2, cluster = d_dyads$politician_name[cc2])
cl3 <- vcovCL(m3, cluster = d_dyads$politician_name[cc2])

cat("\n=== M0: Baseline (Clustered SEs) ===\n")
coeftest(m0, vcov = cl0) |> print()
cat("\n=== M1: + Activity Controls (Clustered SEs) ===\n")
coeftest(m1, vcov = cl1) |> print()
cat("\n=== M2: + Alter Populism & Sentiment (Clustered SEs) ===\n")
coeftest(m2, vcov = cl2) |> print()
cat("\n=== M3: + Interactions (Clustered SEs) ===\n")
coeftest(m3, vcov = cl3) |> print()

cat("\n=== M0 Raw ===\n"); summary(m0)
cat("\n=== M1 Raw ===\n"); summary(m1)
cat("\n=== M2 Raw ===\n"); summary(m2)
cat("\n=== M3 Raw ===\n"); summary(m3)


# === Regression Table ===
fmt_model <- function(model, labels) {
  model |> 
    tbl_regression(
      label = labels,
      estimate_fun = \(x) style_sigfig(x, digits = 2)
    ) |> 
    modify_column_merge(
      pattern = "{estimate} [{conf.low}, {conf.high}]",
      rows = !is.na(conf.low)
    ) |> 
    modify_header(estimate = "**Beta [95% CI]**") |> 
    add_significance_stars(
      hide_p = FALSE,
      pattern = "{p.value}{stars}",
      thresholds = c(0.001, 0.01, 0.05)
    ) |> 
    add_glance_table(include = c(nobs, r.squared, adj.r.squared)) |> 
    bold_labels()
}

lbl_full <- list(
  populism_binary = "Populism (0/1)",
  sum_followers   = "Sum Followers (i+j)",
  diff_followers  = "Diff Followers |i-j|",
  sum_tweets      = "Sum Tweets (i+j)",
  diff_tweets     = "Diff Tweets |i-j|",
  sum_populism    = "Sum Populism (i+j)",
  diff_populism   = "Diff Populism |i-j|",
  sum_sentiment   = "Sum Sentiment (i+j)",
  diff_sentiment  = "Diff Sentiment |i-j|",
  thread_size     = "Thread Size"
)

tbl_dyadic <- tbl_merge(
  tbls = list(
    fmt_model(m0, list(populism_binary = "Populism (0/1)")),
    fmt_model(m1, lbl_full),
    fmt_model(m2, lbl_full),
    fmt_model(m3, lbl_full)
  ),
  tab_spanner = c("**Baseline**", "**+ Activity**", "**+ Populism**", "**+ Interactions**")
) |> 
  modify_table_body(~.x |> dplyr::arrange(row_type == "glance_statistic"))

tbl_dyadic
# tbl_dyadic |> as_gt() |> gt::gtsave("../tables/H1_dyadic_models.png")
# tbl_dyadic |> as_kable_extra(format = "latex", booktabs = TRUE) |> 
#   writeLines("../tables/H1_dyadic_models.tex")


# === Coefficient Plot: M2 (main effects) ===
tidy(m2, conf.int = TRUE) |> 
  filter(term != "(Intercept)") |> 
  mutate(
    term = recode(term,
                  populism_binary = "Populism (0/1)",
                  sum_followers   = "Sum Followers",
                  diff_followers  = "Diff Followers",
                  sum_tweets      = "Sum Tweets",
                  diff_tweets     = "Diff Tweets",
                  sum_populism    = "Sum Populism",
                  diff_populism   = "Diff Populism",
                  sum_sentiment   = "Sum Sentiment",
                  diff_sentiment  = "Diff Sentiment",
                  thread_size     = "Thread Size"
    ),
    sig = p.value < 0.05
  ) |> 
  ggplot(aes(x = estimate, y = reorder(term, estimate), color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), size = 0.6) +
  scale_color_manual(values = c("TRUE" = "#3A6B50", "FALSE" = "#16161D"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "n.s."),
                     name = NULL) +
  labs(x = "Coefficient Estimate", y = NULL,
       title = "Dyadic Model: Predictors of Alter-Alter Tie Weight") +
  theme_bw() +
  theme(legend.position = "bottom")

# ggsave("../images/6-H1_dyadic_main_effects.png", bg = "white", 
#        width = 9, height = 6, dpi = DPI)


# === Coefficient Plot: M3 (interactions only) ===
tidy(m3, conf.int = TRUE) |> 
  filter(grepl(":", term)) |> 
  mutate(
    term = recode(term,
                  `populism_binary:sum_followers`  = "Populism x Sum Followers",
                  `populism_binary:diff_followers` = "Populism x Diff Followers",
                  `populism_binary:sum_tweets`     = "Populism x Sum Tweets",
                  `populism_binary:diff_tweets`    = "Populism x Diff Tweets",
                  `populism_binary:sum_populism`   = "Populism x Sum Alter Populism",
                  `populism_binary:diff_populism`  = "Populism x Diff Alter Populism",
                  `populism_binary:sum_sentiment`  = "Populism x Sum Sentiment",
                  `populism_binary:diff_sentiment` = "Populism x Diff Sentiment"
    ),
    sig = p.value < 0.05
  ) |> 
  ggplot(aes(x = estimate, y = reorder(term, estimate), color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), size = 0.6) +
  scale_color_manual(values = c("TRUE" = "#3A6B50", "FALSE" = "#16161D"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "n.s."),
                     name = NULL) +
  labs(x = "Coefficient Estimate", y = NULL,
       title = "Does Populism Change the Social Sorting Process?",
       subtitle = "Interaction terms from full dyadic model") +
  theme_bw() +
  theme(legend.position = "bottom")

# ggsave("../images/6-H1_dyadic_interactions.png", bg = "white", 
#        width = 9, height = 5, dpi = DPI)