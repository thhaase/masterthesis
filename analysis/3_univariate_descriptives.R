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

setwd("~/Github/masterthesis/analysis")
data_path <- "/home/thhaase/Documents/synosys_masterthesis"
setDTthreads(0)

# === Load Data ===
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/g.rds")
# === META ===
DPI = 300

# === Populism Descriptives ===
data.frame(
  people = V(g)$people_score,
  elite  = V(g)$elite_score,
  antag  = V(g)$antag_score
) |>
  filter(!is.na(people), !is.na(elite), !is.na(antag)) |>
  mutate(people_bin = round(people * 4) / 4, elite_bin = round(elite * 4) / 4) |>
  group_by(people_bin, elite_bin) |>
  summarise(antag = mean(antag), n = n(), .groups = "drop") |>
ggplot(aes(x = people_bin, y = elite_bin, fill = antag, alpha = n)) +
  geom_tile() +
  scale_fill_viridis_c(direction = 1) +
  scale_x_continuous(breaks = -3:3) +
  scale_y_continuous(breaks = -3:3) +
  scale_alpha_continuous(range = c(0.6, 1)) +
  coord_cartesian(xlim = c(-3, 3), ylim = c(-3, 3), clip = "off") +
  annotate("text", x = -3, y = -3.6, label = '("Against the People")', color = "gray33", size = 2.8, fontface = "italic") +
  annotate("text", x =  3, y = -3.6, label = '("For the People")',     color = "gray33", size = 2.8, fontface = "italic") +
  annotate("text", y = -3, x = -4.15, label = '("Against the Elite")',  color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
  annotate("text", y =  3, x = -4, label = '("For the Elite")',      color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
  #annotate("text", y =  3, x = -3.9, label = '  Antagonism captures the strength of opposition between The People and The Elite.',      color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
  theme_bw() +
  theme(plot.margin = margin(10, 10, 25, 30),
        axis.title.y = element_text(angle = 0, vjust = 0.5)) +
  labs(x = "People Score", y = "Elite Score", fill = "Antagonism", alpha = "Count")
ggsave("../images/populism_dimensions_person_level.png", bg = "white", width = 8.5, height = 7, dpi = DPI)

# with politicians
data.frame(
  people = V(g)$people_score,
  elite  = V(g)$elite_score,
  Antagonism  = V(g)$antag_score,
  party  = V(g)$party,
  politician_name = V(g)$politician_name,
  populism = V(g)$populism_score
) |>
  filter(!is.na(people), !is.na(elite), !is.na(Antagonism)) |>
  (\(df) {
    df_pol <- df |> filter(!is.na(party), !is.na(politician_name)) |>
      mutate(label = ifelse(rank(-populism, ties.method = "first") <= 5,
                            politician_name, NA_character_))
    
    df |>
      mutate(people_bin = round(people * 4) / 4,
             elite_bin  = round(elite  * 4) / 4) |>
      group_by(people_bin, elite_bin) |>
      summarise(Antagonism = mean(Antagonism), n = n(), .groups = "drop") |>
      ggplot(aes(x = people_bin, y = elite_bin, fill = Antagonism, alpha = n)) +
      geom_tile() +
      scale_fill_viridis_c(direction = 1) +
      scale_alpha_continuous(range = c(0.6, 1)) +
      new_scale_fill() +
      geom_point(data = df_pol,
                 aes(x = people, y = elite, fill = party),
                 shape = 21, color = "white", stroke = 0.4,
                 size = 2.5, alpha = 1,
                 position = position_jitter(width = 0.09, height = 0.09, seed = 161)) +
      geom_text_repel(data = df_pol,
                      aes(x = people, y = elite, label = label),
                      size = 2.6, bg.color = "white", bg.r = 0.1,
                      inherit.aes = FALSE,
                      position = position_jitter(width = 0.09, height = 0.09, seed = 161),
                      segment.color = "black",
                      segment.size = 0.3,
                      min.segment.length = 0,
                      box.padding = 0.4,
                      point.padding = 0.2) +
      scale_fill_manual(
        name = "Politician\nof Party",
        values = c("CDU" = "black",   "CSU"   = "navy",
                   "SPD" = "#E3000F", "Grüne" = "forestgreen",
                   "FDP" = "#FFED00", "Linke" = "#BE3075",
                   "AfD" = "#009EE0", "BSW"   = "#7D1934"),
        na.value = "gray20",
        guide = guide_legend(override.aes = list(size = 4))) +
      scale_x_continuous(breaks = -3:3) +
      scale_y_continuous(breaks = -3:3) +
      coord_cartesian(xlim = c(-3, 3), ylim = c(-3, 3), clip = "off") +
      annotate("text", x = -3, y = -3.6, label = '("Against the People")',
               color = "gray33", size = 2.8, fontface = "italic") +
      annotate("text", x =  3, y = -3.6, label = '("For the People")',
               color = "gray33", size = 2.8, fontface = "italic") +
      annotate("text", y = -3, x = -4.15, label = '("Against the Elite")',
               color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
      annotate("text", y =  3, x = -4,    label = '("For the Elite")',
               color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
      theme_bw() +
      theme(plot.margin = margin(10, 10, 25, 30),
            axis.title.y = element_text(angle = 0, vjust = 0.5)) +
      labs(x = "People Score", y = "Elite Score",
           fill = "Antagonism", alpha = "Count")
  })()
ggsave("../images/populism_dimensions_person_level_politicians.png", bg = "white", width = 8.5, height = 7, dpi = DPI)

# with politicians ZOOMED IN
data.frame(
  people = V(g)$people_score,
  elite  = V(g)$elite_score,
  Antagonism  = V(g)$antag_score,
  party  = V(g)$party,
  politician_name = V(g)$politician_name,
  populism = V(g)$populism_score
) |>
  filter(!is.na(people), !is.na(elite), !is.na(Antagonism)) |>
  (\(df) {
    df_pol <- df |> filter(!is.na(party), !is.na(politician_name)) |>
      mutate(label = ifelse(rank(-populism, ties.method = "first") <= 30,
                            politician_name, NA_character_))
    
    df |>
      mutate(people_bin = round(people * 8) / 8,
             elite_bin  = round(elite  * 8) / 8) |>
      group_by(people_bin, elite_bin) |>
      summarise(Antagonism = mean(Antagonism), n = n(), .groups = "drop") |>
      ggplot(aes(x = people_bin, y = elite_bin, fill = Antagonism, alpha = n)) +
      geom_tile() +
      scale_fill_viridis_c(direction = 1) +
      scale_alpha_continuous(range = c(0.2, 0.5)) +
      new_scale_fill() +
      geom_point(data = df_pol,
                 aes(x = people, y = elite, fill = party),
                 shape = 21, color = "white", stroke = 0.4,
                 #position = position_jitter(width = 0.009, height = 0.009, seed = 161),
                 size = 5, alpha = 0.75) +
      geom_text_repel(data = df_pol,
                      aes(x = people, y = elite, label = label),
                      size = 3.2, bg.color = "white", bg.r = 0.1,
                      inherit.aes = FALSE,
                      #position = position_jitter(width = 0.09, height = 0.09, seed = 161),
                      segment.color = "black",
                      segment.size = 0.3,
                      min.segment.length = 0,
                      box.padding = 0.4,
                      point.padding = 0.2) +
      scale_fill_manual(
        name = "Politician\nof Party",
        values = c("CDU" = "black",   "CSU"   = "navy",
                   "SPD" = "#E3000F", "Grüne" = "forestgreen",
                   "FDP" = "#FFED00", "Linke" = "#BE3075",
                   "AfD" = "#009EE0", "BSW"   = "#7D1934"),
        na.value = "gray20",
        guide = guide_legend(override.aes = list(size = 4))) +
      # Modified scales for better axis reading inside the zoom
      scale_x_continuous(breaks = -3:3) +
      scale_y_continuous(breaks = -3:3) +
      # --- ZOOMED IN HERE ---
      coord_cartesian(xlim = c(-0.1, 1.1), ylim = c(-2, 0.1), clip = "on") +
      # Adjusted the annotations to match the new coord limits
      annotate("text", x = -0.5, y = -2.8, label = '("Against the People")',
               color = "gray33", size = 2.8, fontface = "italic") +
      annotate("text", x =  1.5, y = -2.8, label = '("For the People")',
               color = "gray33", size = 2.8, fontface = "italic") +
      annotate("text", y = -2.5, x = -0.9, label = '("Against the Elite")',
               color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
      annotate("text", y =  0.5, x = -0.9,  label = '("For the Elite")',
               color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
      theme_bw() +
      # Slightly increased the left plot margin (changed 30 to 45) to fit the adjusted text annotations
      theme(plot.margin = margin(10, 10, 25, 45),
            axis.title.y = element_text(angle = 0, vjust = 0.5)) +
      labs(x = "People Score", y = "Elite Score",
           fill = "Antagonism", alpha = "Count")
  })()
ggsave("../images/populism_dimensions_person_level_politicians.png", bg = "white", width = 8.5, height = 7, dpi = DPI)

paste0(round(sum(V(g)$populism_score > 0,na.rm = T)/length(V(g)$populism_score),2)*100,"% of Users have a populism score above zero") |> cat()
# data.frame(
#   people = V(g)$people_score,
#   elite  = V(g)$elite_score,
#   antag  = V(g)$antag_score
# ) |>
#   filter(!is.na(people), !is.na(elite), !is.na(antag)) |>
#   mutate(people_bin = round(people * 4) / 4,
#          elite_bin  = round(elite  * 4) / 4) |>
#   group_by(people_bin, elite_bin) |>
#   summarise(antag = mean(antag), n = n(), .groups = "drop") |>
#   (\(d) {
#     base <- ggplot(d, aes(x = people_bin, y = elite_bin)) +
#       scale_x_continuous(limits = c(-3, 3), breaks = -3:3) +
#       scale_y_continuous(limits = c(-3, 3), breaks = -3:3) +
#       coord_equal() +
#       theme_bw(base_size = 14) +
#       theme(
#         legend.position = "none",
#         plot.margin = margin(10, 10, 10, 10),
#         aspect.ratio = 1
#       ) +
#       labs(x = "People Score", y = "Elite Score")
#     
#     p_col <- base +
#       geom_tile(aes(fill = antag), width = 0.25, height = 0.25) +
#       scale_fill_viridis_c(direction = 1)
#     
#     p_height <- base +
#       geom_tile(aes(fill = n^0.25), width = 0.25, height = 0.25)
#     
#     plot_gg(p_col,
#             ggobj_height = p_height,
#             width = 4, height = 4,
#             scale = 100,
#             multicore = TRUE,
#             shadow_intensity = 0.2,
#             offset_edges = TRUE,
#             theta = -20, phi = 30, zoom = 0.70,
#             windowsize = c(600, 600))
#     
#     render_highquality(
#       filename = "../images/populism_3d.png",
#       samples = 256,
#       light = TRUE,
#       lightdirection = c(135, 225),
#       lightaltitude = c(45, 30),
#       lightintensity = c(480, 150),
#       lightcolor = c("white", "#ffeedd"),
#       width = 2000, height = 2000
#     )
#   })()
#
# legend_plot <- data.frame(
#   people = V(g)$people_score,
#   elite  = V(g)$elite_score,
#   antag  = V(g)$antag_score
# ) |>
#   filter(!is.na(people), !is.na(elite), !is.na(antag)) |>
#   mutate(people_bin = round(people * 4) / 4,
#          elite_bin  = round(elite  * 4) / 4) |>
#   group_by(people_bin, elite_bin) |>
#   summarise(antag = mean(antag), n = n(), .groups = "drop") |>
#   ggplot(aes(x = people_bin, y = elite_bin, fill = antag)) +
#   geom_tile() +
#   scale_fill_viridis_c(direction = 1, name = "Antagonism") +
#   theme(
#     legend.background = element_rect(fill = "white", colour = "black", linewidth = 0.5),
#     legend.margin = margin(6, 6, 6, 6)
#   )
# 
# leg <- cowplot::get_legend(legend_plot)
# 
# img <- ggdraw() +
#   draw_image("../images/populism_3d.png") +
#   draw_plot(leg, x = 0.85, y = 0.55, width = 0.15, height = 0.3)
# 
# ggsave("../images/populism_3d_final.png", img, width = 10, height = 10)




# === Net Descriptive Statistics ===
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
library(future.apply)
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
  scale_color_manual(values = c("Indegree" = "steelblue4", "Outdegree" = "tomato2")) +
  scale_shape_manual(values = c("Indegree" = 16, "Outdegree" = 17)) +
  labs(title = "Replynetwork: Largest Component",
       subtitle = "Degree Distribution",
       caption = "Data:\nGerman MPs Twitterposts + all replies to MPs posts + all replies to replies",
       x = "Degree (log scale)", y = "Frequency (log scale)",
       color = "Type", shape = "Type") +
  theme_bw() + theme(panel.grid = element_blank()) + 
  annotation_logticks(sides = "trbl", short = unit(0.075, "cm"),
                      mid = unit(0.15, "cm"), long = unit(0.175, "cm")) +
  theme(legend.position = "inside",
        legend.position.inside = c(0.92, 0.88),
        legend.background = element_rect(color = "gray44", fill = "white", linewidth = 0.4))
ggsave("../images/3-degree-distribution.png", bg = "white", width = 10, height = 6, dpi = DPI)

# looks quite hierarchical, lets test barabasis hierarchical network model
data.frame(
  degree = igraph::degree(g),
  clustering = igraph::transitivity(g, type = "local")
) |> 
  filter(degree > 1 & !is.na(clustering) & clustering > 0) |> 
  ggplot(aes(x = degree, y = clustering)) + 
  geom_point(alpha = 0.6, size = 1.5, 
             position = position_jitter(width = 0.2, height = 0.2,
                                        seed = 161)) +
  geom_smooth(method = "lm", color = "black", linewidth = 0.5, 
              se = FALSE, linetype = "dashed") + 
  scale_x_log10(labels = scales::label_log()) + 
  scale_y_log10(labels = scales::label_log()) +
  labs(
    title = "Degree vs. Local Clustering",
    subtitle = "Test Barabasi Hierarchical Model: arXiv:cond-mat/0206130",
    x = "Degree (k)",
    y = "Local Clustering C(k)" 
  ) +
  theme_bw() + theme(panel.grid = element_blank()) + 
  annotation_logticks(sides = "trbl", short = unit(0.075, "cm"),
                      mid = unit(0.15, "cm"), long = unit(0.175, "cm"))
ggsave("../images/3-degree-vs-clustering.png", bg = "white", width = 10, height = 6, dpi = DPI)


# === Centrality Distributions ===

tibble(
  Degree      = igraph::degree(g, mode = "all"),
  Eigenvector = igraph::eigen_centrality(g, directed = T)$vector,
  #PageRank    = igraph::page_rank(g, directed = T)$vector,
  Betweenness = igraph::betweenness(g, directed = T)
) |> 
  mutate(node = row_number()) |> 
  pivot_longer(
    cols = -node, 
    names_to = "type", 
    values_to = "value"
  ) |> 
#  filter(value > 0) |> 
  # bin for logarithmic plot
  # mutate(value = if_else(
  #   type == "Degree", 
  #   as.numeric(value),                 
  #   10^(round(log10(value), 2))
  # )) |>
  count(type, value, name = "count") |>
ggplot(aes(x = value, y = count)) +
  geom_point(alpha = 1, size = 1.3, color = "black") +
  scale_x_log10(labels = scales::label_log()) +
  scale_y_log10(labels = scales::label_log()) +
  facet_wrap(~ type, scales = "free_x") +
  labs(
    x = "Centrality Value (log scale)", 
    y = "Frequency (log scale)",
    title = "Reply Network: Largest Component",
    subtitle = "Centrality Distributions"
  ) +
  theme_bw() + theme(panel.grid = element_blank(), 
                     strip.background = element_rect(fill = "white"),
                     strip.text = element_text(face = "bold", size = 9)) + 
  annotation_logticks(sides = "trbl", short = unit(0.075, "cm"),
                      mid = unit(0.15, "cm"), long = unit(0.175, "cm"))
#ggsave("../images/3-centrality-measures.png", bg = "white", width = 13, height = 5, dpi = DPI)












# peel
g_core <- g
# UNCOMMENT FOR ITERATIVE K CORE DECOMPOSITION
# for (i in 1:1) {
#   deg <- igraph::degree(g_core)
#   g_core <- induced_subgraph(g_core, V(g_core)[deg > 1])
# }
V(g_core)$deg <- igraph::degree(g_core)


# layout
has_party <- which(!is.na(V(g_core)$party))
ranked <- has_party[order(V(g_core)$deg[has_party], decreasing = TRUE)]
# compute layout first, then filter spatially
set.seed(161)
lay <- create_layout(g_core, layout = "drl", 
                     options = list(liquid.attraction=0,
                                    expansion.attraction=0,
                                    cooldown.attraction=0,
                                    crunch.attraction=0,
                                    simmer.attraction=0.005,
                                    edge.cut = 0.885,
                                    use.seed=161))
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
                 size = 2.7, repel = TRUE, 
                 bg.color = "white", bg.r = 0.1) +
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

ggsave("../images/network.png", bg = "white", width = 10, height = 10, dpi = DPI)


