rm(list = ls())
library(arrow)
library(bit64)
library(tidyverse)
library(igraph)
library(furrr)
library(entoptic)
library(scales)
plan(multisession, workers = availableCores() - 1)
setwd("~/Github/masterthesis/analysis")
DPI <- 300

# === Load Data ===
g <- readRDS("../data/nets/g.rds")

# === Get Ego Nets ===
politician_ids <- which(!is.na(V(g)$politician_name))
ego <- lapply(politician_ids, function(v) {
  eg <- make_ego_graph(g, order = 5, nodes = v, mode = "all")[[1]]
  screen <- V(g)$user_screen_name[v]
  keep <- sapply(strsplit(E(eg)$thread_root_user_screen_name, "\\|"), function(x) screen %in% x)
  subgraph_from_edges(eg, which(keep), delete.vertices = TRUE)
})
names(ego) <- V(g)$politician_name[politician_ids]

# === For each ego net: observed stat vs random baseline (parallel) ===
safe_rel <- function(obs, rand) ifelse(rand == 0, NA_real_, (obs - rand) / rand)

ego_stats <- future_map_dfr(seq_along(ego), function(k) {
  eg  <- ego[[k]]
  pid <- politician_ids[k]
  ego_screen <- V(g)$user_screen_name[pid]
  ego_vid <- which(V(eg)$user_screen_name == ego_screen)
  if (length(ego_vid) == 0) return(tibble())
  alter_g <- delete_vertices(eg, ego_vid)
  if (vcount(alter_g) < 2 || ecount(alter_g) == 0) return(tibble())
  
  pop_bin <- as.integer(!is.na(V(g)$populism_score[pid]) & V(g)$populism_score[pid] > 0)
  
  alter_names <- V(alter_g)$name
  idx <- match(alter_names, V(g)$name)
  followers <- as.double(V(g)$user_followers[idx])
  tweets    <- as.double(V(g)$user_tweets[idx])
  pop_score <- as.double(V(g)$populism_score[idx])
  
  all_pairs <- t(combn(seq_along(alter_names), 2))
  rand_absdiff_fol <- mean(abs(followers[all_pairs[,1]] - followers[all_pairs[,2]]), na.rm = TRUE)
  rand_absdiff_tw  <- mean(abs(tweets[all_pairs[,1]]    - tweets[all_pairs[,2]]),    na.rm = TRUE)
  rand_absdiff_pop <- mean(abs(pop_score[all_pairs[,1]] - pop_score[all_pairs[,2]]), na.rm = TRUE)
  rand_sum_fol     <- mean(followers[all_pairs[,1]] + followers[all_pairs[,2]], na.rm = TRUE)
  rand_sum_tw      <- mean(tweets[all_pairs[,1]]    + tweets[all_pairs[,2]],    na.rm = TRUE)
  rand_sum_pop     <- mean(pop_score[all_pairs[,1]] + pop_score[all_pairs[,2]], na.rm = TRUE)
  
  el <- igraph::as_data_frame(alter_g, what = "edges")
  ei <- match(el$from, alter_names)
  ej <- match(el$to,   alter_names)
  obs_absdiff_fol <- mean(abs(followers[ei] - followers[ej]), na.rm = TRUE)
  obs_absdiff_tw  <- mean(abs(tweets[ei]    - tweets[ej]),    na.rm = TRUE)
  obs_absdiff_pop <- mean(abs(pop_score[ei] - pop_score[ej]), na.rm = TRUE)
  obs_sum_fol     <- mean(followers[ei] + followers[ej], na.rm = TRUE)
  obs_sum_tw      <- mean(tweets[ei]    + tweets[ej],    na.rm = TRUE)
  obs_sum_pop     <- mean(pop_score[ei] + pop_score[ej], na.rm = TRUE)
  
  tibble(
    politician_name = names(ego)[k],
    ego_label = ifelse(pop_bin == 1, "Populist", "Non-Populist"),
    n_alters  = vcount(alter_g),
    n_edges   = ecount(alter_g),
    absdiff_followers = safe_rel(obs_absdiff_fol, rand_absdiff_fol),
    absdiff_tweets    = safe_rel(obs_absdiff_tw,  rand_absdiff_tw),
    absdiff_populism  = safe_rel(obs_absdiff_pop, rand_absdiff_pop),
    nodecov_followers = safe_rel(obs_sum_fol, rand_sum_fol),
    nodecov_tweets    = safe_rel(obs_sum_tw,  rand_sum_tw),
    nodecov_populism  = safe_rel(obs_sum_pop, rand_sum_pop)
  )
}, .options = furrr_options(globals = c("ego", "politician_ids", "g", "safe_rel"),
                            packages = c("igraph", "tibble", "dplyr")),
.progress = TRUE)

plan(sequential)










# === absdiff (homophily) ===
d_absdiff <- ego_stats |>
  select(politician_name, ego_label, starts_with("absdiff_")) |>
  pivot_longer(starts_with("absdiff_"), names_to = "metric", values_to = "value",
               names_prefix = "absdiff_") |>
  mutate(metric = recode(str_to_title(metric),
                         "Followers" = "Alter Follower Count",
                         "Tweets"    = "Alter Tweet Count",
                         "Populism"  = "Alter Populism Score"
  )) |>
  group_by(ego_label, metric) |>
  summarise(Median = median(value, na.rm = TRUE),
            Mean   = mean(value, na.rm = TRUE),
            .groups = "drop") |>
  pivot_longer(c(Median, Mean), names_to = "stat", values_to = "value")

sym_lim_abs <- max(abs(d_absdiff$value), na.rm = TRUE) * 1.15
breaks_abs  <- seq(-floor(sym_lim_abs), floor(sym_lim_abs), by = 1)

ggplot(d_absdiff, aes(x = ego_label, y = value, shape = stat)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_hline(yintercept = setdiff(breaks_abs, 0), linetype = "dotted", color = "grey80") +
  geom_point(size = 3.5) +
  scale_shape_manual(values = c(Median = 16, Mean = 17)) +
  scale_y_continuous(labels = scales::percent_format(),
                     breaks = breaks_abs,
                     limits = c(-sym_lim_abs, sym_lim_abs)) +
  facet_wrap(~ metric) +
  labs(x = NULL,
       y = "Alter Similarity: (Observed − Random) / Random",
       shape = NULL) +
  theme_bw() +
  theme(legend.position = "bottom",
        panel.grid = element_blank(),
        strip.background = element_rect(fill = "white", color = "black", linewidth = 1),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 1))
ggsave("../images/6-quasi_ergm_absdiff.png", bg = "white", width = 8, height = 4, dpi = DPI)



# === nodecov / sum (activity) ===
d_nodecov <- ego_stats |>
  select(politician_name, ego_label, starts_with("nodecov_")) |>
  pivot_longer(starts_with("nodecov_"), names_to = "metric", values_to = "value",
               names_prefix = "nodecov_") |>
  mutate(metric = recode(str_to_title(metric),
                         "Followers" = "Alter Follower Count",
                         "Tweets"    = "Alter Tweet Count",
                         "Populism"  = "Alter Populism Score"
  )) |>
  group_by(ego_label, metric) |>
  summarise(Median = median(value, na.rm = TRUE),
            Mean   = mean(value, na.rm = TRUE),
            .groups = "drop") |>
  pivot_longer(c(Median, Mean), names_to = "stat", values_to = "value")

sym_lim_nod <- max(abs(d_nodecov$value), na.rm = TRUE) * 1.15
breaks_nod  <- seq(-floor(sym_lim_nod), floor(sym_lim_nod), by = 1)

ggplot(d_nodecov, aes(x = ego_label, y = value, shape = stat)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_hline(yintercept = setdiff(breaks_nod, 0), linetype = "dotted", color = "grey80") +
  geom_point(size = 3.5) +
  scale_shape_manual(values = c(Median = 16, Mean = 17)) +
  scale_y_continuous(labels = scales::percent_format(),
                     breaks = breaks_nod,
                     limits = c(-sym_lim_nod, sym_lim_nod)) +
  facet_wrap(~ metric) +
  labs(x = NULL,
       y = "Alter Activity: (Observed − Random) / Random",
       shape = NULL) +
  theme_bw() +
  theme(legend.position = "bottom",
        panel.grid = element_blank(),
        strip.background = element_rect(fill = "white", color = "black", linewidth = 1),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 1))
ggsave("../images/6-quasi_ergm_nodecov.png", bg = "white", width = 8, height = 4, dpi = DPI)
