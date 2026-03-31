rm(list = ls())
#.rs.restartR()

library(arrow)
library(bit64)
library(tidyverse)
library(data.table)

library(igraph)
library(kableExtra)
library(ggraph)
library(patchwork)

setwd("~/Github/masterthesis/analysis")
setDTthreads(0)

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/nets/g_full.rds")

DPI <- 300
# === Extract Egonetworks ===
politician_ids <- which(!is.na(V(g)$politician_name))

ego <- lapply(politician_ids, function(v) {
  eg <- make_ego_graph(g, order = 5, nodes = v, mode = "all")[[1]]
  screen <- V(g)$user_screen_name[v]
  keep <- sapply(strsplit(E(eg)$thread_root_user_screen_name, "\\|"), function(x) screen %in% x)
  subgraph_from_edges(eg, which(keep), delete.vertices = TRUE)
})
names(ego) <- V(g)$politician_name[politician_ids]



# helper for arrow management
normalise <- function(x, from = range(x), to = c(0, 1)) {
  x <- (x - from[1]) / (from[2] - from[1])
  if (!identical(to, c(0, 1))) {
    x <- x * (to[2] - to[1]) + to[1]
  }
  x
}


plot_ego_sparse <- function(g, 
                            title = "", 
                            layout = c("stress", "fr", "kk"),
                            gap_weight = 0.1,
                            clip_sd = 2.5,
                            fr_scaling_factor = 2) {
  
  comps <- decompose(g)
  
  # check undirected isomorphisms (same structure when undirected)
  groups <- list()
  for (comp in comps) {
    matched <- FALSE
    for (i in seq_along(groups)) {
      if (isomorphic(as.undirected(comp), as.undirected(groups[[i]]$rep))) {
        groups[[i]]$count <- groups[[i]]$count + 1
        matched <- TRUE
        break
      }
    }
    if (!matched)
      groups[[length(groups) + 1]] <- list(rep = comp, count = 1)
  }
  
  groups <- groups[order(sapply(groups, \(x) vcount(x$rep)), decreasing = TRUE)]
  
  reps   <- lapply(groups, `[[`, "rep")
  counts <- sapply(groups, `[[`, "count")
  n      <- length(reps)
  
  layout <- match.arg(layout)
  
  # individual layout for each component
  layouts <- lapply(reps, function(g) {
    if (vcount(g) == 1) return(data.frame(x = 0, y = 0))
    
    if (layout == "stress") {
      lay <- graphlayouts::layout_with_stress(g)
    } else if (layout == "fr") {
      lay <- layout_with_fr(g)
      lay <- lay * fr_scaling_factor
    } else if (layout == "kk") {
      lay <- layout_with_kk(g)
    }
    
    df <- as.data.frame(lay); names(df) <- c("x", "y")
    df$x <- df$x - mean(df$x)
    df$y <- df$y - mean(df$y)
    
    # clip outlier coordinates only for larger components
    if (!is.null(clip_sd) && nrow(df) > 6) {
      for (col in c("x", "y")) {
        m <- median(df[[col]])
        mad_val <- mad(df[[col]])
        if (mad_val > 0) {
          df[[col]] <- pmax(pmin(df[[col]], m + clip_sd * mad_val), 
                            m - clip_sd * mad_val)
        }
      }
    }
    
    df
  })
  
  # gap relative to actual component sizes, with a floor for isolate-only cases
  widths  <- sapply(layouts, function(df) diff(range(df$x)))
  heights <- sapply(layouts, function(df) diff(range(df$y)))
  raw_gap <- median(c(widths, heights)) * gap_weight
  gap     <- max(raw_gap, 1)
  
  # create grid
  ncol  <- ceiling(sqrt(n))
  cx <- 0; cy <- 0; row_h <- 0; col_i <- 0
  offsets <- vector("list", n)
  
  for (i in seq_len(n)) {
    w_i <- diff(range(layouts[[i]]$x)) + gap
    h_i <- diff(range(layouts[[i]]$y)) + gap
    
    if (col_i >= ncol) {
      cx    <- 0
      cy    <- cy - row_h - gap
      row_h <- 0
      col_i <- 0
    }
    
    offsets[[i]] <- c(cx, cy)
    cx    <- cx + w_i + gap
    row_h <- max(row_h, h_i)
    col_i <- col_i + 1
  }
  
  all_nodes <- do.call(rbind, Map(function(df, off, grp) {
    df$x <- df$x + off[1]
    df$y <- df$y + off[2]
    df$grp <- grp
    df
  }, layouts, offsets, seq_len(n)))
  
  combined <- Reduce(disjoint_union, reps)
  
  deg <- degree(combined)
  V(combined)$s   <- if (diff(range(deg)) == 0) 3.5 else normalise(deg, to = c(3, 4))
  V(combined)$grp <- rep(seq_len(n), sapply(reps, vcount))
  
  lay <- create_layout(combined, "manual", x = all_nodes$x, y = all_nodes$y)
  
  # label offset proportional to overall plot extent
  plot_span   <- max(diff(range(all_nodes$x)), diff(range(all_nodes$y)))
  label_nudge <- if (plot_span > 0) plot_span * 0.05 else 0.1
  
  # labels for components
  labels <- do.call(rbind, lapply(seq_len(n), function(i) {
    sub <- all_nodes[all_nodes$grp == i, ]
    nm  <- if (vcount(reps[[i]]) == 1) "isolate"
    else if (vcount(reps[[i]]) == 2) "dyad"
    else NULL
    lab <- if (counts[i] > 1)
      paste0(counts[i], "\u00d7", if (!is.null(nm)) paste0(" ", nm))
    else NA_character_
    data.frame(x = mean(sub$x),
               y = min(sub$y),
               label = lab)
  }))
  labels <- labels[!is.na(labels$label), ]
  
  ggraph(lay) +
    geom_edge_link(aes(end_cap = circle(node2.s + 2, "pt")),
                   edge_colour = "grey25",
                   arrow = arrow(angle = 20, length = unit(0.08, "in"),
                                 type = "closed")) +
    geom_node_point(aes(size = I(s)), col = "white") +
    geom_node_point(aes(size = I(s), alpha = s), show.legend = FALSE) +
    scale_alpha_continuous(range = c(0.4, 1)) +
    geom_text(data = labels, aes(x = x, y = y, label = label),
              size = 3.5, colour = "gray10", vjust = -1, inherit.aes = FALSE) +
    theme_graph() +
    ggtitle(title)
}

# TOP 1 Populist (not found)
name <- "Helin Evrim Sommer"
ego[[name]] |>
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |>
  plot_ego_sparse(layout = "kk")
ggsave("../images/egonet_top_1_helin_evrim_sommer.png",
       bg = "white", width = 12, height = 7, dpi = DPI)

# TOP 2 Populist
# ego[[name]] |>
#   delete_vertices(which(V(ego[[name]])$politician_name == name)) |>  
#   intergraph::asNetwork() |> network::plot.network()
name <- "Alice Elisabeth Weidel"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "kk")
ggsave("../images/egonet_top_2_alice_weidel.png",
       bg = "white", width = 12, height = 7, dpi = DPI)

# TOP 3 Populist
name <- "Peter Christian Pascal Boehringer"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "stress", gap_weight = 0.3, clip_sd = 2.0)
ggsave("../images/egonet_top_3_peter_christian_pascal_boehringer.png",
       bg = "white", width = 14, height = 9, dpi = DPI)

# TOP 4 Populist
name <- "Beatrix von Storch"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "stress", gap_weight = 0.3, clip_sd = 2.0)
ggsave("../images/egonet_top_4_beatrix_von_storch.png",
       bg = "white", width = 14, height = 9, dpi = DPI)

# TOP 5 Populist
name <- "Erik von Malottki"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "stress", gap_weight = 0.3, clip_sd = 2.0)
ggsave("../images/egonet_top_5_erik_von_malottki.png",
       bg = "white", width = 14, height = 9, dpi = DPI)

# TOP 6 Populist
name <- "Tobias Matthias Peterka"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "stress", gap_weight = 0.3, clip_sd = 2.0)
ggsave("../images/egonet_top_6_tobias_matthias_peterka.png",
       bg = "white", width = 14, height = 9, dpi = DPI)

# TOP 7 Populist
name <- "Stephan Günther Brandner"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "stress", gap_weight = 0.3, clip_sd = 2.0)
ggsave("../images/egonet_top_7_stephan_günther_brandner.png",
       bg = "white", width = 14, height = 9, dpi = DPI)

# TOP 7 Populist
name <- "Dietmar Gerhard Bartsch"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "stress", gap_weight = 0.3, clip_sd = 2.0)
ggsave("../images/egonet_top_8_dietmar_gerhard_bartsch.png",
       bg = "white", width = 14, height = 9, dpi = DPI)

# TOP 8 Populist
name <- "Sahra Wagenknecht"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "stress", gap_weight = 0.3, clip_sd = 2.0)
ggsave("../images/egonet_top_9_sahra_wagenknecht.png",
       bg = "white", width = 14, height = 9, dpi = DPI)






name <- "Christian Wolfgang Lindner"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "kk")
ggsave("../images/egonet_christian_lindner.png",
       bg = "white", width = 12, height = 7, dpi = DPI)

name <- "Katja Kipping"
ego[[name]] |> 
  delete_vertices(which(V(ego[[name]])$politician_name == name)) |> 
  plot_ego_sparse(layout = "kk")
ggsave("../images/egonet_katja_kipping.png",
       bg = "white", width = 12, height = 7, dpi = DPI)