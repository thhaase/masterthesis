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
d <- read_parquet("../data/d.parquet")
g <- readRDS("../data/nets/g.rds") # largest component
#g <- readRDS("../data/g_full.rds")
# === META ===
DPI = 300



# === Populism Descriptives ===
data.frame(
  people = V(g)$people_score,
  elite  = V(g)$elite_score,
  antag  = V(g)$antag_score
) |> nrow()
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
  #scale_fill_viridis_c(direction = 1) +
  entoptic::scale_fill_entoptic_c(end = 0.85) +
  scale_x_continuous(breaks = -3:3) +
  scale_y_continuous(breaks = -3:3) +
  scale_alpha_continuous(range = c(0.65, 1)) +
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
      #scale_fill_viridis_c(direction = 1) +
      entoptic::scale_fill_entoptic_c(end = 0.85) +
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
    df_pol <- df |> 
      filter(!is.na(party), !is.na(politician_name)) |>
      # Identify extremes: Top 30 Populism, and Top/Bottom 10 for both People and Elite axes
      mutate(label = ifelse(
        rank(-populism, ties.method = "first") <= 10 | 
        rank(-people,   ties.method = "first") <= 10 | 
        rank(people,    ties.method = "first") <= 15 | 
        rank(-elite,    ties.method = "first") <= 15 | 
        rank(elite,     ties.method = "first") <= 10,
        politician_name, NA_character_))
    
    df |>
      mutate(people_bin = round(people * 16) / 16,
             elite_bin  = round(elite  * 16) / 16) |>
      group_by(people_bin, elite_bin) |>
      summarise(Antagonism = mean(Antagonism), n = n(), .groups = "drop") |>
      ggplot(aes(x = people_bin, y = elite_bin, fill = Antagonism, alpha = n)) +
      geom_tile() +
      #scale_fill_viridis_c(direction = 1) +
      entoptic::scale_fill_entoptic_c(end = 0.85) +
      scale_alpha_continuous(range = c(0.45, 0.8)) +
      new_scale_fill() +
      geom_point(data = df_pol,
                 aes(x = people, y = elite, fill = party),
                 shape = 21, color = "grey11", stroke = 0,
                 size = 6, alpha = 1, position = position_jitter(0.01,0.01)) +
      geom_text_repel(data = df_pol,
                      aes(x = people, y = elite, label = label),
                      size = 3.2, bg.color = "white", bg.r = 0.1,
                      inherit.aes = FALSE,
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
      scale_x_continuous(breaks = seq(-3, 3, by = 0.5)) +
      scale_y_continuous(breaks = seq(-3, 3, by = 0.5)) +
      coord_cartesian(xlim = c(-0.05, 1), ylim = c(-1.5, 0), clip = "on") +
      annotate("text", x = -0.5, y = -2.8, label = '("Against the People")',
               color = "gray33", size = 2.8, fontface = "italic") +
      annotate("text", x =  1.5, y = -2.8, label = '("For the People")',
               color = "gray33", size = 2.8, fontface = "italic") +
      annotate("text", y = -2.5, x = -0.9, label = '("Against the Elite")',
               color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
      annotate("text", y =  0.5, x = -0.9,  label = '("For the Elite")',
               color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
      theme_bw() +
      theme(plot.margin = margin(10, 10, 25, 45),
            axis.title.y = element_text(angle = 0, vjust = 0.5)) +
      labs(x = "People Score", y = "Elite Score",
           fill = "Antagonism", alpha = "Count")
  })()
ggsave("../images/populism_dimensions_person_level_politicians_zoomed.png", bg = "white", width = 8.5, height = 7, dpi = DPI)


# ZOOOOOMMMMM
df_all <- data.frame(
  people = V(g)$people_score,
  elite  = V(g)$elite_score,
  Antagonism = V(g)$antag_score,
  party  = V(g)$party,
  politician_name = V(g)$politician_name,
  populism = V(g)$populism_score
) |>
  filter(!is.na(people), !is.na(elite), !is.na(Antagonism))

df_pol <- df_all |>
  filter(!is.na(party), !is.na(politician_name))

df_pol_labeled <- df_pol |>
  mutate(label = ifelse(
    rank(-populism, ties.method = "first") <= 5 |
      rank(-people,   ties.method = "first") <= 5 |
      rank(people,    ties.method = "first") <= 5 |
      rank(-elite,    ties.method = "first") <= 5 |
      rank(elite,     ties.method = "first") <= 5,
    politician_name, NA_character_))

BINS = 4
df_tile <- df_all |>
  mutate(people_bin = round(people * BINS) / BINS,
         elite_bin  = round(elite  * BINS) / BINS) |>
  group_by(people_bin, elite_bin) |>
  summarise(Antagonism = mean(Antagonism), n = n(), .groups = "drop")

df_tile_zoom <- df_all |>
  mutate(people_bin = round(people * BINS) / BINS,
         elite_bin  = round(elite  * BINS) / BINS) |>
  group_by(people_bin, elite_bin) |>
  summarise(Antagonism = mean(Antagonism), n = n(), .groups = "drop")

party_colors <- c("CDU" = "black",   "CSU"   = "navy",
                  "SPD" = "#E3000F", "Grüne" = "forestgreen",
                  "FDP" = "#FFED00", "Linke" = "#BE3075",
                  "AfD" = "#009EE0", "BSW"   = "#7D1934")

XMIN = 0
XMAX = 1.5
YMIN = -2
YMAX = 0

p_main <- ggplot(df_tile, aes(x = people_bin, y = elite_bin, fill = Antagonism, alpha = n)) +
  geom_tile() +
  entoptic::scale_fill_entoptic_c(end = 0.9) +
  scale_alpha_continuous(range = c(0.6, 1)) +
  new_scale_fill() +
  geom_point(data = df_pol_labeled,
             aes(x = people, y = elite, fill = party),
             shape = 21, color = "white", stroke = 0.1,
             size = 2, alpha = 0.75, position = position_jitter(0.01, 0.01)) +
  scale_fill_manual(values = party_colors, na.value = "gray20") +
  annotate("rect",
           xmin = XMIN, xmax = XMAX, ymin = YMIN, ymax = YMAX,
           fill = NA, color = "grey10", linewidth = 0.3, linetype = "dashed") +
  annotate("segment", color = "grey10", linewidth = 0.2, linetype = "dashed",
           x = XMIN, xend = -3,
           y = YMIN, yend = -0.25) +
  annotate("segment", color = "grey10", linewidth = 0.2, linetype = "dashed",
           x = XMAX, xend = -0.3,
           y = YMAX, yend = 3) +
  scale_x_continuous(breaks = -3:3) +
  scale_y_continuous(breaks = -3:3) +
  coord_cartesian(xlim = c(-3, 3), ylim = c(-3, 3), clip = "off") +
  annotate("text", x = -3, y = -3.6, label = '("Against the People")',
           color = "gray33", size = 2.8, fontface = "italic") +
  annotate("text", x =  3, y = -3.6, label = '("For the People")',
           color = "gray33", size = 2.8, fontface = "italic") +
  annotate("text", y = -3, x = -4.15, label = '("Against the Elite")',
           color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
  annotate("text", y =  3, x = -4, label = '("For the Elite")',
           color = "gray33", size = 2.8, fontface = "italic", angle = 0) +
  theme_bw() +
  theme(plot.margin = margin(10, 10, 25, 30),
        axis.title.y = element_text(angle = 0, vjust = 0.5)) +
  labs(x = "People Score", y = "Elite Score",
       fill = "Party", alpha = "Count")

p_inset <- ggplot(df_tile_zoom, aes(x = people_bin, y = elite_bin, fill = Antagonism, alpha = n)) +
  geom_tile() +
  entoptic::scale_fill_entoptic_c(end = 0.9) +
  scale_alpha_continuous(range = c(0.45, 0.8)) +
  new_scale_fill() +
  geom_point(data = df_pol_labeled,
             aes(x = people, y = elite, fill = party),
             shape = 21, color = "white", stroke = 0.4,
             size = 3.2, alpha = 1, position = position_jitter(0.01, 0.01)) +
  geom_text_repel(data = df_pol_labeled,
                  aes(x = people, y = elite, label = label),
                  size = 2.8, bg.color = "white", bg.r = 0.12,
                  inherit.aes = FALSE,
                  segment.color = "black", segment.size = 0.3,
                  min.segment.length = 0, box.padding = 0.25, point.padding = 0.1,
                  max.overlaps = Inf, force = 15, force_pull = 0.1,
                  max.iter = 20000, seed = 42,
                  nudge_x = 0.3, nudge_y = -0.15,
                  direction = "both") +
  scale_fill_manual(values = party_colors, na.value = "gray20") +
  scale_x_continuous(breaks = seq(-3, 3, by = 0.5)) +
  scale_y_continuous(breaks = seq(-3, 3, by = 0.5)) +
  coord_cartesian(xlim = c(XMIN, XMAX), ylim = c(YMIN, YMAX), clip = "on") +
  theme_bw(base_size = 7) +
  theme(legend.position = "none",
        plot.background = element_rect(fill = "white", color = "grey20", linewidth = 0.8),
        plot.margin = margin(4, 4, 4, 4),
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank())

p_combined <- p_main +
  inset_element(p_inset,
                left = 0.025, right = 0.45,
                bottom = 0.465, top = 0.975,
                align_to = "panel")
p_combined
ggsave("../images/populism_dimensions_person_level_politicians_inset.png",
       p_combined, bg = "white", width = 8.5, height = 7, dpi = DPI)



paste0(round(sum(V(g)$populism_score > 0,na.rm = T)/length(V(g)$populism_score),2)*100,"% of Users have a populism score above zero") |> cat()

# SET TRUE TO MAKE RESSOURCE INTENSE 3D PLOT
if(FALSE){
  data.frame(
    people = V(g)$people_score,
    elite  = V(g)$elite_score,
    antag  = V(g)$antag_score
  ) |>
    filter(!is.na(people), !is.na(elite), !is.na(antag)) |>
    mutate(people_bin = round(people * 4) / 4,
           elite_bin  = round(elite  * 4) / 4) |>
    group_by(people_bin, elite_bin) |>
    summarise(antag = mean(antag), n = n(), .groups = "drop") |>
    (\(d) {
      base <- ggplot(d, aes(x = people_bin, y = elite_bin)) +
        scale_x_continuous(limits = c(-3, 3), breaks = -3:3) +
        scale_y_continuous(limits = c(-3, 3), breaks = -3:3) +
        coord_equal() +
        theme_bw(base_size = 14) +
        theme(
          legend.position = "none",
          plot.margin = margin(10, 10, 10, 10),
          aspect.ratio = 1
        ) +
        labs(x = "People Score", y = "Elite Score")
  
      p_col <- base +
        geom_tile(aes(fill = antag), width = 0.25, height = 0.25) +
        #scale_fill_viridis_c(direction = 1)
        entoptic::scale_fill_entoptic_c(end = 0.9)
      
      p_height <- base +
        geom_tile(aes(fill = n^0.25), width = 0.25, height = 0.25)
  
      plot_gg(p_col,
              ggobj_height = p_height,
              width = 4, height = 4,
              scale = 100,
              multicore = TRUE,
              shadow_intensity = 0.1,
              offset_edges = TRUE,
              theta = -20, phi = 30, zoom = 0.70,
              windowsize = c(600, 600))
  
      render_highquality(
        filename = "../images/populism_3d.png",
        samples = 256,
        light = TRUE,
        lightdirection = c(135, 225),
        lightaltitude = c(45, 30),
        lightintensity = c(600, 250),
        ambient_light = TRUE,
        lightcolor = c("white", "#ffeedd"),
        width = 2000, height = 2000
      )
    })()
  
  legend_plot <- data.frame(
    people = V(g)$people_score,
    elite  = V(g)$elite_score,
    antag  = V(g)$antag_score
  ) |>
    filter(!is.na(people), !is.na(elite), !is.na(antag)) |>
    mutate(people_bin = round(people * 4) / 4,
           elite_bin  = round(elite  * 4) / 4) |>
    group_by(people_bin, elite_bin) |>
    summarise(antag = mean(antag), n = n(), .groups = "drop") |>
    ggplot(aes(x = people_bin, y = elite_bin, fill = antag)) +
    geom_tile() +
    #scale_fill_viridis_c(direction = 1, name = "Antagonism") +
    entoptic::scale_fill_entoptic_c(end = 0.9, name = "Antagonism") +
    theme(
      legend.background = element_rect(fill = "white", colour = "black", linewidth = 0.5),
      legend.margin = margin(6, 6, 6, 6)
    )
  
  leg <- cowplot::get_legend(legend_plot)
  
  img <- ggdraw() +
    draw_image("../images/populism_3d.png") +
    draw_plot(leg, x = 0.85, y = 0.55, width = 0.15, height = 0.3)
  
  ggsave("../images/populism_3d_final.png", img, width = 10, height = 10)
}




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
             position = position_jitter(
               width = 0.3, height = 0.3,
               seed = 161
               )
             ) +
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

theme_centrality <- theme_bw() +
  theme(
    panel.grid = element_blank(),
    strip.background = element_rect(fill = "white"),
    strip.text = element_text(face = "bold", size = 9)
  )

logticks <- annotation_logticks(
  sides = "trbl",
  short = unit(0.075, "cm"),
  mid   = unit(0.15, "cm"),
  long  = unit(0.175, "cm")
)

# Degree
tibble(value = igraph::degree(g, mode = "all")) |>
  count(value, name = "count") |>
  ggplot(aes(x = value, y = count)) +
  geom_point(size = 1.2, color = "black") +
  scale_x_log10(labels = scales::label_log()) +
  scale_y_log10(labels = scales::label_log()) +
  labs(x = "Degree (log scale)", y = "Frequency (log scale)",
       title = "Reply Network: Largest Component",
       subtitle = "Degree Distribution") +
  theme_centrality + logticks
ggsave("../images/3-degree.png", bg = "white", width = 5, height = 5, dpi = DPI)







#  prepare graph 
g_core <- g
# UNCOMMENT FOR ITERATIVE K CORE DECOMPOSITION (Peeling)
# for (i in 1:1) {
#   deg <- igraph::degree(g_core)
#   g_core <- induced_subgraph(g_core, V(g_core)[deg > 1])
# }

V(g_core)$deg <- igraph::degree(g_core)

#  compute layout 
set.seed(161)
orig_lay <- create_layout(g_core, layout = "drl",
              options = list(
                edge.cut             = 0.94,
                
                liquid.attraction    = 0,
                expansion.attraction = 0,  
                cooldown.attraction  = 0.3,
                crunch.attraction    = 0.6,
                simmer.attraction    = 0.1,
                
                crunch.iterations    = 60, 
                
                use.seed = 161
              ))
lay <- orig_lay
# distance based radial warping
cx   <- median(lay$x)
cy   <- median(lay$y)
dx   <- lay$x - cx
dy   <- lay$y - cy
r    <- sqrt(dx^2 + dy^2)
r_n  <- r / max(r)                 # normalize to [0, 1]

alpha <- 0.55                      # < 1 expands core, > 1 compresses core
r_new <- r_n ^ alpha               # concave warp
r_new <- r_new / max(r_new) * max(r)  # restore original scale

scale <- ifelse(r == 0, 1, r_new / r)
lay$x <- cx + dx * scale
lay$y <- cy + dy * scale

#  pick labels: top-degree politicians, spatially spread 
has_party <- which(!is.na(V(g_core)$party))
ranked    <- has_party[order(V(g_core)$deg[has_party], decreasing = TRUE)]

picked   <- c()
min_dist <- 0.05 * diff(range(lay$x))
for (id in ranked) {
  if (length(picked) == 0 ||
      all(sqrt((lay$x[id] - lay$x[picked])^2 +
               (lay$y[id] - lay$y[picked])^2) > min_dist)) {
    picked <- c(picked, id)
  }
  if (length(picked) >= 45) break
}

V(g_core)$label <- NA
V(g_core)$label[picked] <- V(g_core)$politician_name[picked]

#  plot 
ggraph(g_core, layout = "manual", x = lay$x, y = lay$y) +
  geom_edge_bundle_force(color = "gray40", alpha = 0.005,
                         n_cycle = 1, threshold = 0.3) +
  geom_node_point(data = function(x) filter(x, is.na(V(g_core)$party)),
                  aes(size = deg),
                  color = "gray10", shape = 19, alpha = 0.5, stroke = 0) +
  geom_node_point(data = function(x) filter(x, !is.na(V(g_core)$party)),
                  aes(size = deg, fill = party),
                  shape = 21, color = "white", stroke = 0.2, alpha = 1) +
  geom_node_text(aes(label = label),
                 size = 2.7, repel = TRUE,
                 bg.color = "white", bg.r = 0.1) +
  scale_size_continuous(name = "Degree", range = c(1.1, 5)) +
  scale_fill_manual(name = "Politician of Party",
                    values = c("CDU" = "black",    "CSU"   = "navy",
                               "SPD" = "#E3000F",  "Grüne" = "forestgreen",
                               "FDP" = "#FFED00",  "Linke" = "#BE3075",
                               "AfD" = "#009EE0",  "BSW"   = "#7D1934"),
                    na.value = "gray20",
                    guide = guide_legend(override.aes = list(size = 4))) +
  scale_edge_width_continuous(range = c(0.5, 3)) +
  theme_void() +
  theme(legend.position       = "bottom",
        legend.title.position = "top",
        legend.title          = element_text(face = "bold"),
        legend.text.position  = "left")
ggsave("../images/network_warped.png", bg = "white", width = 10, height = 10, dpi = 600)




lay <- orig_lay
has_party <- which(!is.na(V(g_core)$party))
ranked    <- has_party[order(V(g_core)$deg[has_party], decreasing = TRUE)]
picked   <- c()
min_dist <- 0.05 * diff(range(lay$x))
for (id in ranked) {
  if (length(picked) == 0 ||
      all(sqrt((lay$x[id] - lay$x[picked])^2 +
               (lay$y[id] - lay$y[picked])^2) > min_dist)) {
    picked <- c(picked, id)
  }
  if (length(picked) >= 45) break
}

V(g_core)$label <- NA
V(g_core)$label[picked] <- V(g_core)$politician_name[picked]

#  plot 
ggraph(g_core, layout = "manual", x = lay$x, y = lay$y) +
  geom_edge_bundle_force(color = "gray40", alpha = 0.005,
                         n_cycle = 1, threshold = 0.3) +
  geom_node_point(data = function(x) filter(x, is.na(V(g_core)$party)),
                  aes(size = deg),
                  color = "gray10", shape = 19, alpha = 0.5, stroke = 0) +
  geom_node_point(data = function(x) filter(x, !is.na(V(g_core)$party)),
                  aes(size = deg, fill = party),
                  shape = 21, color = "white", stroke = 0.2, alpha = 1) +
  geom_node_text(aes(label = label),
                 size = 2.7, repel = TRUE,
                 bg.color = "white", bg.r = 0.1) +
  scale_size_continuous(name = "Degree", range = c(1.1, 5)) +
  scale_fill_manual(name = "Politician of Party",
                    values = c("CDU" = "black",    "CSU"   = "navy",
                               "SPD" = "#E3000F",  "Grüne" = "forestgreen",
                               "FDP" = "#FFED00",  "Linke" = "#BE3075",
                               "AfD" = "#009EE0",  "BSW"   = "#7D1934"),
                    na.value = "gray20",
                    guide = guide_legend(override.aes = list(size = 4))) +
  scale_edge_width_continuous(range = c(0.5, 3)) +
  theme_void() +
  theme(legend.position       = "bottom",
        legend.title.position = "top",
        legend.title          = element_text(face = "bold"),
        legend.text.position  = "left")
ggsave("../images/network.png", bg = "white", width = 10, height = 10, dpi = 600)



# for black background
ggraph(g_core, layout = "manual", x = lay$x, y = lay$y) +
  geom_edge_bundle_force(color = "gray40",
                         alpha = 0.05,
                         n_cycle = 1, threshold = 0.3) +
  geom_node_point(data = function(x) filter(x, is.na(V(g_core)$party)),
                  aes(size = deg), 
                  color = "gray80", shape = 19, alpha = 0.3, stroke = 0) +   # lighter
  geom_node_point(data = function(x) filter(x, !is.na(V(g_core)$party)),
                  aes(size = deg, fill = party), 
                  shape = 21, color = "white", stroke = 0, alpha = 1) +
  geom_node_text(aes(label = label),
                 size = 2.7, repel = TRUE, color = "white",      # white text
                 bg.color = "black", bg.r = 0.1) +               # dark text halo
  scale_size_continuous(name = "Degree", range = c(1, 5)) +
  scale_fill_manual(name = "Politician of Party", 
                    values = c("CDU"="gray70", "CSU"  = "dodgerblue",  # CDU no longer black
                               "SPD"="#E3000F", "Grüne"= "forestgreen",
                               "FDP"="#FFED00", "Linke"= "#BE3075",
                               "AfD"="#009EE0", "BSW"  = "#7D1934"), 
                    na.value = "gray50",
                    guide = guide_legend(override.aes = list(size = 4))) +
  scale_edge_width_continuous(range = c(0.25,2.2)) +
  theme_void() +
  theme(legend.position = "bottom",
        legend.title.position = "top",
        legend.title = element_text(face="bold", color = "white"),
        legend.text = element_text(color = "white"),
        plot.background = element_rect(fill = "black", color = NA),
        panel.background = element_rect(fill = "black", color = NA))
ggsave("../images/network_dark.png", bg = "black", width = 10, height = 10, dpi = DPI)



# empty background
ggraph(g_core, layout = "manual", x = lay$x, y = lay$y) +
  geom_edge_bundle_force(color = "gray40",
                         alpha = 0.05,
                         n_cycle = 1, threshold = 0.3) +
  geom_node_point(data = function(x) filter(x, is.na(V(g_core)$party)),
                  aes(size = deg), 
                  color = "gray80", shape = 19, alpha = 0.3, stroke = 0) +   # lighter
  geom_node_point(data = function(x) filter(x, !is.na(V(g_core)$party)),
                  aes(size = deg, fill = party), 
                  shape = 21, color = "white", stroke = 0, alpha = 1) +
  # geom_node_text(aes(label = label),
  #                size = 2.7, repel = TRUE, color = "white",      # white text
  #                bg.color = "black", bg.r = 0.1) +               # dark text halo
  scale_size_continuous(name = "Degree", range = c(1, 5)) +
  scale_fill_manual(name = "Politician of Party", 
                    values = c("CDU"="gray70", "CSU"  = "dodgerblue",  # CDU no longer black
                               "SPD"="#E3000F", "Grüne"= "forestgreen",
                               "FDP"="#FFED00", "Linke"= "#BE3075",
                               "AfD"="#009EE0", "BSW"  = "#7D1934"), 
                    na.value = "gray50",
                    guide = guide_legend(override.aes = list(size = 4))) +
  scale_edge_width_continuous(range = c(0.5,3)) +
  theme_void() +
  theme(legend.position = "bottom",
        legend.title.position = "top",
        legend.title = element_text(face = "bold", color = "white"),
        legend.text = element_text(color = "white"),
        plot.background = element_rect(fill = "transparent", color = NA),
        panel.background = element_rect(fill = "transparent", color = NA))

ggsave("../images/network_trans.png", bg = "transparent", width = 10, height = 10, dpi = DPI)











# === Network Plot with Zoomed Inset ===
# --- Define zoom region ---
zoom_xlim <- c(-55, -30) - 10
zoom_ylim <- c(20, 40) - 60
dist(zoom_xlim)[1]
dist(zoom_ylim)[1]
# --- Flag cluster-internal edges ---
el <- as_edgelist(g_core, names = FALSE)
in_zoom_nodes <- (lay$x >= min(zoom_xlim) & lay$x <= max(zoom_xlim) &
                    lay$y >= min(zoom_ylim) & lay$y <= max(zoom_ylim))
cluster_idx <- which(in_zoom_nodes[el[,1]] & in_zoom_nodes[el[,2]])

# Set edge attribute directly on the igraph object
E(g_core)$is_cluster <- seq_len(ecount(g_core)) %in% cluster_idx

# Rebuild layout with updated edge attribute
lay_inset <- create_layout(g_core, layout = "manual",
                           x = lay$x, y = lay$y)

# --- Main plot -> p_main ---
p_main <- 
  ggraph(g_core, layout = "manual", x = lay$x, y = lay$y) +
  geom_edge_bundle_force(color = "gray40", alpha = 0.005,
                         n_cycle = 1, threshold = 0.3) +
  geom_node_point(data = function(x) filter(x, is.na(V(g_core)$party)),
                  aes(size = deg),
                  color = "gray15", shape = 19, alpha = 0.5, stroke = 0) +
  geom_node_point(data = function(x) filter(x, !is.na(V(g_core)$party)),
                  aes(size = deg, fill = party),
                  shape = 21, color = "white", stroke = 0.2, alpha = 1) +
  annotate("rect",
           xmin = zoom_xlim[1], xmax = zoom_xlim[2],
           ymin = zoom_ylim[1], ymax = zoom_ylim[2],
           fill = NA, color = "grey10", linewidth = 0.5) +
  geom_node_text(aes(label = label),
                 size = 2.7, repel = TRUE,
                 bg.color = "white", bg.r = 0.1) +
  scale_size_continuous(name = "Degree", range = c(1.1, 5)) +
  scale_fill_manual(name = "Politician of Party",
                    values = c("CDU" = "black",    "CSU"   = "navy",
                               "SPD" = "#E3000F",  "Grüne" = "forestgreen",
                               "FDP" = "#FFED00",  "Linke" = "#BE3075",
                               "AfD" = "#009EE0",  "BSW"   = "#7D1934"),
                    na.value = "gray20",
                    guide = guide_legend(override.aes = list(size = 4))) +
  annotate("segment",color = "gray15", linewidth = 0.7, linetype = "dashed",
           x = zoom_xlim[1], xend = -450,
           y = zoom_ylim[2], yend = -110) +
  annotate("segment",color = "gray15", linewidth = 0.7, linetype = "dashed",
           x = zoom_xlim[2], xend = -155,
           y = zoom_ylim[2], yend = -110) +
  scale_edge_width_continuous(range = c(0.5, 3)) +
  theme_void() +
  theme(legend.position       = "bottom",
        legend.title.position = "top",
        legend.title          = element_text(face = "bold"),
        legend.text.position  = "left")
p_main
# --- Zoomed inset -> p_inset ---
# Find Weidel's node index
weidel_idx <- which(V(g_core)$politician_name == "Alice Elisabeth Weidel")

# Three-level classification
E(g_core)$edge_type <- ifelse(
  !seq_len(ecount(g_core)) %in% cluster_idx,
  "external",
  ifelse(el[,1] == weidel_idx | el[,2] == weidel_idx,
         "hub",
         "alter")
)

# Rebuild layout
lay_inset <- create_layout(g_core, layout = "manual",
                           x = lay$x, y = lay$y)

p_inset <- ggraph(lay_inset) +
  geom_edge_link0(aes(edge_colour = edge_type,
                      edge_alpha = edge_type,
                      linewidth = edge_type),
                  arrow = arrow(length = unit(1.5, "mm"), type = "closed"),
                  end_cap = circle(2, "mm"),
                  start_cap = circle(2, "mm")) +
  scale_edge_colour_manual(values = c("alter"    = "gray10",
                                      "hub"      = "gray10",
                                      "external" = "gray50"),
                           guide = "none") +
  scale_edge_alpha_manual(values = c("alter"    = 0.85,
                                     "hub"      = 0.2,
                                     "external" = 0.4),
                          guide = "none") +
  scale_edge_width_manual(values = c("alter"    = 0.6,
                                     "hub"      = 0.5,
                                     "external" = 0.1),
                          guide = "none") +
  geom_node_point(data = function(x) filter(x, is.na(party)),
                  aes(size = deg),
                  color = "gray20", shape = 19, alpha = 0.5, stroke = 0) +
  geom_node_point(data = function(x) filter(x, !is.na(party)),
                  aes(size = deg, fill = party),
                  shape = 21, color = "white", stroke = 0.5, alpha = 1) +
  geom_node_text(data = function(x) filter(x, !is.na(politician_name),
                                           x >= min(zoom_xlim), x <= max(zoom_xlim),
                                           y >= min(zoom_ylim), y <= max(zoom_ylim)),
                 aes(label = politician_name),
                 size = 2.5, repel = TRUE,
                 bg.color = "white", bg.r = 0.15) +
  scale_size_continuous(range = c(2, 8)) +
  scale_fill_manual(values = c("CDU"="black", "CSU"="navy",
                               "SPD"="#E3000F", "Grüne"="forestgreen",
                               "FDP"="#FFED00", "Linke"="#BE3075",
                               "AfD"="#009EE0", "BSW"="#7D1934"),
                    na.value = "gray20") +
  coord_cartesian(xlim = zoom_xlim, ylim = zoom_ylim, clip = "on") +
  theme_void() +
  theme(legend.position = "none",
        plot.background = element_rect(fill = "white", color = "grey30", linewidth = 0.8),
        plot.margin = margin(6, 6, 6, 6))
p_inset
# --- Combine and save ---
p_combined <- p_main + 
  #theme_bw() +
  inset_element(p_inset,
                left = 0.05, right = 0.35,
                bottom = 0.05, top = 0.35,
                align_to = "panel") 

p_combined

ggsave("../images/network_inset.png", p_combined,
       bg = "white", width = 10, height = 10, dpi = DPI)

