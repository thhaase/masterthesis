rm(list = ls())
#.rs.restartR()

library(arrow)
library(bit64)
library(tidyverse)

library(igraph)
library(kableExtra)
library(ggraph)

library(easystats)

library(gtsummary)
library(broom)
setwd("~/Github/masterthesis/analysis")

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/nets/g.rds") # largest component
#g <- readRDS("../data/g_full.rds")

DPI = 300

# === Extract Egonetworks ===
politician_ids <- which(!is.na(V(g)$politician_name))

ego <- lapply(politician_ids, function(v) {
  eg <- make_ego_graph(g, order = 5, nodes = v, mode = "all")[[1]]
  screen <- V(g)$user_screen_name[v]
  keep <- sapply(strsplit(E(eg)$thread_root_user_screen_name, "\\|"), function(x) screen %in% x)
  subgraph_from_edges(eg, which(keep), delete.vertices = TRUE)
})
names(ego) <- V(g)$politician_name[politician_ids]

# === STRATEGY ===
# Y: mean_alter_degree as a networksize-robust measure of how well connected the alternetwork is 
# X: Ego populism_score (convert to binary (0==0 AND 1 when >0))


# Ego Controls (stored in V(g))
# - user_tweets
# - user_followers
# - vader_sentiment_mean
# Network Controls:
# - calculate ego_degree before removing ego
# - n_alters (nodes in network)
# - edge_density among alters
# - mean_alter_degree
# - gw_mean_alter_degree (geometrically weighted)
# - prop_reciprocated

# additionally put this information of the ego in the table:
# - user_screen_name
# - party
# - politician_name
# - populism_se
# - people_score
# - people_se
# - elite_score
# - elite_se
# - antag_score
# - antag_se
# - vader_sentiment_se


# === Summarize Ego Networks ===
d_ego <- map_dfr(names(ego), function(nm) {
  
  eg <- ego[[nm]]
  
  # find ego vertex in the subgraph
  pid <- politician_ids[which(names(ego) == nm)]
  ego_screen <- V(g)$user_screen_name[pid]
  ego_vid <- which(V(eg)$user_screen_name == ego_screen)
  
  # --- Y ---
  pop_raw         <- V(g)$populism_score[pid]
  populism_binary <- as.numeric(!is.na(pop_raw) & pop_raw > 0)
  
  people_raw    <- V(g)$people_score[pid]
  people_binary <- as.numeric(!is.na(people_raw) & people_raw > 0)
  
  elite_raw     <- V(g)$elite_score[pid]
  elite_binary  <- as.numeric(!is.na(elite_raw) & elite_raw < 0)
  
  antag_raw     <- V(g)$antag_score[pid]
  antag_binary  <- as.numeric(!is.na(antag_raw) & antag_raw > 0)
  
  # --- Ego-level controls (from full graph) ---
  user_tweets       <- V(g)$user_tweets[pid]
  user_followers    <- V(g)$user_followers[pid]
  vader_mean        <- V(g)$vader_sentiment_mean[pid]
  
  # --- Network controls ---
  # ego_degree BEFORE removing ego
  ego_degree <- igraph::degree(eg, v = ego_vid, mode = "all")
  
  # remove ego -> alter subgraph
  alter_g <- igraph::delete_vertices(eg, ego_vid)
  
  n_alters        <- igraph::vcount(alter_g)
  n_edges_alters  <- igraph::ecount(alter_g)
  edge_density    <- if (n_alters > 1) igraph::edge_density(alter_g) else NA
  transitivity_   <- if (n_alters > 2) igraph::transitivity(alter_g, type = "global") else NA
  
  alter_degrees     <- igraph::degree(alter_g, mode = "all")
  mean_alter_degree <- if (n_alters > 0) mean(alter_degrees) else NA
  
  # number of components in alter subgraph
  component_count <- if (n_alters > 0) {
    igraph::components(alter_g)$no
  } else {
    NA
  }
  
  # geometrically weighted mean alter degree (decay = 0.5)
  decay <- 0.5
  if (n_alters > 0) {
    weights <- decay^(seq_along(sort(alter_degrees)) - 1)
    gw_mean_alter_degree <- weighted.mean(sort(alter_degrees), weights)
  } else {
    gw_mean_alter_degree <- NA
  }
  
  # proportion reciprocated (dyads)
  if (igraph::is_directed(alter_g) && n_alters > 1) {
    dc <- igraph::dyad_census(alter_g)
    prop_reciprocated <- dc$mut / (dc$mut + dc$asym)
  } else {
    prop_reciprocated <- NA
  }
  
  # --- Additional ego info ---
  tibble(
    politician_name      = nm,
    user_screen_name     = ego_screen,
    party                = V(g)$party[pid],
    populism_score       = pop_raw,
    populism_binary      = populism_binary,
    people_score         = people_raw,
    people_binary        = people_binary,
    elite_score          = elite_raw,
    elite_binary         = elite_binary,
    antag_score          = antag_raw,
    antag_binary         = antag_binary,
    populism_se          = V(g)$populism_se[pid],
    people_se            = V(g)$people_se[pid],
    elite_se             = V(g)$elite_se[pid],
    antag_se             = V(g)$antag_se[pid],
    user_tweets          = user_tweets,
    user_followers       = user_followers,
    vader_sentiment_mean = vader_mean,
    vader_sentiment_se   = V(g)$vader_sentiment_se[pid],
    ego_degree           = ego_degree,
    n_alters             = n_alters,
    edge_density         = edge_density,
    transitivity         = transitivity_,
    mean_alter_degree    = mean_alter_degree,
    component_count      = component_count,
    gw_mean_alter_degree = gw_mean_alter_degree,
    prop_reciprocated    = prop_reciprocated
  )
})





# ==== MODEL POPULISM ====

# === Baseline ===
m0 <- lm(mean_alter_degree ~ populism_binary, 
         data = d_ego)
summary(m0)
check_model(m0)
ggsave("../images/5-modelcheck_m0.png",
       width = 11, height = 9, dpi = DPI)

# === Full ===
m1 <- lm(mean_alter_degree ~ populism_binary +
           ego_degree +
           user_followers, 
          data = d_ego)
summary(m1)
check_model(m1)
ggsave("../images/5-modelcheck_m1.png",
       width = 11, height = 9, dpi = DPI)


# ==== ROBUSTNESS CHECK ====
d_ego$fragmentation <- d_ego$component_count / d_ego$n_alters

r1 <- lm(mean_alter_degree ~ populism_binary +
           ego_degree +
           user_followers,
         data = d_ego)
summary(r1)
check_model(r1)
ggsave("../images/5-modelcheck_r1.png",
       width = 11, height = 9, dpi = DPI)



# ==== CREATE TABLE AND PLOTS ====
# === 1. gtsummary Table ===

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
    add_glance_table(include = c(nobs, r.squared, adj.r.squared, AIC)) |> 
    bold_labels()
}

lbl_pop <- list(populism_binary = "Ego Populism Score (0/1)")

table <- tbl_merge(
  tbls = list(
    fmt_model(m0, list(
      populism_binary      = "Ego Populism Score (0/1)"
    )),
    fmt_model(m1, list(
      populism_binary      = "Ego Populism Score (0/1)",
      ego_degree           = "Ego Degree",
      user_followers       = "Ego Followers",
      vader_sentiment_mean = "Ego VADER Sentiment"
    )),
    fmt_model(r1, list(
      populism_binary      = "Ego Populism Score (0/1)",
      ego_degree           = "Ego Degree",
      user_followers       = "Ego Followers",
      vader_sentiment_mean = "Ego VADER Sentiment"
    ))
  ),
  tab_spanner = c("**Baseline**", "**Full Model**", "**Robustness**")
) |> 
  modify_table_body(~.x |> dplyr::arrange(row_type == "glance_statistic"))

table |> as_kable_extra(format = "latex", booktabs = TRUE) |> writeLines("../tables/H1_egonet_models.tex")
table |> as_kable() |> writeLines("../tables/H1_egonet_models.md")
table |> as_gt() |> gt::gtsave("../tables/H1_egonet_models.png")
table

# === 2. Forest Plot (faceted by model) ===
bind_rows(
  tidy(m0, conf.int = TRUE) |> mutate(model = "Baseline"),
  tidy(m1, conf.int = TRUE) |> mutate(model = "Full Model"),
  tidy(r1, conf.int = TRUE) |> mutate(model = "Robustness")
) |> 
  filter(term != "(Intercept)") |> 
  mutate(
    term = recode(term,
                  populism_binary      = "Ego Populism Score (0/1)",
                  fragmentation        = "Fragmentation Ratio",
                  ego_degree           = "Ego Degree",
                  user_followers       = "Ego Followers",
                  vader_sentiment_mean = "Ego VADER Sentiment"
    ),
    term = factor(term, levels = rev(c(
      "Ego Populism Score (0/1)", "Fragmentation Ratio",
      "Ego Degree", "Ego Followers", "Ego VADER Sentiment"
    ))),
    sig = p.value < 0.05,
    model = factor(model, levels = c("Baseline", "Full Model", "Robustness"))
  ) |> 
  ggplot(aes(x = estimate, y = term, color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), size = 0.6) +
  scale_color_manual(values = c("TRUE" = "#3A6B50", "FALSE" = "#16161D"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "not significant"),
                     name = NULL) +
  facet_wrap(~model, ncol = 3) +
  labs(x = "Coefficient Estimate", y = NULL,
       title = "Coefficient Plot: Predicting Mean Alter Degree") +
  theme_bw() +
  theme(legend.position = "bottom")

ggsave("../images/5-H1_egonet_models.png", bg = "white", width = 10, height = 5, dpi = DPI)



# === 3. Predicted Probabilities ===
library(marginaleffects)
predictions(m1, 
            newdata = datagrid(populism_binary = c(0, 1))) |> 
  mutate(populism_binary = factor(populism_binary, levels = c(0,1))) |> 
  ggplot(aes(x = populism_binary, y = estimate)) +
  geom_jitter(
    data = d_ego |> 
      mutate(populism_binary = factor(populism_binary, levels = c(1, 0))),
    aes(y = mean_alter_degree),
    width = 0.1, alpha = 0.45, color = "#16161D", size = 2, stroke = 0
  ) +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high), 
                  size = 1.25, linewidth = 1.25, color = "#4B7D55") +
  scale_y_log10() +
  scale_x_discrete(labels = c("1" = "Populist", "0" = "Non-Populist")) +
  labs(
    x = "Ego Populism Score > 0",
    y = "Mean Alter Degree (Log Scaled)",
    title = "Predicted Values vs. Observations - Full Model (N = 147)"
  ) +
  theme_classic()
ggsave("../images/5-H1_predicted_values.png", bg = "white", 
       width = 6, height = 6, dpi = DPI)

predictions(r1, 
            newdata = datagrid(populism_binary = c(0, 1))) |> 
  mutate(populism_binary = factor(populism_binary, levels = c(0,1))) |> 
  ggplot(aes(x = populism_binary, y = estimate)) +
  geom_jitter(
    data = d_ego |> 
      mutate(populism_binary = factor(populism_binary, levels = c(1, 0))),
    aes(y = mean_alter_degree),
    width = 0.1, alpha = 0.45, color = "#16161D", size = 2, stroke = 0
  ) +
  geom_pointrange(aes(ymin = conf.low, ymax = conf.high), 
                  size = 1.25, linewidth = 1.25, color = "#4B7D55") +
  scale_y_log10() +
  scale_x_discrete(labels = c("1" = "Populist", "0" = "Non-Populist")) +
  labs(
    x = "Ego Populism Score > 0",
    y = "Fragmentation Ratio¹ (Log Scaled)",
    title = "Predicted Values vs. Observations - Full Model (N = 147)",
    caption = "¹ Component Count / Alter Count"
  ) +
  theme_classic()
ggsave("../images/5-H1-robustness_predicted_values.png", bg = "white", 
       width = 6, height = 6, dpi = DPI)

