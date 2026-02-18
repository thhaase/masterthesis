library(arrow)
library(bit64)
library(tidyverse)
library(data.table)
library(igraph)
library(intergraph)
library(network)
library(sna)
library(kableExtra)

setwd("~/Github/masterthesis/analysis")
data_path <- "/home/thhaase/Documents/synosys_masterthesis"
setDTthreads(0)

# === Load Data ===
d <- read_parquet("d.parquet")
g <- readRDS("g.rds")

# === Net Descriptive Statistics ===
n_nodes  <- vcount(g)
n_edges  <- ecount(g)
deg_in   <- igraph::degree(g, mode = "in")
deg_out  <- igraph::degree(g, mode = "out")
deg      <- deg_in + deg_out
mean_deg <- mean(deg)
sd_deg   <- sd(deg)
trans    <- transitivity(g, type = "average")
dens     <- edge_density(g)
recip    <- reciprocity(g)
assort   <- assortativity_degree(g, directed = TRUE)

coreness_vals <- coreness(g, mode = "all")
max_core      <- max(coreness_vals)

set.seed(1234)
sample_nodes <- sample(V(g), size = min(100, n_nodes))
d_mat    <- distances(g, v = sample_nodes, weights = E(g)$weight, mode = "all")

avg_path <- mean(d_mat[is.finite(d_mat)])
diam <- max(d_mat[is.finite(d_mat)])

table_desc <- data.table(
  Metric = c("Nodes", "Links", "Density",
             "Mean Degree", "SD Degree",
             "Reciprocity", "Assortativity (Degree)",
             "Average Shortest Path (sampled)", "Diameter (sampled)",
             "Clustering Coefficient",
             "Max K-Core"),
  Value = round(c(n_nodes, n_edges, dens,
                  mean_deg, sd_deg,
                  recip, assort,
                  avg_path, diam,
                  trans,
                  max_core), 4)
)

kable(table_desc, format = "markdown", caption = "")
kable(table_desc,
      format = "markdown",
      caption = "") |>
  writeLines("../tables/network_structure_descriptives.md")

# === Degree Distributions ===
# Reuse deg_in / deg_out instead of recomputing
rbind(
  data.table(degree = deg_in,  type = "Indegree"),
  data.table(degree = deg_out, type = "Outdegree")
) |>
  _[degree > 0] |>
  _[, .(count = .N), by = .(degree, type)] |>
  ggplot(aes(x = degree, y = count, color = type, shape = type)) +
  geom_point(size = 2.3) +
  scale_x_log10(labels = scales::label_number()) +
  scale_y_log10(labels = scales::label_number()) +
  scale_color_manual(values = c("Indegree" = "steelblue", "Outdegree" = "salmon")) +
  scale_shape_manual(values = c("Indegree" = 16, "Outdegree" = 17)) +
  labs(title = "Largest Component: (USER) —replies—> (USER)",
       subtitle = "Degree Distribution",
       caption = "Data:\nGerman MPs Twitterposts + all replies to MPs posts + all replies to replies",
       x = "Degree (log scale)", y = "Frequency (log scale)",
       color = "Type", shape = "Type") +
  theme_bw() +
  theme(legend.position = "inside",
        legend.position.inside = c(0.9, 0.9),
        legend.background = element_rect(color = "gray44", fill = "white", linewidth = 0.4))

ggsave("../images/3-degree-distribution.png", bg = "white", width = 11, height = 6, dpi = 300)

# === Centrality Distributions ===
cent_eigen <- igraph::eigen_centrality(g, directed = T)$vector
cent_betwe <- igraph::betweenness(g, directed = T, cutoff = 5, normalized = T)

data.table(
  Degree      = deg,
  Eigenvector = cent_eigen,
  Betweenness = cent_betwe
  )[, node := .I] |>
  melt(id.vars = "node", variable.name = "type", value.name = "value") |>
  _[value > 0] |>
  _[, .(count = .N), by = .(value = round(value, 6), type)] |>
ggplot(aes(x = value, y = count)) +
  geom_point(size = 2) +
  scale_x_log10(labels = scales::label_number()) +
  scale_y_log10(labels = scales::label_number()) +
  facet_wrap(~ type, scales = "free_x") +
  labs(x = "Centrality Value (log scale)", y = "Frequency (log scale)",
       title = "Largest Component: (USER) —replies—> (USER)",
       caption = "Data:\nGerman MPs Twitterposts + all replies to MPs posts + all replies to replies",
       subtitle = "Centrality Measures") +
  theme_bw()

ggsave("../images/3-centrality-measures.png", bg = "white", width = 13, height = 5, dpi = 300)










