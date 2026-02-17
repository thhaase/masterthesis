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
data_path = "/home/thhaase/Documents/synosys_masterthesis"

setDTthreads(0)

# === load data ===
# Load both raw and reftweets, then combine
raw <- rbind(
  read_parquet(paste0(data_path,"/raw.parquet")),
  read_parquet(paste0(data_path,"/reftweets.parquet"))
) |> 
  distinct(id, .keep_all = TRUE) %>%  # Deduplicate by tweet ID
  setDT()

# add politicians info
raw <- merge(
  raw,
  read_parquet(file.path(data_path, "politicians.parquet.gzip")) |>
    setDT() |>
    _[, user_screen_name := gsub("https://x.com/|/$", "", x_url)],
  by = "user_screen_name",
  all.x = TRUE
)

# filter double rows so that IDs become the dataset KEY
setorder(raw, -timestamp_utc)
d <- unique(raw, by = "id")

# filter for all tweets that are part of the reply network (replying or replied to)
d_reply <- d[id %in% d[!is.na(to_tweetid), unique(c(id, to_tweetid))]]
d <- d_reply
rm(d_reply)

# === === === === === === === === === === === === === === === === === === === == 
# Idea: 
# Create a network of tweets, filter them based on threadsize, then indicate those tweets in the big table and delete them there aswell

d_el <- d[!is.na(id) & !is.na(to_tweetid) & !is.na(user_id) & !is.na(to_userid),
          .(id, to_tweetid, user_id, to_userid)] |> as.matrix()

gt <- d_el[,1:2] |> graph_from_edgelist() # tweet - tweet reply network
gu <- d_el[,3:4] |> graph_from_edgelist() #  user - user  reply network

igraph::degree(gu) |> 
  as.data.table() |> 
  _[, .N, by = .(degree = V1)] |>
  ggplot(aes(x = degree, y = N)) +
  geom_point() +
  theme_minimal() +
  scale_x_log10() +
  scale_y_log10() +
  labs(x = "Degree", y = "Frequency")

igraph::degree(gt) |> 
  as.data.table() |> 
  _[, .N, by = .(degree = V1)] |>
  ggplot(aes(x = degree, y = N)) +
  geom_point() +
  theme_minimal() +
  scale_x_log10() +
  scale_y_log10() +
  labs(x = "Degree", y = "Frequency")

igraph::components(gu)$csize |>
  as.data.table() |>
  _[, .N, by = .(size = V1)] |>
  ggplot(aes(x = size, y = N)) +
  geom_point() +
  theme_minimal() +
  scale_x_log10() +
  scale_y_log10() +
  labs(x = "Component Size", y = "Frequency")

igraph::components(gt)$csize |>
  as.data.table() |>
  _[, .N, by = .(size = V1)] |>
  ggplot(aes(x = size, y = N)) +
  geom_point() +
  theme_minimal() +
  scale_x_log10() +
  scale_y_log10() +
  labs(x = "Component Size", y = "Frequency")


# FILTERING THREADS DEACTIVATED
# REASON: Did not change anything meaningful for the descriptive statistics of the 2_describe_network.R descriptive statistics 
# ---
# gt <- gt |>
#   delete_vertices(which(igraph::components(gt)$membership %in% which(igraph::components(gt)$csize < 3)))
# d <- d[d$id %in% names(V(gt)), ]

# === === === === === === === === === === === === === === === === === === === == 
# == Create Threads and get Thread Information ==
# Now the tweet-threads are decomposed and their information is added to the individual rows. 
# For each tweet I want to know what roottweet it had, what position in the tree it has and what the leadratio is, maybe later also populist rhetoric amount

# get all components(threads)
gt_threads <- decompose(gt) 

# list with structure list[[thread]][[ids in that thread]]
threadid_lookup <- lapply(gt_threads, \(thread) names(V(thread)))

# threadIDs are position of thread in threadid_lookup -> add that to d
d[lapply(seq_along(threadid_lookup), 
         \(i) data.table(id = threadid_lookup[[i]], thread_id = i)) |>
    rbindlist(), 
  on = "id", 
  thread_id := i.thread_id]

d$thread_id |> head()

# Step 1: Create threadinfo with ONE row per thread (not per node!)
threadinfo <- lapply(gt_threads, function(thread) {
  list(
    size    = vcount(thread),
    leaf_pc = sum(igraph::degree(thread) == 1) / vcount(thread),
    id_root = names(which(igraph::degree(thread, mode = "out") == 0))
  )
}) |> rbindlist(idcol = "thread_id")

# Step 2: Enrich with root user info (same as before)
threadinfo[d, on = .(id_root = id), `:=`(
  user_name = i.user_name,
  user_screen_name = i.user_screen_name,
  party = i.party,
  user_followers = i.user_followers,
  user_friends = i.user_friends,
  user_likes = i.user_likes,
  user_tweets = i.user_tweets,
  like_count = i.like_count,
  retweet_count = i.retweet_count,
  reply_count = i.reply_count
)]
threadinfo

# Step 3: Set keys and join efficiently
setkey(d, thread_id)
setkey(threadinfo, thread_id)

d[threadinfo, 
  c("thread_size", "thread_leaf_pc", "thread_root_id", "thread_root_user_name", 
    "thread_root_user_screen_name", "thread_root_party",
    "thread_root_user_followers", "thread_root_user_friends", 
    "thread_root_user_likes", "thread_root_user_tweets",
    "thread_root_like_count", "thread_root_retweet_count", 
    "thread_root_reply_count") := 
    .(i.size, i.leaf_pc, i.id_root, i.user_name, i.user_screen_name, i.party,
      i.user_followers, i.user_friends, i.user_likes, i.user_tweets,
      i.like_count, i.retweet_count, i.reply_count)]


# = Depth of Tweet in Trees =
tweet_depth <- gt_threads |>
  lapply(\(thread) {
    # Find root (out-degree = 0)
    out_degrees <- igraph::degree(thread, mode = "out")
    root_id <- which(out_degrees == 0)[1]  
    
    # find depth (traverse graph)
    bfs_result <- igraph::bfs(
      thread, 
      root = root_id, 
      mode = "in",  # Follow edges backward (from root to leaves)
      unreachable = FALSE
    )
    
    data.table(
      id = names(V(thread)),
      depth = as.numeric(bfs_result$dist)
    )
  }) |>
  rbindlist()

d[tweet_depth, on = "id", thread_tweet_depth := i.depth]
rm(tweet_depth)

ggplot(threadinfo, aes(x = size)) + 
  geom_point(stat = "count") +
  scale_x_log10() +
  scale_y_log10() +
  theme_bw() +
  labs(title = "Nodes per Discussion-Thread in Replynetwork",
       subtitle = "Nodes: Tweets, Links encode Reply",
       x="Thread Size (n Nodes)", y="Count of Threads")

threadinfo[, .(
  thread_id = thread_id[which.max(size)],
  nodes_in_thread = max(size),
  total_nodes = sum(size),
  percent = (max(size) / sum(size)) * 100
)] |> print()

# === === === === === === === === === === === === === === === === === === === == 
# Create final user network
# === === ===
# The dataset only has tweets below politicians posts in it. 
# The discussion Dynamic is therefore only happening in threads
# That serious discussions can arise it is necessary to have enough nodes in a tree 
# - What are enough nodes?
#   - Simmel -> min. 3 persons needed for a group
# - In a Discussion
# - Just one answer does not count as a discussion
# === === ===

# # Option 1: Use graph_from_data_frame() (recommended)
# gu <- d[!is.na(user_id) & !is.na(to_userid),
#                        .(user_id, to_userid, id)] |> 
#   graph_from_data_frame(directed = TRUE)
# 
# # Create weighted edge list by counting connections
# gu <- d[!is.na(user_id) & !is.na(to_userid),
#         .(weight = .N), 
#         by = .(user_id, to_userid)] |> 
#   graph_from_data_frame(directed = TRUE)
# Create the graph with weights and tweet ID references

gu <- d[!is.na(user_id) & !is.na(to_userid),
        .(weight = .N,
          first_tweet_id = first(id),
          tweet_ids = paste(id, collapse = "|")  # All tweetIDs as string
        ),
        by = .(user_id, to_userid)] |> 
  graph_from_data_frame(directed = TRUE)

gu |> is_directed()
gu |> is_weighted()
gu


igraph::components(gu)$csize |>
  as.data.table() |>
  _[, .N, by = .(size = V1)] |>
  ggplot(aes(x = size, y = N)) +
  geom_point() +
  theme_bw() +
  scale_x_log10(
    labels = scales::comma,
    breaks = scales::breaks_log(n = 10, base = 10)
  ) +
  scale_y_log10() +
  labs(x = "Component Size", y = "Frequency",
       title = "Retweet Network\n(User) ––Retweet––> (User)",
       subtitle = "Frequency of Components with specific sizes")


total_nodes <- igraph::vcount(gu)

table_componentsizes <- igraph::components(gu)$csize |>
  as.data.table() |>
  _[, .N, by = .(size = V1)] |>
  _[, `:=`(
    total_nodes = size * N,
    pct_of_network = 100 * size * N / vcount(gu)
  )] |>
  setorder(-size) |>
  _[, .(
    `Component Size` = size,
    `Number of Components` = N,
    `Total Nodes` = total_nodes,
    `% of Network` = sprintf("%.2f%%", pct_of_network)
  )]
table_componentsizes
# largest component has 98% of all nodes

kable(table_componentsizes, 
      format = "markdown",
      caption = "") |>
  writeLines("../tables/component_table.md")


# === === === === === === === === === === === === === === === === === === === == 
# Isolate largest component (98% of all nodes)
# === === ===

gu_largest <- gu |> 
  induced_subgraph(which(igraph::components(gu)$membership == which.max(igraph::components(gu)$csize)))

# sanity checks
vcount(gu_largest) 
igraph::components(gu_largest)$no


saveRDS(gu_largest, "largest_component.rds")
write_parquet(d, "d.parquet")

rm(list = ls())
