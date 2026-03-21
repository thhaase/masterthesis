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

setwd("~/Github/masterthesis/analysis")
data_path <- "/home/thhaase/Documents/synosys_masterthesis"
setDTthreads(0)

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/g.rds")

# === Extract Egonetworks ===
politician_ids <- which(!is.na(V(g)$politician_name))

ego <- lapply(politician_ids, function(v) {
  eg <- make_ego_graph(g, order = 5, nodes = v, mode = "all")[[1]]
  screen <- V(g)$user_screen_name[v]
  keep <- sapply(strsplit(E(eg)$thread_root_user_screen_name, "\\|"), function(x) screen %in% x)
  subgraph_from_edges(eg, which(keep), delete.vertices = TRUE)
})
names(ego) <- V(g)$politician_name[politician_ids]


egonetwork <- ego[["Christian Wolfgang Lindner"]] |> (\(g) delete_vertices(g, which(V(g)$politician_name == "Christian Wolfgang Lindner")))()|> (\(g) delete_vertices(g, which(igraph::degree(g) == 0)))()

egonetwork <- ego[["Alice Elisabeth Weidel"]] |> (\(g) delete_vertices(g, which(V(g)$politician_name == "Alice Elisabeth Weidel")))()
egonetwork <- ego[["Katja Kipping"]] |> (\(g) delete_vertices(g, which(V(g)$politician_name == "Katja Kipping")))()
egonetwork <- ego[["Sahra Wagenknecht"]] |> (\(g) delete_vertices(g, which(V(g)$politician_name == "Sahra Wagenknecht")))() 

# helper for arrow management
normalise <- function(x, from = range(x), to = c(0, 1)) {
  x <- (x - from[1]) / (from[2] - from[1])
  if (!identical(to, c(0, 1))) {
    x <- x * (to[2] - to[1]) + to[1]
  }
  x
}
# Store degree for arrow
V(egonetwork)$degree <- normalise(igraph::degree(egonetwork), to = c(3, 11))
# Store degree for alpha (set floor to see isolates)
V(egonetwork)$deg <- pmax(igraph::degree(egonetwork), 1)
egonetwork |>
  ggraph(layout = "fr", weight = E(egonetwork)$weight, niter = 1000) +
  geom_edge_link(aes(end_cap = circle(node2.degree, "pt")),
                 color = "gray60",
                 arrow = arrow(angle = 15, length = unit(0.015, "native"),
                               ends = "last", type = "closed")) +
  geom_node_point(aes(size  = deg), 
                  col = "white") +
  geom_node_point(aes(size  = deg,
                      alpha = deg)) +
  scale_size(range = c(2, 8)) +
  scale_alpha(range = c(0.5, 1)) +
  theme_graph() + theme(legend.position = "none")


