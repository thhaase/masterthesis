library(arrow)
library(tidyverse)
library(data.table)

library(igraph)

library(intergraph)
library(network)
library(sna)

library(bit64)


data_path = "/home/thhaase/Documents/synosys_masterthesis"

setDTthreads(0)
#getDTthreads()

# === load data ===

raw <- read_parquet(paste0(data_path,"/raw.parquet")) |> setDT()
# raw <- read_parquet(paste0(data_path,"/rawbit64.parquet")) |> setDT()

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


# filter for all tweets that are part of the reply network (repliying or replied to)
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

gt_filtered <- gt |> 
  delete_vertices(which(igraph::components(gt)$membership %in% which(igraph::components(gt)$csize < 3)))

d_filtered <- d[d$id %in% names(V(gt_filtered)), ]


# === === === === === === === === === === === === === === === === === === === == 
# == Create Threads and get Thread Information ==
# Now the tweet-threads are decomposed and their information is added to the individual rows. 
# For each tweet I want to know what roottweet it had, what position in the tree it has and what the leadratio is, maybe later also populist rhetoric amount

threads <- decompose(gt) 

# list of threads containing nodeIDs
threadid_lookup <- lapply(threads, \(thread) names(V(thread)))

# adding the threads position in the list e,g, [[2]] to d
d[lapply(seq_along(threadid_lookup), 
         \(i) data.table(id = threadid_lookup[[i]], thread_id = i)) |>
    rbindlist(), 
  on = "id", 
  thread_id := i.thread_id]

d$thread_id |> head()

# Step 1: Create threadinfo with ONE row per thread (not per node!)
threadinfo <- lapply(threads, function(thread) {
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
tweet_depth <- threads |>
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


# === === === === === === === === === === === === === === === === === === === == 
# Create final user network


# schreiben was tweet und was kante ist





