rm(list = ls())
#.rs.restartR()

library(arrow)
library(bit64)

library(igraph)

library(ergm.ego)
library(ergm)
set.seed(1)

setwd("~/Github/masterthesis/analysis")
data_path <- "/home/thhaase/Documents/synosys_masterthesis"

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/g.rds")

# === Prepare Data ===






# === Run Models===

# === Model Base ===

# === Model H1 ===

# === Model H2 ===