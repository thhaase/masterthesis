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
data_path <- "/home/thhaase/Documents/synosys_masterthesis"

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/g.rds")

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
# Y: Ego populism_score (convert to binary (0==0 AND 1 when >0))
# X: mean_alter_degree as a networksize-robust measure of how well connected the alternetwork is 

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
  edge_density    <- if (n_alters > 1) igraph::edge_density(alter_g) else NA_real_
  transitivity_   <- if (n_alters > 2) igraph::transitivity(alter_g, type = "global") else NA_real_
  
  alter_degrees     <- igraph::degree(alter_g, mode = "all")
  mean_alter_degree <- if (n_alters > 0) mean(alter_degrees) else NA_real_
  
  # number of components in alter subgraph
  component_count <- if (n_alters > 0) {
    igraph::components(alter_g)$no
  } else {
    NA_real_
  }
  
  # geometrically weighted mean alter degree (decay = 0.5)
  decay <- 0.5
  if (n_alters > 0) {
    weights <- decay^(seq_along(sort(alter_degrees)) - 1)
    gw_mean_alter_degree <- weighted.mean(sort(alter_degrees), weights)
  } else {
    gw_mean_alter_degree <- NA_real_
  }
  
  # proportion reciprocated (dyads)
  if (igraph::is_directed(alter_g) && n_alters > 1) {
    dc <- igraph::dyad_census(alter_g)
    prop_reciprocated <- dc$mut / (dc$mut + dc$asym)
  } else {
    prop_reciprocated <- NA_real_
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
m0 <- glm(populism_binary ~ mean_alter_degree, 
          family = binomial(link = "logit"), 
          data = d_ego)
summary(m0)

# === Full ===
m1 <- glm(populism_binary ~ mean_alter_degree + 
            ego_degree + 
            user_followers + 
            vader_sentiment_mean, 
          family = binomial(link = "logit"), 
          data = d_ego)
summary(m1)


# ==== ROBUSTNESS CHECK ====
d_ego$fragmentation <- d_ego$component_count / d_ego$n_alters

r1 <- glm(populism_binary ~ fragmentation + 
                ego_degree + 
                user_followers + 
                vader_sentiment_mean, 
              family = binomial(link = "logit"), 
              data = d_ego)
summary(r1)



# ==== CREATE TABLE AND PLOTS ====



# === 1. gtsummary Table ===
table <- tbl_merge(
  tbls = list(
    m0 |> 
      tbl_regression(
        exponentiate = TRUE,
        label = list(mean_alter_degree = "Mean Alter Degree"),
        conf.int = TRUE,
        add_estimate_to_reference_rows = FALSE
      ) |> 
      modify_column_merge(
        pattern = "[{conf.low}, {conf.high}]",
        rows = !is.na(estimate)
      ) |> 
      modify_header(conf.low = "**95% CI**") |> 
      add_significance_stars(
        hide_p = FALSE,
        pattern = "{p.value}{stars}",
        thresholds = c(0.001, 0.01, 0.05)
      ) |> 
      add_glance_table(include = c(nobs, logLik, AIC, deviance)) |> 
      bold_labels(),
    
    m1 |> 
      tbl_regression(
        exponentiate = TRUE,
        label = list(
          mean_alter_degree    = "Mean Alter Degree",
          ego_degree           = "Ego Degree",
          user_followers       = "User Followers",
          vader_sentiment_mean = "VADER Sentiment"
        )
      ) |> 
      modify_column_merge(
        pattern = "[{conf.low}, {conf.high}]",
        rows = !is.na(estimate)
      ) |> 
      modify_header(conf.low = "**95% CI**") |> 
      add_significance_stars(
        hide_p = FALSE,
        pattern = "{p.value}{stars}",
        thresholds = c(0.001, 0.01, 0.05)
      ) |> 
      add_glance_table(include = c(nobs, logLik, AIC, deviance)) |> 
      bold_labels(),
    
    r1 |> 
      tbl_regression(
        exponentiate = TRUE,
        label = list(
          fragmentation        = "Fragmentation Ratio",
          ego_degree           = "Ego Degree",
          user_followers       = "User Followers",
          vader_sentiment_mean = "VADER Sentiment"
        )
      ) |> 
      modify_column_merge(
        pattern = "[{conf.low}, {conf.high}]",
        rows = !is.na(estimate)
      ) |> 
      modify_header(conf.low = "**95% CI**") |> 
      add_significance_stars(
        hide_p = FALSE,
        pattern = "{p.value}{stars}",
        thresholds = c(0.001, 0.01, 0.05)
      ) |> 
      add_glance_table(include = c(nobs, logLik, AIC, deviance)) |> 
      bold_labels()
  ),
  tab_spanner = c("**Baseline**", "**Full Model**", "**Robustness**")
) |> 
  modify_table_body(~.x |> dplyr::arrange(row_type == "glance_statistic"))

table |> as_kable_extra(format = "latex", booktabs = TRUE) |> writeLines("../tables/H1_egonet_models.tex")
table |> as_kable() |> writeLines("../tables/H1_egonet_models.md")
table |> as_gt() |> gt::gtsave("../tables/H1_egonet_models.png")


# === 2. Forest Plot (faceted by model) ===
bind_rows(
  tidy(m0, conf.int = TRUE, exponentiate = TRUE) |> mutate(model = "Baseline"),
  tidy(m1, conf.int = TRUE, exponentiate = TRUE) |> mutate(model = "Full Model"),
  tidy(r1, conf.int = TRUE, exponentiate = TRUE) |> mutate(model = "Robustness")
) |> 
  filter(term != "(Intercept)") |> 
  mutate(
    term = recode(term,
                  mean_alter_degree    = "Mean Alter Degree",
                  fragmentation        = "Fragmentation Ratio",
                  ego_degree           = "Ego Degree",
                  user_followers       = "User Followers",
                  vader_sentiment_mean = "VADER Sentiment"
    ),
    term = factor(term, levels = rev(c(
      "Mean Alter Degree", "Fragmentation Ratio",
      "Ego Degree", "User Followers", "VADER Sentiment"
    ))),
    sig = p.value < 0.05,
    model = factor(model, levels = c("Baseline", "Full Model", "Robustness"))
  ) |> 
  ggplot(aes(x = estimate, y = term, color = sig)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), size = 0.6) +
  scale_x_log10(labels = scales::label_log()) +
  scale_color_manual(values = c("TRUE" = "firebrick3", "FALSE" = "grey30"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "not significant"),
                     name = NULL) +
  facet_wrap(~model, ncol = 3) +
  labs(x = "Odds Ratio (log scale)", y = NULL,
       title = "Variable Significance: Predicting Egos' Populism (Binary)") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("../images/H1_egonet_models.png", bg = "white", width = 10, height = 5, dpi = DPI)



# === 3. Predicted Probabilities ===
library(patchwork)

{
  # --- prediction grid: Full Model ---
  newdata_m1 <- data.frame(
    mean_alter_degree = seq(min(d_ego$mean_alter_degree, na.rm = TRUE),
                            max(d_ego$mean_alter_degree, na.rm = TRUE), 
                            length.out = 200),
    ego_degree           = median(d_ego$ego_degree, na.rm = TRUE),
    user_followers       = median(d_ego$user_followers, na.rm = TRUE),
    vader_sentiment_mean = median(d_ego$vader_sentiment_mean, na.rm = TRUE)
  )
  pred_m1 <- predict(m1, newdata = newdata_m1, type = "link", se.fit = TRUE)
  newdata_m1$prob    <- plogis(pred_m1$fit)
  newdata_m1$ci_low  <- plogis(pred_m1$fit - 1.96 * pred_m1$se.fit)
  newdata_m1$ci_high <- plogis(pred_m1$fit + 1.96 * pred_m1$se.fit)
  
  # --- prediction grid: Robustness ---
  newdata_rf <- data.frame(
    fragmentation = seq(min(d_ego$fragmentation, na.rm = TRUE),
                        max(d_ego$fragmentation, na.rm = TRUE), 
                        length.out = 200),
    ego_degree           = median(d_ego$ego_degree, na.rm = TRUE),
    user_followers       = median(d_ego$user_followers, na.rm = TRUE),
    vader_sentiment_mean = median(d_ego$vader_sentiment_mean, na.rm = TRUE)
  )
  pred_rf <- predict(r1, newdata = newdata_rf, type = "link", se.fit = TRUE)
  newdata_rf$prob    <- plogis(pred_rf$fit)
  newdata_rf$ci_low  <- plogis(pred_rf$fit - 1.96 * pred_rf$se.fit)
  newdata_rf$ci_high <- plogis(pred_rf$fit + 1.96 * pred_rf$se.fit)
  
  # --- jitter data ---
  jitter_m1 <- d_ego |> select(mean_alter_degree, populism_binary)
  jitter_rf <- d_ego |> select(fragmentation, populism_binary)
  
  # --- plot 1: Full Model ---
  p1 <- ggplot(newdata_m1, aes(x = mean_alter_degree, y = prob)) +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.2) +
    geom_line(linewidth = 1) +
    # geom_jitter(data = jitter_m1,
    #             aes(x = mean_alter_degree, y = populism_binary),
    #             height = 0.02, alpha = 0.3, size = 1.5) +
    scale_y_continuous(limits = c(0, 1)) +
    labs(x = "Mean Alter Degree",
         y = "P(Ego Populism = 1)",
         title = "Full Model") +
    theme_classic() +
    theme(plot.title = element_text(size = 12))
  
  # --- Robustness ---
  p2 <- ggplot(newdata_rf, aes(x = fragmentation, y = prob)) +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.2) +
    geom_line(linewidth = 1) +
    # geom_jitter(data = jitter_rf,
    #             aes(x = fragmentation, y = populism_binary),
    #             height = 0.02, alpha = 0.3, size = 1.5) +
    scale_y_continuous(limits = c(0, 1)) +
    labs(x = "Fragmentation Ratio (Component Count / Alter Count)",
         y = "P(Ego Populism = 1)",
         title = "Robustness") +
    theme_classic() +
    theme(plot.title = element_text(size = 12))
  
  # --- combine ---
  p1 + p2
}
ggsave("../images/H1_predicted_probabilities.png", bg = "white", width = 10, height = 5, dpi = DPI)


