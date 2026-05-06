rm(list = ls())
gc()
#.rs.restartR()

library(arrow)
library(tidyverse)
library(igraph)
library(kableExtra)
library(ggraph)
library(tidygraph)
library(quanteda)
library(quanteda.textstats)
library(patchwork)

library(sysfonts)
library(showtext)

font_add_google("Outfit", "Outfit")
showtext_auto()
setwd("~/Github/masterthesis/analysis")

# === Load Data ===
d <- read_parquet("../data/d_raw.parquet")
#g <- readRDS("../data/nets/g.rds") # largest component

# === Wordcorrelations ===

#pacman::p_load("cld2")
#languages <- cld2::detect_language(text = d$text, lang_code = F)

# tibble(languages) |> 
#   count(languages) |>
#   mutate(prop = n / sum(n)) |> 
#   arrange(-n)

d <- d |> 
  mutate(populism_score = ifelse(people_score > 0 & elite_score < 0,
                                 ifelse(antagonism_score > 0,
                                        (people_score - elite_score) * antagonism_score,
                                        people_score - elite_score),
                                 0)
  )

# === Global word-populism lookup (computed once on full data) ===
corp <- corpus(d$text,
               docvars = d |> select(-text))

toks <- corp |> 
  tokens(remove_punct = T,
         remove_numbers = T,
         remove_symbols = T,
         remove_separators = T)

dfm <- toks |> 
  dfm() |> 
  dfm_remove(pattern = c(stopwords("en"), stopwords("de"),
                         "rt", "@*", "dass", "u", "d", 
                         "mehr", "mal", "schon", "ja", "nein",
                         "beim", "s", "de", "us")) |> 
  dfm_trim(min_termfreq = .7, 
           termfreq_type = "quantile", 
           verbose = T)

top_features <- dfm |> 
  dfm_tfidf() |> 
  colMeans() |> 
  sort(decreasing = T) |> 
  head(10000) |> 
  names()

dfm <- dfm |> 
  dfm_select(pattern = top_features)

# === === === === === === === === === === === === === === === === === === === ==
# === Get Word-Populism associations ===

y <- docvars(dfm)$populism_score
keep <- !is.na(y)
y <- y[keep]
x <- as(dfm[keep, ], "dgCMatrix")
n <- nrow(x)

lookup <- data.frame(
  name = featnames(dfm[keep, ]),
  populism = as.numeric(
    (n * Matrix::crossprod(x, y) - Matrix::colSums(x) * sum(y)) /
      sqrt((n * Matrix::colSums(x^2) - Matrix::colSums(x)^2) *
             (n * sum(y^2) - sum(y)^2))
  )
)

# === === === === === === === === === === === === === === === === === === === ==
# === Per-group plot function ===

plot_group <- function(d_sub, lookup, title) {
  
  corp <- corpus(d_sub$text, docvars = d_sub |> select(-text))
  
  toks <- corp |> 
    tokens(remove_punct = T,
           remove_numbers = T,
           remove_symbols = T,
           remove_separators = T)
  
  dfm_g <- toks |> 
    dfm() |> 
    dfm_remove(pattern = c(stopwords("en"), stopwords("de"),
                           "rt", "@*", "dass", "u", "d", 
                           "mehr", "mal", "schon", "ja", "nein",
                           "beim", "s", "de", "us")) |> 
    dfm_trim(min_termfreq = .7, 
             termfreq_type = "quantile", 
             verbose = T)
  
  top_features <- dfm_g |> 
    dfm_tfidf() |> 
    colMeans() |> 
    sort(decreasing = T) |> 
    head(10000) |> 
    names()
  
  dfm_g <- dfm_g |> 
    dfm_select(pattern = top_features)
  
  fcm_g <- fcm(dfm_g)
  
  gp <- fcm_g |>
    igraph::graph_from_adjacency_matrix(weighted = TRUE) |>
    as_tbl_graph() |>
    activate(edges) |>
    filter(!edge_is_loop()) |>
    activate(nodes) |>
    filter(!node_is_isolated()) |>
    tidygraph::convert(to_undirected) |>
    tidygraph::convert(to_largest_component) |>
    activate(nodes) |>
    mutate(deg = centrality_degree()) |>
    top_n(100, deg) |>
    left_join(lookup, by = "name")
  
  set.seed(161)
  gp |> 
    ggraph(layout = "centrality", 
           cent = closeness(gp)) +
    # edges
    geom_edge_bundle_path0(
      aes(edge_linewidth = weight),
      tension = 0.7,
      colour = "gray35",
      alpha = 0.1,
      show.legend = FALSE
    ) +
    scale_edge_width(range = c(0.05, 0.8), guide = "none") +
    # nodes
    geom_node_point(aes(size = deg), colour = "white", stroke = 0) +
    geom_node_point(aes(size = deg, colour = populism),
                    alpha = 0.9, fill = "white", stroke = 1) +
    entoptic::scale_colour_entoptic_b(option = "firstlight", direction = 1,
                                      name   = "Populism Score Correlation",
                                      begin = 0, end = 0.8,
                                      limits = range(lookup$populism, na.rm = TRUE)) +
    scale_size_continuous(range = c(1, 4), guide = "none") +
    # text
    geom_node_text(aes(label = name), size = 8, colour = "black",
                   repel = T,
                   family = "Roboto", segment.colour = "grey50",
                   segment.size = 0.3, bg.color = "white", bg.r = 0.01) +
    # theme
    theme_graph(background = "white") +
    coord_cartesian(clip = "off") +
    theme(
      legend.text  = element_text(family = "Roboto", size = 20),
      legend.title = element_text(family = "Roboto", size = 24, lineheight = 0.35),
      legend.key.width  = unit(0.5, "cm"),
      legend.key.height = unit(1, "cm"),
      
      legend.position = "right",
      legend.justification = c(0, 0.5),
      legend.title.position = "top",
      plot.title = element_text(family = "Roboto", size = 32, hjust = 0.5),
      plot.caption = element_text(face = "plain"),
      plot.caption.position = "plot",
      text = element_text(family = "Roboto")
    ) +
    labs(title = title)
}

# === Make plots for each populism component ===
p_people <- plot_group(d |> filter(people_score > 0),
                       lookup, "Pro-People Tweets")
p_elite  <- plot_group(d |> filter(elite_score < 0),
                       lookup, "Anti-Elite Tweets")
p_antag  <- plot_group(d |> filter(antagonism_score > 0),
                       lookup, "Antagonistic Tweets")
p_other  <- plot_group(d |> filter(people_score <= 0,
                                   elite_score  >= 0,
                                   antagonism_score <= 0),
                       lookup, "Other Tweets")

plot <- (p_people + p_elite) / (p_antag + p_other) +
  plot_layout(guides = "collect") &
  theme(
    legend.position      = "bottom",
    legend.justification = "center",
    legend.key.width     = unit(1.5, "cm"),
    legend.key.height    = unit(0.4, "cm"),
    legend.title         = element_text(size = 30),
    plot.margin          = margin(2, 2, 2, 2)
  )

ggsave("../images/tfidf_wordcorrelations_populism_dimensions.png", plot,
       width = 9, height = 10, dpi = 300, bg = "white")

# === Summary of subset sizes ===
tibble(
  component = c("Pro-People Tweets", "Anti-Elite Tweets",
                "Antagonistic Tweets", "Other Tweets"),
  n_tweets  = c(sum(d$people_score     > 0, na.rm = TRUE),
                sum(d$elite_score      < 0, na.rm = TRUE),
                sum(d$antagonism_score > 0, na.rm = TRUE),
                sum(d$people_score <= 0 & d$elite_score >= 0 &
                      d$antagonism_score <= 0, na.rm = TRUE)),
  n_mps     = c(n_distinct(d$user_id[d$people_score     > 0]),
                n_distinct(d$user_id[d$elite_score      < 0]),
                n_distinct(d$user_id[d$antagonism_score > 0]),
                n_distinct(d$user_id[d$people_score <= 0 &
                                       d$elite_score  >= 0 &
                                       d$antagonism_score <= 0]))
) |> print()