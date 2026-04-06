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
