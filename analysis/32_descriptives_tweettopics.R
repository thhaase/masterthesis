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

#example tweets
d |>
  filter(!is.na(party)) |>
  select(text, populism_score, user_screen_name, party) |>
  slice_max(populism_score, n = 10)

# Internal Validity

d |> 
  select(people_score, elite_score, antagonism_score, populism_score) |>
  mutate(elite_score = -elite_score) |> 
  drop_na() |> 
  cov(method = "pearson") |> 
  round(3) 

d |> 
  select(people_score, elite_score, antagonism_score, populism_score) |>
  mutate(elite_score = -elite_score) |> 
  drop_na() |> 
  cor() |> 
  round(3) 

d |> 
  select(people_score, elite_score, antagonism_score) |> 
  mutate(elite_score = -elite_score) |> 
  drop_na() |> 
  psych::alpha()


lm(retweet_count ~ people_score * antagonism_score, data = d) |> 
summary()

library(sjPlot)

plot_model(lm(like_count ~ people_score * antagonism_score, data = d), 
           type = "int") +
  theme_minimal() +
  labs(title = "Moderationseffekt von Antagonismus auf People-Centrism")

library(MASS)
# Negative Binomial Regression
glm.nb(reply_count ~ people_score * antagonism_score, data = d) |> 
  summary()

library(pscl)
# hurdle() kombiniert Logit (für die 0) und truncated NegBin (für den Rest)
model <- hurdle(reply_count ~ people_score * antagonism_score |
         people_score * antagonism_score,
       dist = "negbin", data = d) 
summary(model)
library(ggplot2)
library(broom)

# Koeffizienten extrahieren
tidy_hurdle <- tidy(model) |> 
  filter(term != "(Intercept)", term != "Log(theta)")

# Plot erstellen
ggplot(tidy_hurdle, aes(x = estimate, y = term, color = component)) +
  geom_vline(xintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_point(size = 3) +
  geom_errorbarh(aes(xmin = estimate - 1.96 * std.error, 
                     xmax = estimate + 1.96 * std.error), height = 0.2) +
  facet_wrap(~component, scales = "free_x") +
  theme_minimal() +
  labs(title = "Forest Plot: Hurdle Model Koeffizienten",
       subtitle = "Vergleich der Wahrscheinlichkeit (zero) vs. Intensität (count)",
       x = "Estimate (mit 95% Konfidenzintervall)",
       y = "")

# back to text analysis
corp <- corpus(d$text,
               docvars = d[,-5])



if(file.exists("../data/tokens_d.rds")){
  cat("\nLoading tokens ...")
  toks <- readRDS("../data/tokens_d.rds")
} else {
  cat("Creating tokens obj")
  
  toks <- corp |> 
    tokens(remove_punct = T,
           remove_numbers = T,
           remove_symbols = T,
           remove_separators = T)
  saveRDS(toks, "../data/tokens_d.rds")

}


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

# Now FCM is built on raw co-occurrence counts
fcm <- fcm(dfm)

m <- fcm |> as("dgCMatrix")


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
# Network Plot

g <- fcm |> 
  igraph::graph_from_adjacency_matrix(weighted = TRUE) |>
  as_tbl_graph()


is_acyclic(g)
is_directed(g)

gp <- g |>
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

# compute layout 
set.seed(161)
lay <- create_layout(gp, layout = "drl",
                     options = list(
                       edge.cut             = 0.45,
                       liquid.attraction    = 0.01,
                       
                       expansion.iterations = 400,
                       expansion.temperature = 7000,
                       expansion.attraction = 0,
                       expansion.damping.mult = 1,
                       
                       cooldown.attraction  = 0.3,
                       crunch.attraction    = 0.6,
                       simmer.attraction    = 0.08,
                       crunch.iterations    = 140,
                       use.seed = 161
                     ))
# # 75nodes
# lay <- create_layout(gp, layout = "drl",
#                      options = list(
#                        edge.cut             = 0.95,
#                        liquid.attraction    = 0,
#                        expansion.attraction = 0,
#                        cooldown.attraction  = 0.3,
#                        crunch.attraction    = 0.6,
#                        simmer.attraction    = 0.08,
#                        crunch.iterations    = 100,
#                        use.seed = 161
#                      ))
plot <- gp |> 
  #ggraph(layout = "manual", x = lay$x, y = lay$y) +
  ggraph(layout = "centrality", 
         cent = closeness(gp)) + #strength, closeness, betweenness
  # edges
  geom_edge_bundle_path0(
    aes(edge_linewidth = weight),
    tension = 0.75,
    #colour = "grey80",
    
    #tension = 0.7,
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
                                    name   = "Populism Score\nCorrelation",
                                    begin = 0, end = 0.8) +
  scale_size_continuous(range = c(1, 4), guide = "none") +
# text
  geom_node_text(aes(label = name), size = 6, colour = "black",
                 repel = T, #max.overlaps = 20,
                 family = "Roboto", segment.colour = "grey50",
                 segment.size = 0.3, bg.color = "white", bg.r = 0.075) +
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
    plot.caption = element_text(face = "plain"),
    plot.caption.position = "plot",
    text = element_text(family = "Roboto"),
    plot.margin = margin(2,2,2,2)
  )
plot
ggsave("../images/tfidf_wordcorrelations.png", plot,
       width = 6.5, height = 4.5, dpi = 300, bg = "white")




