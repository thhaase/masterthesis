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

# === Data Prep ===
# create adjacency matrix
m <- as_adjacency_matrix(graph = g, attr = "weight") |> 
  as.matrix()
  

library(greed)
library(igraph)
library(Matrix)

# Get sparse adjacency matrix (no 34 GiB allocation)
M <- as_adjacency_matrix(g, attr = "weight", sparse = TRUE)

# Fit a directed weighted SBM
# DcLbm for directed, CombinedModels for weighted+directed
sol <- greed(M, model = new("DcSbm"))  # directed degree-corrected SBM

# Number of blocks chosen automatically via ICL
K <- sol@K

# Block memberships
memberships <- clustering(sol)

# Image matrix (the network abstraction you want)
# Average weight between each pair of blocks
image_matrix <- matrix(0, K, K)
el <- as_edgelist(g, names = FALSE)
w  <- E(g)$weight
for (i in seq_along(w)) {
  r <- memberships[el[i, 1]]
  c <- memberships[el[i, 2]]
  image_matrix[r, c] <- image_matrix[r, c] + w[i]
}
# Normalize by block pair sizes
block_sizes <- table(memberships)
for (r in 1:K) for (c in 1:K) {
  image_matrix[r, c] <- image_matrix[r, c] / (block_sizes[r] * block_sizes[c])
}

print(image_matrix)