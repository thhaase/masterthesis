rm(list = ls())
#.rs.restartR()

library(arrow)
library(bit64)
library(tidyverse)
library(data.table)

library(igraph)
library(intergraph)
library(network)
library(sna)
library(kableExtra)
library(ggraph)

library(ggnewscale)
library(ggrepel)
library(ggExtra)

options(rgl.useNULL = TRUE)
library(rayshader)
library(cowplot)
library(magick)
library(patchwork)

setwd("~/Github/masterthesis/analysis")
setDTthreads(0)

# === Load Data ===
#d <- read_parquet("../data/d.parquet")
d <- read_parquet("../data/d_raw.parquet")
g <- readRDS("../data/nets/g.rds") # largest component
#g <- readRDS("../data/g_full.rds")
# === META ===
DPI = 600
WIDTH = 5
HEIGHT = 9
# === Prepare tweet-level party data ===

d_party <- d |>
  as_tibble() |>
  filter(!is.na(people_score), !is.na(elite_score), !is.na(antagonism_score),
         !is.na(party), !is.na(politician_name)) |>
  mutate(populism_score = ifelse(people_score > 0 & elite_score < 0,
                                 ifelse(antagonism_score > 0,
                                        (people_score - elite_score) * antagonism_score,
                                        people_score - elite_score),
                                 0),
         block = factor(ifelse(party %in% c("SPD", "Grüne", "FDP"),
                              "Governing", "Opposition"),
                       levels = c("Governing", "Opposition")),
         party = factor(party,
                        levels = c("SPD", "Grüne", "FDP",
                                   "CDU", "CSU", "AfD", "Linke", "BSW")))

party_colors <- c("CDU" = "black",   "CSU"   = "navy",
                  "SPD" = "#E3000F", "Grüne" = "forestgreen",
                  "FDP" = "#FFED00", "Linke" = "#BE3075",
                  "AfD" = "#009EE0", "BSW"   = "#7D1934")


# shared theme for stacked bar plots
theme_bars <- theme_classic() +
  theme(strip.background = element_blank(),
        strip.text.y.left = element_text(face = "bold", angle = 0, margin = margin()),
        strip.placement = "outside",
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        legend.position = "right",
        panel.spacing.y = unit(0.5, "lines"),
        panel.background = element_rect(fill = "white", color = NA),
        panel.grid = element_blank())

# --- 1a) Anti-Elite (sorted by own dimension) ---
p_antielite <- d_party |>
  mutate(`Anti-Elite` = cut(-elite_score,
                       breaks = c(-Inf, 0, 1, 2, Inf),
                       labels = c("None (>= 0)", "Low (-1)", "Medium (-2)", "High (-3)"),
                       right = TRUE)) |>
  count(block, party, politician_name, `Anti-Elite`) |>
  group_by(politician_name) |>
  mutate(pct = n / sum(n) * 100,
         pol_nonzero = 100 - sum(pct[`Anti-Elite` == "None (>= 0)"])) |>
  ungroup() |>
  group_by(party) |>
  mutate(party_mean_nonzero = mean(unique(pol_nonzero))) |>
  ungroup() |>
  mutate(sort_key = party_mean_nonzero * 1000 + pol_nonzero,
         politician_label = fct_reorder(politician_name, sort_key),
         party = fct_reorder(party, -party_mean_nonzero)) |>
  ggplot(aes(x = pct, y = politician_label, fill = `Anti-Elite`)) +
  geom_col(position = "stack", width = 1) +
  scale_fill_viridis_d(option = "inferno", direction = -1, begin = 0.3, end = 0.9) +
  facet_grid(party ~ ., scales = "free_y", space = "free_y", switch = "y") +
  theme_bars +
  labs(x = "% of Politician's Tweets", y = NULL)
p_antielite
ggsave("../images/populism_stacked_antielite_all_tweets.png", bg = "white", width = WIDTH, height = HEIGHT, dpi = DPI)

# --- 1b) Pro-People (sorted by own dimension) ---
p_propeople <- d_party |>
  mutate(`Pro-People` = cut(people_score,
                       breaks = c(-Inf, 0, 1, 2, Inf),
                       labels = c("None (<= 0)", "Low (1)", "Medium (2)", "High (3)"),
                       right = TRUE)) |>
  count(block, party, politician_name, `Pro-People`) |>
  group_by(politician_name) |>
  mutate(pct = n / sum(n) * 100,
         pol_nonzero = 100 - sum(pct[`Pro-People` == "None (<= 0)"])) |>
  ungroup() |>
  group_by(party) |>
  mutate(party_mean_nonzero = mean(unique(pol_nonzero))) |>
  ungroup() |>
  mutate(sort_key = party_mean_nonzero * 1000 + pol_nonzero,
         politician_label = fct_reorder(politician_name, sort_key),
         party = fct_reorder(party, -party_mean_nonzero)) |>
  ggplot(aes(x = pct, y = politician_label, fill = `Pro-People`)) +
  geom_col(position = "stack", width = 1) +
  scale_fill_viridis_d(option = "inferno", direction = -1, begin = 0.3, end = 0.9) +
  facet_grid(party ~ ., scales = "free_y", space = "free_y", switch = "y") +
  theme_bars +
  labs(x = "% of Politician's Tweets", y = NULL)
p_propeople
ggsave("../images/populism_stacked_propeople_all_tweets.png", bg = "white", width = WIDTH, height = HEIGHT, dpi = DPI)

# --- 1c) Antagonism (sorted by own dimension) ---
p_antagonism <- d_party |>
  mutate(Antagonism = cut(antagonism_score,
                       breaks = c(-Inf, 0, 1, 2, Inf),
                       labels = c("None (0)", "Low (1)", "Medium (2)", "High (3)"),
                       right = TRUE)) |>
  count(block, party, politician_name, Antagonism) |>
  group_by(politician_name) |>
  mutate(pct = n / sum(n) * 100,
         pol_nonzero = 100 - sum(pct[Antagonism == "None (0)"])) |>
  ungroup() |>
  group_by(party) |>
  mutate(party_mean_nonzero = mean(unique(pol_nonzero))) |>
  ungroup() |>
  mutate(sort_key = party_mean_nonzero * 1000 + pol_nonzero,
         politician_label = fct_reorder(politician_name, sort_key),
         party = fct_reorder(party, -party_mean_nonzero)) |>
  ggplot(aes(x = pct, y = politician_label, fill = Antagonism)) +
  geom_col(position = "stack", width = 1) +
  scale_fill_viridis_d(option = "inferno", direction = -1, begin = 0.3, end = 0.9) +
  facet_grid(party ~ ., scales = "free_y", space = "free_y", switch = "y") +
  theme_bars +
  labs(x = "% of Politician's Tweets", y = NULL)
p_antagonism
ggsave("../images/populism_stacked_antagonism_all_tweets.png", bg = "white", width = WIDTH, height = HEIGHT, dpi = DPI)

# === Combined plot - all dimensions side by side, sorted by populism score ===
party_pop_order <- d_party |>
  group_by(party) |>
  summarise(mean_pop = mean(populism_score), .groups = "drop") |>
  arrange(-mean_pop) |>
  pull(party)

prep_bars <- function(data, score_col, cat_name, breaks, labels, none_label) {
  data |>
    mutate(cat = cut(.data[[score_col]],
                     breaks = breaks, labels = labels, right = TRUE)) |>
    count(party, politician_name, cat) |>
    group_by(politician_name) |>
    mutate(pct = n / sum(n) * 100,
           pol_nonzero = 100 - sum(pct[cat == none_label])) |>
    ungroup() |>
    mutate(politician_label = fct_reorder(politician_name,
                                           match(party, party_pop_order) * 1000 + pol_nonzero),
           party = factor(party, levels = party_pop_order)) |>
    rename(!!cat_name := cat)
}

scales::show_col(c("gray95", rev(entoptic::firstlight(3,begin = 0.2, end = 0.75))))

scale_fill <- scale_fill_manual(values = c("gray95", rev(entoptic::firstlight(3,begin = 0.15, end = 0.6))))
#scale_fill <- scale_fill_manual(values = c("gray95", rev(viridis::inferno(3,begin = 0.3, end = 0.8))))

pc_ae <- prep_bars(d_party |> mutate(neg_elite = -elite_score),
                   "neg_elite", "Anti-Elite",
                   c(-Inf, 0, 1, 2, Inf),
                   c("None (>= 0)", "Low (-1)", "Medium (-2)", "High (-3)"),
                   "None (>= 0)") |>
  ggplot(aes(x = pct, y = politician_label, fill = `Anti-Elite`)) +
  geom_col(position = "stack", width = 1) +
  #scale_fill_viridis_d(option = "inferno", direction = -1, begin = 0.3, end = 0.9) +
  scale_fill +
  facet_grid(party ~ ., scales = "free_y", space = "free_y", switch = "y") +
  theme_bars +
  labs(x = NULL, y = NULL, title = "Anti-Elite") +
  theme(strip.text.y.left = element_text(size = 14, angle = 0))

pc_pp <- prep_bars(d_party, "people_score", "Pro-People",
                   c(-Inf, 0, 1, 2, Inf),
                   c("None (<= 0)", "Low (1)", "Medium (2)", "High (3)"),
                   "None (<= 0)") |>
  ggplot(aes(x = pct, y = politician_label, fill = `Pro-People`)) +
  geom_col(position = "stack", width = 1) +
  #scale_fill_viridis_d(option = "inferno", direction = -1, begin = 0.3, end = 0.9) +
  scale_fill +
  facet_grid(party ~ ., scales = "free_y", space = "free_y", switch = "y") +
  theme_bars + theme(strip.text.y.left = element_blank()) +
  labs(x = NULL, y = NULL, title = "Pro-People")

pc_an <- prep_bars(d_party, "antagonism_score", "Antagonism",
                   c(-Inf, 0, 1, 2, Inf),
                   c("None (0)", "Low (1)", "Medium (2)", "High (3)"),
                   "None (0)") |>
  ggplot(aes(x = pct, y = politician_label, fill = Antagonism)) +
  geom_col(position = "stack", width = 1) +
  #scale_fill_viridis_d(option = "inferno", direction = -1, begin = 0.3, end = 0.9) +
  scale_fill +
  facet_grid(party ~ ., scales = "free_y", space = "free_y", switch = "y") +
  theme_bars + theme(strip.text.y.left = element_blank()) +
  labs(x = NULL, y = NULL, title = "Antagonism")

pc_pop <- prep_bars(d_party, "populism_score", "Populism",
                    c(-Inf, 0, 2, 6, Inf),
                    c("None (0)", "Low (0-2]", "Medium (2-6]", "High (>6)"),
                    "None (0)") |>
  ggplot(aes(x = pct, y = politician_label, fill = Populism)) +
  geom_col(position = "stack", width = 1) +
  #scale_fill_viridis_d(option = "inferno", direction = -1, begin = 0.3, end = 0.9) +
  scale_fill +
  facet_grid(party ~ ., scales = "free_y", space = "free_y", switch = "y") +
  theme_bars + theme(strip.text.y.left = element_blank()) +
  labs(x = NULL, y = NULL, title = "Populism",
       #caption = "¹(Anti-Elite + Pro-People); if Antagonism > 0: (Anti-Elite + Pro-People)*Antagonism"
       )

pc_ae + pc_pp + pc_an + pc_pop +
  plot_layout(ncol = 4, guides = "collect") &
  labs(x = "% of Politician's Tweets") &
  theme(legend.position = "bottom",
        legend.text.position = "bottom",
        legend.title.position = "top",
        legend.title = element_text(size = 13),
        legend.text = element_text(size = 12),
        plot.title   = element_text(size = 18),
        axis.text.x  = element_text(size = 13),
        axis.title.x = element_text(size = 13)) 

#ggsave("../images/populism_stacked_dimensions_all_tweets_combined.png", bg = "white", width = 14, height = 10, dpi = DPI)
ggsave("../images/populism_stacked_dimensions_all_tweets_combined.png", bg = "white", width = 14, height = 12, dpi = DPI)

