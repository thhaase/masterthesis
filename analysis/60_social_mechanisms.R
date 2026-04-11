rm(list = ls())

library(arrow)
library(bit64)
library(tidyverse)
library(igraph)
library(ggraph)
library(easystats)
library(gtsummary)
library(broom)

setwd("~/Github/masterthesis/analysis")

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/nets/g.rds")

DPI <- 300

# === Extract Ego Networks (same as main analysis) ===
politician_ids <- which(!is.na(V(g)$politician_name))

ego <- lapply(politician_ids, function(v) {
  eg <- make_ego_graph(g, order = 5, nodes = v, mode = "all")[[1]]
  screen <- V(g)$user_screen_name[v]
  keep <- sapply(strsplit(E(eg)$thread_root_user_screen_name, "\\|"), function(x) screen %in% x)
  subgraph_from_edges(eg, which(keep), delete.vertices = TRUE)
})
names(ego) <- V(g)$politician_name[politician_ids]


# === Build Alter-Edge Dataset ===

d_edges <- map_dfr(names(ego), function(nm) {
  
  eg <- ego[[nm]]
  pid <- politician_ids[which(names(ego) == nm)]
  ego_screen <- V(g)$user_screen_name[pid]
  ego_vid <- which(V(eg)$user_screen_name == ego_screen)
  
  if (length(ego_vid) == 0) return(tibble())
  
  alter_g <- delete_vertices(eg, ego_vid)
  
  if (ecount(alter_g) == 0) return(tibble())
  
  el <- as_data_frame(alter_g, what = "edges")
  
  el$politician_name <- nm
  el$party <- V(g)$party[pid]
  el$populism_binary <- as.numeric(!is.na(V(g)$populism_score[pid]) & V(g)$populism_score[pid] > 0)
  el$ego_followers   <- V(g)$user_followers[pid]
  
  as_tibble(el)
})

# === Parse pipe-separated edge attributes ===
parse_pipe_mean <- function(x) {
  sapply(x, function(val) {
    nums <- suppressWarnings(as.numeric(strsplit(as.character(val), "\\|")[[1]]))
    if (all(is.na(nums))) NA_real_ else mean(nums, na.rm = TRUE)
  })
}

d_edges <- d_edges |> 
  mutate(
    weight      = as.numeric(weight),
    thread_size = parse_pipe_mean(thread_size)
  )

# === Diagnostics ===
cat("Edge dataset dimensions:", nrow(d_edges), "edges across", 
    n_distinct(d_edges$politician_name), "ego networks\n\n")

d_edges |> 
  summarise(
    n = n(),
    pct_weight_1   = mean(weight == 1),
    thread_size_na = mean(is.na(thread_size))
  ) |> 
  print()

d_edges |> 
  group_by(populism_binary) |> 
  summarise(
    n_egos  = n_distinct(politician_name),
    n_edges = n(),
    .groups = "drop"
  ) |> 
  print()

d_edges |> as.data.frame() |> head()
# ============================================================
# STEP 1: RULE OUT THE NULL (H3 — Thread Size)
# ============================================================

# --- 1a. Compare thread size by ego type ---

step1_summary <- d_edges |> 
  group_by(populism_binary) |> 
  summarise(
    n_edges            = n(),
    mean_thread_size   = mean(thread_size, na.rm = TRUE),
    median_thread_size = median(thread_size, na.rm = TRUE),
    .groups = "drop"
  )
print(step1_summary)

cat("\n--- Thread Size: Wilcoxon rank-sum test ---\n")
wilcox.test(thread_size ~ populism_binary, data = d_edges) |> print()


# --- 1b. Visualize thread size distributions ---

d_edges |> 
  mutate(populism_binary = factor(populism_binary, labels = c("Non-Populist", "Populist"))) |> 
  filter(!is.na(thread_size)) |>
  ggplot(aes(x = thread_size, fill = populism_binary)) +
  geom_density(alpha = 0.6, color = NA) +
  scale_fill_manual(values = c("Non-Populist" = "#16161D", "Populist" = "#3A6B50")) +
  scale_x_log10() +
  labs(x = "Thread Size (Log Scale)", y = "Density", fill = NULL,
       title = "Thread Size Distribution by Ego Type") +
  theme_classic() +
  theme(legend.position = "bottom")

# ggsave("../images/6-step1_thread_size.png", bg = "white", 
#        width = 7, height = 5, dpi = DPI)


# --- 1c. Ego-level regressions ---

d_ego <- map_dfr(names(ego), function(nm) {
  
  eg <- ego[[nm]]
  pid <- politician_ids[which(names(ego) == nm)]
  ego_screen <- V(g)$user_screen_name[pid]
  ego_vid <- which(V(eg)$user_screen_name == ego_screen)
  
  if (length(ego_vid) == 0) return(tibble())
  
  pop_raw <- V(g)$populism_score[pid]
  populism_binary <- as.numeric(!is.na(pop_raw) & pop_raw > 0)
  
  ego_degree <- igraph::degree(eg, v = ego_vid, mode = "all")
  alter_g <- igraph::delete_vertices(eg, ego_vid)
  
  n_alters <- igraph::vcount(alter_g)
  
  alter_degrees <- if (n_alters > 0) igraph::degree(alter_g, mode = "all") else numeric(0)
  mean_alter_degree <- if (n_alters > 0) mean(alter_degrees) else NA
  
  # thread size control
  edge_df <- as_data_frame(alter_g, what = "edges")
  
  if (nrow(edge_df) > 0) {
    ts_vals <- parse_pipe_mean(edge_df$thread_size)
    wt_vals <- as.numeric(edge_df$weight)
    mean_thread_size <- mean(ts_vals, na.rm = TRUE)
    mean_weight      <- mean(wt_vals, na.rm = TRUE)
  } else {
    mean_thread_size <- NA
    mean_weight      <- NA
  }
  
  # structural signatures (Step 2)
  prop_reciprocated <- NA
  if (igraph::is_directed(alter_g) && n_alters > 1) {
    dc <- igraph::dyad_census(alter_g)
    if ((dc$mut + dc$asym) > 0) {
      prop_reciprocated <- dc$mut / (dc$mut + dc$asym)
    }
  }
  
  component_count <- if (n_alters > 0) igraph::components(alter_g)$no else NA
  fragmentation   <- if (n_alters > 0) component_count / n_alters else NA
  
  tibble(
    politician_name   = nm,
    party             = V(g)$party[pid],
    populism_binary   = populism_binary,
    ego_degree        = ego_degree,
    user_followers    = V(g)$user_followers[pid],
    n_alters          = n_alters,
    mean_alter_degree = mean_alter_degree,
    mean_thread_size  = mean_thread_size,
    mean_weight       = mean_weight,
    component_count   = component_count,
    fragmentation     = fragmentation,
    prop_reciprocated = prop_reciprocated
  )
})

# --- Models ---

m0 <- lm(mean_alter_degree ~ populism_binary, data = d_ego)

m1 <- lm(mean_alter_degree ~ populism_binary + 
           mean_thread_size, 
         data = d_ego)

m2 <- lm(mean_alter_degree ~ populism_binary + 
           mean_thread_size +
           ego_degree + user_followers,
         data = d_ego)

cat("\n=== STEP 1 RESULTS ===\n")
cat("\nBaseline:\n")
summary(m0)
cat("\n+ Thread size control:\n")
summary(m1)
cat("\nFull model:\n")
summary(m2)


# --- Step 1 Regression Table ---

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

table_step1 <- tbl_merge(
  tbls = list(
    fmt_model(m0, list(
      populism_binary = "Populism (0/1)"
    )),
    fmt_model(m1, list(
      populism_binary  = "Populism (0/1)",
      mean_thread_size = "Mean Thread Size"
    )),
    fmt_model(m2, list(
      populism_binary  = "Populism (0/1)",
      mean_thread_size = "Mean Thread Size",
      ego_degree       = "Ego Degree",
      user_followers   = "Ego Followers"
    ))
  ),
  tab_spanner = c("**Baseline**", "**+ Thread Size**", "**Full Model**")
) |> 
  modify_table_body(~.x |> dplyr::arrange(row_type == "glance_statistic"))

# table_step1 |> as_kable_extra(format = "latex", booktabs = TRUE) |> 
#   writeLines("../tables/H3_thread_controls.tex")
# table_step1 |> as_gt() |> gt::gtsave("../tables/H3_thread_controls.png")


# --- Step 1 Coefficient Plot ---

bind_rows(
  tidy(m0, conf.int = TRUE) |> mutate(model = "Baseline"),
  tidy(m1, conf.int = TRUE) |> mutate(model = "+ Thread Size"),
  tidy(m2, conf.int = TRUE) |> mutate(model = "Full Model")
) |> 
  filter(term != "(Intercept)") |> 
  mutate(
    term = recode(term,
                  populism_binary  = "Populism (0/1)",
                  mean_thread_size = "Mean Thread Size",
                  ego_degree       = "Ego Degree",
                  user_followers   = "Ego Followers"
    ),
    sig = p.value < 0.05,
    model = factor(model, levels = c("Baseline", "+ Thread Size", "Full Model"))
  ) |> 
  ggplot(aes(x = estimate, y = reorder(term, estimate), color = sig)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), size = 0.6) +
  scale_color_manual(values = c("TRUE" = "#3A6B50", "FALSE" = "#16161D"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "n.s."),
                     name = NULL) +
  facet_wrap(~model, ncol = 3) +
  labs(x = "Coefficient Estimate", y = NULL,
       title = "Step 1: Does Populism Survive Thread Size Controls?") +
  theme_bw() +
  theme(legend.position = "bottom")

# ggsave("../images/6-step1_coefficient_plot.png", bg = "white", 
#        width = 10, height = 5, dpi = DPI)


# ============================================================
# STEP 2: CHARACTERIZE TIE QUALITY (H1 vs. H2)
# ============================================================

# --- 2a. Edge-level weight comparison ---

step2_edges <- d_edges |> 
  mutate(pop_label = factor(populism_binary, labels = c("Non-Populist", "Populist"))) |> 
  group_by(pop_label) |> 
  summarise(
    n_edges       = n(),
    mean_weight   = mean(weight, na.rm = TRUE),
    median_weight = median(weight, na.rm = TRUE),
    .groups = "drop"
  )
print(step2_edges)

cat("\n--- Edge Weight: Wilcoxon rank-sum test ---\n")
wilcox.test(weight ~ populism_binary, data = d_edges) |> print()


# --- 2b. Ego-level structural signatures ---

step2_structure <- d_ego |> 
  filter(n_alters > 0) |> 
  mutate(pop_label = factor(populism_binary, labels = c("Non-Populist", "Populist"))) |> 
  group_by(pop_label) |> 
  summarise(
    n = n(),
    mean_fragmentation = mean(fragmentation, na.rm = TRUE),
    mean_reciprocity   = mean(prop_reciprocated, na.rm = TRUE),
    mean_weight        = mean(mean_weight, na.rm = TRUE),
    .groups = "drop"
  )
print(step2_structure)


# --- 2c. Visualize edge weight ---

d_edges |> 
  mutate(pop_label = factor(populism_binary, labels = c("Non-Populist", "Populist"))) |>
  ggplot(aes(x = pop_label, y = weight, fill = pop_label)) +
  geom_boxplot(outlier.alpha = 0.3, width = 0.6) +
  scale_fill_manual(values = c("Non-Populist" = "#16161D", "Populist" = "#3A6B50")) +
  labs(x = NULL, y = "Edge Weight (Repeated Interactions)", fill = NULL,
       title = "Step 2: Tie Intensity — Edge Weight") +
  theme_classic() +
  theme(legend.position = "none")

# ggsave("../images/6-step2_edge_weight.png", bg = "white", 
#        width = 6, height = 5, dpi = DPI)


# --- 2d. Visualize ego-level structural signatures ---

d_ego |> 
  filter(n_alters > 0) |> 
  mutate(pop_label = factor(populism_binary, labels = c("Non-Populist", "Populist"))) |> 
  select(pop_label, prop_reciprocated, fragmentation) |> 
  pivot_longer(-pop_label, names_to = "metric", values_to = "value") |> 
  filter(!is.na(value)) |> 
  mutate(metric = recode(metric,
                         prop_reciprocated = "Proportion Reciprocated",
                         fragmentation     = "Fragmentation Ratio"
  )) |> 
  ggplot(aes(x = pop_label, y = value, fill = pop_label)) +
  geom_boxplot(outlier.alpha = 0.3, width = 0.6) +
  scale_fill_manual(values = c("Non-Populist" = "#16161D", "Populist" = "#3A6B50")) +
  facet_wrap(~metric, scales = "free_y") +
  labs(x = NULL, y = NULL, fill = NULL,
       title = "Step 2: Structural Signatures — Reciprocity and Fragmentation") +
  theme_classic() +
  theme(legend.position = "none")

# ggsave("../images/6-step2_structural_signatures.png", bg = "white", 
#        width = 8, height = 5, dpi = DPI)


# ============================================================
# SUMMARY
# ============================================================

cat("\n\n========================================\n")
cat("MECHANISM DIAGNOSTIC SUMMARY\n")
cat("========================================\n\n")

cat("H1 (In-Group Formation) predicts:\n")
cat("  - Higher edge weight       → sustained interaction\n")
cat("  - Lower fragmentation      → cohesive community\n")
cat("  - Higher reciprocity       → mutual ties\n\n")

cat("H2 (Provocation) predicts:\n")
cat("  - Lower edge weight        → one-off conflict\n")
cat("  - Higher fragmentation     → opposing camps\n\n")

cat("H3 (Thread Size) predicts:\n")
cat("  - Populism coefficient drops to n.s. after thread size control\n")
cat("  - Check Step 1 regression table\n")
