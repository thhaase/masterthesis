library(arrow)
library(tidyverse)
library(data.table)

library(igraph)

library(intergraph)
library(network)
library(sna)

library(bit64)


data_path = "/home/thhaase/Documents/synosys_masterthesis"

d <- read_parquet(paste0(data_path,"/dd.parquet")) |> 
  setDT() |>
  _[, c("id", "to_tweetid", "user_id", "to_userid") := lapply(.SD, as.character), 
    .SDcols = c("id", "to_tweetid", "user_id", "to_userid")]

# filter for all tweets that are part of the reply network (repliying or replied to)
d <- d |> 
  filter(id %in% (
    d |> 
      filter(!is.na(to_tweetid)) |> 
      select(id, to_tweetid) |> 
      unlist() |> unique()
  )) |> setDT()


# === === === === === === === === === === === === === === === === === === === ==
# === Create Network === 

d_el <- d[!is.na(id) & !is.na(to_tweetid) & !is.na(user_id) & !is.na(to_userid),
          .(id, to_tweetid, user_id, to_userid)] |> as.matrix()

gt <- d_el[,1:2] |> graph_from_edgelist() # tweet - tweet reply network
gu <- d_el[,3:4] |> graph_from_edgelist() #  user - user  reply network



# == Create Threads and get Thread Information ==

threads <- decompose(gt)


# create and add thread_id in d
threadid_lookup <- lapply(threads, \(thread) names(V(thread)))

d[lapply(seq_along(threadid_lookup), 
         \(i) data.table(id = threadid_lookup[[i]], thread_id = i)) |>
    rbindlist(), 
  on = "id", 
  thread_id := i.thread_id]

d$thread_id |> head()

# create threadinfo and match based on thread_id
threadinfo <- lapply(threads, function(thread) {
  list(
    id      = names(V(thread)),
    size    = vcount(thread),
    leaf_pc = sum(igraph::degree(thread) == 1) / vcount(thread),
    id_root = names(which(igraph::degree(thread, mode = "out") == 0))
  )
}) |> rbindlist(idcol = "thread_id")

d[threadinfo, 
  on = "thread_id", 
  c("thread_size", "thread_leaf_pc", "thread_root_id") := 
    .(i.size, i.leaf_pc, i.id_root)]


# = Depth of Tweet in Trees =
# flag _thread_tweet (tweetspecific) vs. _thread_root(roottweet specific)
tweet_depth <- threads |>
  lapply(\(thread) {
    root_nodes <- thread |>
      igraph::degree(mode = "out") |>
      {\(x) names(x[x == 0])}()
    
    thread |>
      igraph::distances(to = root_nodes, mode = "out") |>
      apply(1, min) |>
      {\(d) data.table(id = names(d), depth = d)}()
  }) |>
  rbindlist()
d[tweet_depth, on = "id", thread_tweet_depth := i.depth]
rm(tweet_depth)




# Explore Threads
threads[[5174]] |> asNetwork() |> gplot()
threads[[5174]] |> igraph::degree(mode = "out") |> (\(x) x == 0)() |> which() |> names()

threads[[5174]] |>
  asNetwork() |>
  gplot(
    mode = "kamadakawai",
    vertex.col = threads[[5174]] |>
      igraph::distances(
        v = igraph::V(threads[[5174]])[igraph::degree(threads[[5174]], mode = "out") == 0],
        mode = "in"
      ) |>
      as.vector() |>
      (\(d) viridisLite::viridis(length(unique(d)), direction = -1)[as.numeric(factor(d))])()
  )

# == add rootnode info ==










# === === === === === === === === === === === === === === === === === === === ==
# === Filter ===

plot(as.numeric(names(table(sapply(decompose(g_raw), vcount)))),
     as.numeric(table(sapply(decompose(g_raw), vcount))), log="xy", 
     main="Component Size Distribution",
     xlab="Log(Component Size)", 
     ylab="Log(Frequency)",
     pch=19, col="steelblue", type = "b")

# only keep 
g <- g_raw |> 
  decompose() |> 
  (\(decomp_graph) Filter(function(g) vcount(g) >= 3, decomp_graph))() |> 
  (\(filtered_graph) do.call(disjoint_union, filtered_graph))()

decompose(g)[[2]] |> asNetwork() |> gplot()



# === Function to build the User Interaction Network ===
get_user_graph <- function(sub_d) {
  # Edges: Who replied to Whom
  edges <- sub_d[!is.na(user_id) & !is.na(to_userid), 
                 .(from = as.character(user_id), 
                   to   = as.character(to_userid))]
  
  # If no interaction edges exist in this thread, return empty graph
  if (nrow(edges) == 0) return(make_empty_graph())
  
  graph_from_data_frame(edges, directed = TRUE)
}

# === Function to build the Tweet Tree Network ===
get_tweet_graph <- function(sub_d) {
  # Edges: Tweet -> Parent Tweet
  edges <- sub_d[!is.na(to_tweetid), 
                 .(from = as.character(id), 
                   to   = as.character(to_tweetid))]
  
  # Vertices: All tweets in this thread (ensures root is included even if it has no outgoing edge)
  nodes <- unique(sub_d[, .(name = as.character(id))])
  
  graph_from_data_frame(edges, vertices = nodes, directed = TRUE)
}

# === Generate the Aligned Lists ===
user_net_list  <- lapply(d_threads, get_user_graph)
tweet_net_list <- lapply(d_threads, get_tweet_graph)

# VERIFICATION
thread_idx <- 1

g_user <- user_net_list[[thread_idx]]
g_tweet <- tweet_net_list[[thread_idx]]

plot(g_tweet, main = paste("Tweet Tree", thread_idx))
plot(g_user, main = paste("User Flow", thread_idx))

# === === === === === === === === === === === === === === === === === === === ==
# attribute lookup table
node_data_sender <- d |> 
  distinct(xid, .keep_all = TRUE) |> 
  mutate(
    id_char = as.character(xid),
    engagement = as.numeric(scale(retweet_count) + scale(like_count) + scale(reply_count))
  )

node_data_target <- d |> 
  filter(!is.na(target_party)) |>       # Only keep useful targets (politicians)
  distinct(xto_tweetid, .keep_all = TRUE) |> 
  mutate(id_char = as.character(xto_tweetid))


idx_sender <- match(V(g_raw)$name, node_data_sender$id_char)
idx_target <- match(V(g_raw)$name, node_data_target$id_char)

V(g_raw)$llm_populism_mean <- node_data_sender$llm_populism_mean[idx_sender]
V(g_raw)$party             <- node_data_sender$party[idx_sender]
V(g_raw)$engagement        <- node_data_sender$engagement[idx_sender]
V(g_raw)$user_name         <- node_data_sender$user_name[idx_sender]
V(g_raw)$user_description  <- node_data_sender$user_description[idx_sender]
V(g_raw)$user_friends      <- node_data_sender$user_friends[idx_sender]
V(g_raw)$user_likes        <- node_data_sender$user_likes[idx_sender]
V(g_raw)$timestamp_utc     <- node_data_sender$timestamp_utc[idx_sender]

# 1. User Metadata
V(g_raw)$user_followers    <- node_data_sender$user_followers[idx_sender]
V(g_raw)$reply_count       <- node_data_sender$reply_count[idx_sender]
V(g_raw)$likecount         <- node_data_sender$like_count[idx_sender] 

# 2. Demographics
V(g_raw)$politician_name   <- node_data_sender$politician_name[idx_sender]
V(g_raw)$gender            <- node_data_sender$gender[idx_sender]
V(g_raw)$religion          <- node_data_sender$religion[idx_sender]

# 3. LLM Scores: GPT-120B
V(g_raw)$gpt120b_populist_score  <- node_data_sender$gpt120b_populist_score[idx_sender]
V(g_raw)$gpt120b_elitist_score   <- node_data_sender$gpt120b_elitist_score[idx_sender]
V(g_raw)$gpt120b_intensity_score <- node_data_sender$gpt120b_intensity_score[idx_sender]

# 4. LLM Scores: Qwen-235B (Note: d uses 'qwen235b', not '325b')
V(g_raw)$qwen325b_populist_score  <- node_data_sender$qwen235b_populist_score[idx_sender]
V(g_raw)$qwen325b_elitist_score   <- node_data_sender$qwen235b_elitist_score[idx_sender]
V(g_raw)$qwen325b_intensity_score <- node_data_sender$qwen235b_intensity_score[idx_sender]


missing_party <- is.na(V(g_raw)$party)
has_target_info <- !is.na(idx_target)
to_update <- missing_party & has_target_info
V(g_raw)$party[to_update] <- node_data_target$target_party[idx_target[to_update]]
V(g_raw)$user_name[to_update] <- node_data_target$to_username[idx_target[to_update]]

rm(node_data_sender, node_data_target, idx_sender, idx_target, missing_party, has_target_info, to_update)

# Verification
cat("Nodes:", vcount(g_raw), "\n")
cat("Party info present:", sum(!is.na(V(g_raw)$party)), "/", vcount(g_raw), "\n")
cat("Nodes:", vcount(g_raw), "| Pop. Score Present:", sum(!is.na(V(g_raw)$llm_populism_mean)), "\n")
# ~16% of the nodes are not in the network, normal for reply networks
sum(degree(g_raw, mode = "out") == 0 & degree(g_raw, mode = "in") > 0)

# ---- Start Descriptives ----

paste0("The raw graph has ",igraph::components(g_raw)$no," Components")


igraph::components(g_raw, mode = "weak")$csize |> 
  as.data.frame() |> 
  setNames("size") |> 
  count(size) |> 
ggplot(aes(x = size, y = n)) +
  geom_point(color = "steelblue4", size = 3) +
  geom_smooth(method = "lm", se = FALSE, 
              color = "gray50", linetype = "dashed", 
              linewidth = 1.5) +
  scale_x_log10(breaks = scales::trans_breaks("log10", function(x) 10^x), 
                limits = c(0.8, NA), labels = scales::comma_format(accuracy = 1)) +
  scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x), 
                limits = c(0.8, NA), labels = scales::comma_format(accuracy = 1)) +
  theme_minimal() +
  labs(
#    title = "Component Size Distribution", 
#    subtitle = "with Powerlaw Fit",
    x = "log10(Component Size)",
    y = "log10(Frequency)"
    ) +
  theme(text=element_text(size=13, family="Lato Medium"))
ggsave("images/component-size-distribution-raw.png", bg="white", width = 8, height = 8, dpi=600)
ggsave("images/component-size-distribution-raw.svg", bg="white", width = 8, height = 8)

igraph::components(g_raw, mode = "weak")$csize |> 
  data.frame(size = _) |> 
  dplyr::count(size) |> 
  lm(log10(n) ~ log10(size), data = _)

# ---- Reducing the Network ----

tibble(size = components(g_raw)$csize) |>
  count(size) |>
  arrange(size) |>
  mutate(
    `Components Removed` = cumsum(n) / sum(n),
    `Nodes Retained` = 1 - (cumsum(size * n) / sum(size * n))
  ) |>
  filter(size <= 20) |>
  pivot_longer(cols = c(`Components Removed`, `Nodes Retained`)) |>
ggplot(aes(x = size, y = value, color = name)) +
  geom_vline(xintercept = 3, linewidth = 1.5, color = "red3", linetype = "dashed") +
  geom_line(linewidth = 1.5) +
  geom_point(size = 3) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1), 
                     breaks = seq(0, 1, 0.2)) +
  scale_x_continuous(breaks = 1:20, minor_breaks = NULL) +
  scale_color_viridis_d(option = "D", end = 0.8) +
  theme_minimal() +
  theme(legend.position = "bottom",
        text=element_text(size=13, family="Lato Medium")) +
  labs(
    title = "Trade Off: Removed Components vs. Retained Nodes",
    subtitle = "Removing ~95% of Components (Noise) retains >30% of Total Tweets (Signal)",
    x = "Removal Threshold (Component Size ≤ x)", 
    y = "Componentshare or Nodeshare of Total Dataset (%)", 
    color = NULL
  )
ggsave("images/component-removal-trade-off.png", bg="white", width = 13.5, height = 7.5, dpi=600)
ggsave("images/component-removal-trade-off.svg", bg="white", width = 13.5, height = 7.5)


g <- delete_vertices(g_raw, which(components(g_raw)$membership %in% which(components(g_raw)$csize <= 3)))
paste0("The reduced graph has ",igraph::components(g)$no," Components")

igraph::components(g)$csize |> 
  as.data.frame() |> 
  setNames("size") |> 
  count(size) |> 
ggplot(aes(x = size, y = n)) +
  geom_point(color = "steelblue4", size = 3) +
  geom_smooth(method = "lm", se = FALSE, 
              color = "gray50", linetype = "dashed", 
              linewidth = 1.5) +
  scale_x_log10(breaks = scales::trans_breaks("log10", function(x) 10^x), 
                limits = c(min(components(g)$csize), NA), labels = scales::comma_format(accuracy = 1)) +
  scale_y_log10(breaks = scales::trans_breaks("log10", function(x) 10^x), 
                limits = c(1, NA), labels = scales::comma_format(accuracy = 1)) +
  theme_minimal() +
  labs(x = "log10(Component Size)", y = "log10(Frequency)", 
       title = "Component Size Distribution of Reduced Network",
       subtitle = "with Powerlaw Fit")+
  theme(text=element_text(size=13, family="Lato Medium"))
ggsave("images/component-size-distribution-reduced.png", bg="white", width = 8, height = 8, dpi=600)
ggsave("images/component-size-distribution-reduced.svg", bg="white", width = 8, height = 8)



tibble(
  Parameter = c(
    "Node Count",
    "Tie Count",
    "Degree",
    "Component Count",
    "Component Size",
    "Diameter per Component",
    "Leaf Fraction per Component"
  ),
  `Value (AVG ± SD)` = c(
    format(vcount(g), big.mark = ","),
    format(ecount(g), big.mark = ","),
    
    degree(g, mode = "all") |> 
      {\(x) paste0(round(mean(x), 1), " ± ", round(sd(x), 1))}(),
    
    format(components(g)$no, big.mark = ","),
    
    components(g)$csize |> 
      {\(x) paste0(round(mean(x), 1), " ± ", round(sd(x), 1))}(),
    
    decompose(g) |> 
      map_dbl(diameter, directed = FALSE) |> 
      {\(x) paste0(round(mean(x), 1), " ± ", round(sd(x), 1))}(),

    decompose(g) |> 
      map_dbl(function(x) { sum(degree(x) == 1) / vcount(x) }) |> 
      {\(x) paste0(round(mean(x) * 100, 1), "% ± ", round(sd(x) * 100, 1), "%")}()
  )
) |>
  gt() |>
  cols_label(`Value (AVG ± SD)` = md("Value (AVG $\\pm$ SD)")) |>
  tab_footnote(
    footnote = "Thread Depth: Longest Shortest Path aka Debate per Thread",
    locations = cells_body(rows = 6, columns = Parameter)
  ) |>
  tab_footnote(
    footnote = "Leaf Fraction: Low %: Long Debate Branches - High %: Broadcasting Starshape",
    locations = cells_body(rows = 7, columns = Parameter)
  ) |>
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_title(groups = "title")
  ) |>
  gtsave("images/network-descriptive-stats.tex")

# The analysis reveals a highly fragmented, broadcast-oriented topology. With a Leaf Fraction of 73% and a low average Diameter (3.3), the network consists primarily of 'hub-and-spoke' reaction threads where users engage with a central post rather than with each other. The high variance in component size (±35.7) indicates that the network is dominated by a few massive 'viral' events amidst a sea of small, disconnected interactions.

# ---- Quick plot for Presentation ----
library(intergraph)
library(sna)

decompose <- decompose(g)  
decompose[[1]] |> asNetwork() |> gplot()
decompose[[2]] |> asNetwork() |> gplot()
decompose[[3]] |> asNetwork() |> gplot()
decompose[[4]] |> asNetwork() |> gplot()
decompose[[5]] |> asNetwork() |> gplot()

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# ---- ADD POPULIST RHETORIC ----
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


thread_stats <- decompose(g) |>
  map_dfr(function(subgraph) {
    
    pops <- V(subgraph)$llm_populism_mean 
    engs <- V(subgraph)$engagement
    
    tibble(
      mean_pop = mean(pops, na.rm = TRUE),
      sd_pop   = sd(pops, na.rm = TRUE), 
      mean_eng = mean(engs, na.rm = TRUE),
      max_eng  = if(all(is.na(engs))) NA else max(engs, na.rm = TRUE)
    )
  })

# Helper function
fmt_msd <- function(x) {
  paste0(round(mean(x, na.rm = TRUE), 2), " ± ", round(sd(x, na.rm = TRUE), 2))
}

# 2. Create and Save the Table
tibble(
  Category = c(
    "Populist Rhetorics", "Populist Rhetorics",
    "Impact & Engagement", "Impact & Engagement"
  ),
  Parameter = c(
    "Mean Thread Populism", "Thread Polarization (SD)",
    "Avg. Engagement", "Peak Engagement"
  ),
  `Value (AVG ± SD)` = c(
    # Rhetoric
    fmt_msd(thread_stats$mean_pop),
    fmt_msd(thread_stats$sd_pop),
    
    # Impact
    fmt_msd(thread_stats$mean_eng),
    fmt_msd(thread_stats$max_eng)
  )
) |>
  gt(groupname_col = "Category") |>
  cols_label(`Value (AVG ± SD)` = md("Value (AVG $\\pm$ SD)")) |>
  tab_footnote(
    footnote = "Engagement: Sum of z-scaled Retweet, Like and Reply Count",
    locations = cells_row_groups(groups = "Impact & Engagement")
  ) |>
  tab_style(
    style = list(
      cell_text(weight = "bold", align = "left")
    ),
    locations = cells_row_groups()
  ) |>
  # Save directly to .tex
  gtsave("images/network-content-stats.tex")



saveRDS(g, paste0(data_path, "/reply_network_reduced.rds"))

rm(list = ls())
cat("done")