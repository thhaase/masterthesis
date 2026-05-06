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

# === Classify MPs by populism use ===
mp_class <- d |>
  filter(!is.na(party)) |>
  group_by(user_id) |>
  summarise(mp_pop = mean(populism_score, na.rm = TRUE), .groups = "drop") |>
  mutate(group = ifelse(mp_pop > 0, "Populist MPs", "Non-Populist MPs"))

d <- d |>
  left_join(mp_class |> select(user_id, group), by = "user_id")


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
closeness_opsahl <- function(g, alpha = 0.5, weights = NULL,
                             mode = "all", normalized = FALSE) {
  if (is.null(weights)) weights <- igraph::E(g)$weight
  if (is.null(weights)) stop("No edge weights found.")
  if (any(weights <= 0)) stop("Weights must be > 0.")
  
  # Opsahl tuning: cost of traversing an edge = (1/w)^alpha
  costs <- (1 / weights)^alpha
  
  D <- igraph::distances(g, weights = costs, mode = mode)
  diag(D) <- NA                      # exclude self
  D[is.infinite(D)] <- NA            # disconnected pairs
  
  cl <- 1 / rowSums(D, na.rm = TRUE)
  if (normalized) cl <- cl * (igraph::vcount(g) - 1)
  cl
}
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
    top_n(75, deg) |>
    left_join(lookup, by = "name")
  
set.seed(161)
gp |> 
    ggraph(layout = "centrality", 
           cent = strength(gp)) +
    # edges
    geom_edge_bundle_path0(
      aes(edge_linewidth = weight),
      tension = 0.7,
      colour = "gray35",
      alpha = 0.2,
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
    geom_node_text(aes(label = name), size = 7, colour = "black",
                   repel = T, 
                   #fontface = "bold",
                   max.overlaps = 20,
                   family = "Roboto", segment.colour = "grey50",
                   segment.size = 0.3, bg.color = "white", bg.r = 0.01) +
    # theme
    theme_graph(background = "white") +
    theme(
      legend.text  = element_text(family = "Roboto", size = 20),
      legend.title = element_text(family = "Roboto", size = 24, lineheight = 0.35),
      legend.key.width  = unit(0.5, "cm"),
      legend.key.height = unit(1, "cm"),
      
      legend.position = "right",
      legend.justification = c(0, 0.5),
      legend.title.position = "top",
      plot.title = element_text(family = "Roboto", size = 28, hjust = 0.5),
      plot.caption = element_text(face = "plain"),
      plot.caption.position = "plot",
      text = element_text(family = "Roboto")
    ) +
    labs(title = title)
}

# === Make plots ===
p_pop    <- plot_group(d |> filter(group == "Populist MPs"),     
                       lookup, "Populist MPs")
#p_pop
p_nonpop <- plot_group(d |> filter(group == "Non-Populist MPs"), 
                       lookup, "Non-Populist MPs")
#p_nonpop
plot <- p_pop + p_nonpop + plot_layout(guides = "collect") &
  theme(legend.position = "bottom",
        legend.key.width = unit(1.3,"cm"),
        legend.key.height = unit(0.5,"cm"),
        plot.margin = margin(2,2,2,2))

#plot
ggsave("../images/tfidf_wordcorrelations_split.png", plot,
       width = 8, height = 5, dpi = 300, bg = "white")

d |>
  filter(!is.na(party)) |>
  group_by(group) |>
  summarise(n_tweets = n(),
            n_mps    = n_distinct(user_id),
            .groups  = "drop") |>
  print()



