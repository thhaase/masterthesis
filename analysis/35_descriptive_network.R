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
setDTthreads(0)

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/nets/g.rds") # largest component
#g <- readRDS("../data/g_full.rds")
# === META ===
DPI = 300

# === Net Descriptive Statistics ===
# Set TRUE to calculate ressourceintense statistics
if(FALSE){
  library(future.apply)
  
  deg      <- igraph::degree(g, mode = "all")
  mean_deg <- mean(deg)
  sd_deg   <- sd(deg)
  trans    <- transitivity(g, type = "average")
  dens     <- edge_density(g)
  recip    <- reciprocity(g)
  assort   <- assortativity_degree(g, directed = TRUE)
  coreness_vals <- coreness(g, mode = "all")
  max_core      <- max(coreness_vals)
  
  # calculate distances for large network in parallel
  plan(multisession) 
  stats <- future_sapply(V(g), function(v) {
    d <- distances(g, v = v, weights = E(g)$weight, mode = "all")
    d <- d[is.finite(d)]
    c(sum = sum(d), count = length(d), mx = if(length(d) > 0) max(d) else -Inf)
  })
  avg_path <- sum(stats["sum", ]) / sum(stats["count", ])
  diam     <- max(stats["mx", ])
  
  # walktrap modularity
  mod <- modularity(cluster_walktrap(g, weights = E(g)$weight))
  
  table_desc <- data.table(
    Metric = c("Nodes", "Links", 
               "Density",
               "Mean Degree", 
               "SD Degree",
               "Reciprocity", 
               "Assortativity (Degree)",
               "Average Shortest Path", 
               "Diameter",
               "Clustering Coefficient",
               "Max K-Core",
               "Modularity (Walktrap)"),
    Value = c(
      # round decimals in table
      sprintf("%.0f", vcount(g)),    
      sprintf("%.0f", ecount(g)),    
      sprintf("%.4f", dens),       
      sprintf("%.2f", mean_deg),   
      sprintf("%.2f", sd_deg),     
      sprintf("%.4f", recip),      
      sprintf("%.3f", assort),     
      sprintf("%.2f", avg_path),   
      sprintf("%.0f", diam),       
      sprintf("%.3f", trans),      
      sprintf("%.0f", max_core),   
      sprintf("%.3f", mod)         
    )
  )
  
  kable(table_desc, format = "markdown", caption = "")
  kable(table_desc,
        format = "markdown",
        caption = "") |>
    writeLines("../tables/network_structure_descriptives.md")
}

# === Degree Distributions ===

rbind(
  data.table(degree = igraph::degree(g, mode = "in"),  type = "Indegree"),
  data.table(degree = igraph::degree(g, mode = "out"), type = "Outdegree")
) |>
  _[degree > 0] |>
  _[, .(count = .N), by = .(degree, type)] |>
  ggplot(aes(x = degree, y = count, 
             color = type, 
             shape = type)) +
  geom_point(size = 2.3) +
  scale_x_log10(labels = scales::label_log()) +
  scale_y_log10(labels = scales::label_log()) +
  #scale_color_manual(values = c("Indegree" = viridis::viridis(1, begin = 0.1), "Outdegree" = viridis::viridis(1, begin = 0.6))) +  
  #scale_color_manual(values = c("Indegree" = "steelblue4", "Outdegree" = "tomato2")) +
  scale_shape_manual(values = c("Indegree" = 16, "Outdegree" = 17)) +
  entoptic::scale_color_entoptic_d(option = "firstlight", begin = 0.15, end = 0.45, direction = -1) +
  labs(#title = "Replynetwork: Largest Component",
    #subtitle = "Degree Distribution",
    #caption = "Data:\nGerman MPs Twitterposts + all replies to MPs posts + all replies to replies",
    x = "Degree (log scale)", y = "Frequency (log scale)",
    color = "Type", shape = "Type") +
  theme_bw() + theme(panel.grid = element_blank()) + 
  annotation_logticks(sides = "trbl", short = unit(0.075, "cm"),
                      mid = unit(0.15, "cm"), long = unit(0.175, "cm")) +
  theme(legend.position = "inside",
        legend.position.inside = c(0.9, 0.84),
        legend.background = element_rect(color = "gray44", fill = "white", linewidth = 0.4))
ggsave("../images/3-degree-distribution.png", bg = "white", width = 7.5, height = 4, dpi = DPI)
