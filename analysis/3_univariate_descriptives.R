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
setwd("~/Github/masterthesis/analysis")
data_path <- "/home/thhaase/Documents/synosys_masterthesis"
setDTthreads(0)

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/g.rds")

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
sample_nodes <- sample(V(g), size = min(1000, n_nodes))
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


# Content variables

vertex_attr_names(g)
edge_attr_names(g)











# peel
g_core <- g
for (i in 1:1) {
  deg <- igraph::degree(g_core)
  g_core <- induced_subgraph(g_core, V(g_core)[deg > 1])
}
V(g_core)$deg <- igraph::degree(g_core)


# layout
has_party <- which(!is.na(V(g_core)$party))
ranked <- has_party[order(V(g_core)$deg[has_party], decreasing = TRUE)]
# compute layout first, then filter spatially
set.seed(22)
lay <- create_layout(g_core, layout = "drl", 
                     options = list(liquid.attraction=0,
                                    expansion.attraction=0,
                                    cooldown.attraction=0,
                                    crunch.attraction=0,
                                    simmer.attraction=0.005,
                                    edge.cut = 0.885,
                                    use.seed=22))
# greedily pick top-degree politicians that aren't too close together
picked <- c()
min_dist <- 0.05 * diff(range(lay$x))  # adjust multiplier for spacing

for (id in ranked) {
  if (length(picked) == 0 || 
      all(sqrt((lay$x[id] - lay$x[picked])^2 + (lay$y[id] - lay$y[picked])^2) > min_dist)) {
    picked <- c(picked, id)
  }
  if (length(picked) >= 22) break
}

V(g_core)$label <- NA
V(g_core)$label[picked] <- V(g_core)$politician_name[picked]



# plot
V(g_core)$deg <- igraph::degree(g_core)

ggraph(g_core, layout = "drl", options = list(liquid.attraction=0,
                                              expansion.attraction=0,
                                              cooldown.attraction=0,
                                              crunch.attraction=0,
                                              simmer.attraction=0.005,
                                              edge.cut = 0.885,
                                              use.seed=161)) +
  geom_edge_bundle_force(color = "gray40", 
                          alpha = 0.1, 
                         n_cycle = 1, threshold = 0.3) +
  geom_node_point(data = function(x) filter(x, is.na(V(g_core)$party)),
                  aes(size = deg), 
                  color = "gray10", shape = 19, alpha = 0.5) +
  geom_node_point(data = function(x) filter(x, !is.na(V(g_core)$party)),
                  aes(size = deg, fill = party), 
                  shape = 21, color = "white", stroke = 0.4, alpha = 1) +
  geom_node_text(aes(label = label), 
                 size = 2.5, repel = TRUE,
                 bg.color = "white", bg.r = 0.15) +
  scale_size_continuous(name = "Degree", range = c(1, 5)) +
  scale_fill_manual(name = "Politician of Party", 
                    values = c("CDU"="black", "CSU"  = "navy",
                               "SPD"="#E3000F", "Grüne"= "forestgreen",
                               "FDP"="#FFED00", "Linke"= "#BE3075",
                               "AfD"="#009EE0", "BSW"  = "#7D1934"), 
                    na.value = "gray20",
                    guide = guide_legend(override.aes = list(size = 4))) +
  scale_edge_width_continuous(range = c(0.5,3)) +
  theme_void() +
  theme(legend.position = "bottom",
        legend.title.position = "top",
        legend.title = element_text(face="bold"),
        legend.text.position = "left")

