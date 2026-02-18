library(reticulate)
library(arrow)
library(bit64)
library(tidyverse)
library(data.table)
library(igraph)
library(intergraph)
library(network)
library(sna)
library(kableExtra)

use_python("/home/thhaase/miniforge3/envs/master_thesis/bin/python", required = TRUE)

setwd("~/Github/masterthesis/analysis")
data_path <- "/home/thhaase/Documents/synosys_masterthesis"
setDTthreads(0)

# === Load Data ===
d <- read_parquet("d.parquet")
g <- readRDS("g.rds")


gt <- import("graph_tool.all")



# Extract edgelist and weights from igraph
el <- as_edgelist(g, names = FALSE)  # numeric node IDs
w  <- E(g)$weight

# Build graph-tool graph
gtg <- gt$Graph(directed = TRUE)
gtg$add_vertex(as.integer(vcount(g)))

# Add edges in bulk
el_py <- r_to_py(el - 1L)  # 0-indexed for Python
gtg$add_edge_list(el_py)

# Add weight property
eprop <- gtg$new_edge_property("double")
eprop$a <- w
gtg$ep[["weight"]] <- eprop

# Fit the SBM (this should handle 68K nodes fine)
state <- gt$minimize_blockmodel_dl(
  gtg,
  state_args = py_dict(
    list("recs", "rec_types"),
    list(list(eprop), list("real-normal"))
  )
)

# Extract results
memberships <- state$get_blocks()$a + 1L  # back to R 1-indexed
K <- length(unique(memberships))
cat("Found", K, "blocks\n")