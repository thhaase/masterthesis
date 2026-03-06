library(arrow)
library(bit64)
library(parallel)
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

# === === === === === === === === === === === === === === === === === === === == 
# === Load Data ===
# Load both raw and reftweets, then combine
d <- read_parquet("../data/d.parquet") |> setDT()
g <- readRDS("../data/largest_component.rds")

# === === === === === === === === === === === === === === === === === === === == 
# === Add Network Variables ===

# === === === === === === === === 
# === Add Vertex Attributes (User-level data)
# Aggregate to user level (take first/most recent values per user)
vertex_lookup <- d[, .SD[1], by = user_id, .SDcols = c(
  "user_name",
  "user_description", 
  "user_tweets",
  "user_followers",
  "user_friends",
  "user_likes",
  "politician_name",
  "gender",
  "party",
  "x_url"
)]

# Match to vertices
vertex_data <- vertex_lookup[match(V(g)$name, vertex_lookup$user_id)]

# Add all columns to graph vertices at once
for (col in names(vertex_data)) {
  if (col == "user_id") next  # Skip the ID column
  
  # Rename gender to politician_gender
  attr_name <- if (col == "gender") "politician_gender" else col
  
  g <- set_vertex_attr(g, attr_name, value = vertex_data[[col]])
}

# ADD POPULISM LABELS
# final populism score is higher when people score is bigger and elite score is smaller, 
# if then the antagonism score is above 0 it is used as a weight
d[, populism_score := fifelse(
  people_score > 0 & elite_score < 0,
  fifelse(antagonism_score > 0,
          (people_score - elite_score) * antagonism_score,
          people_score - elite_score),
  0
)]
# d$people_score |> table() |> barplot(log = "y")
# d$elite_score |> table() |> barplot(log = "y")
# d$antagonism_score |> table() |> barplot(log = "y")
# d$populism_score |> table() |> barplot(log = "y")

# add to nodes
score_cols <- c("people_score", "elite_score", "antagonism_score", "populism_score")

score_stats <- d[, unlist(lapply(.SD, function(x) {
  list(mean = mean(x, na.rm = TRUE),
       median = median(x, na.rm = TRUE),
       sd = sd(x, na.rm = TRUE))
}), recursive = FALSE), by = user_id, .SDcols = score_cols]

score_data <- score_stats[match(V(g)$name, score_stats$user_id)]

for (col in names(score_data)) {
  if (col == "user_id") next
  g <- set_vertex_attr(g, col, value = score_data[[col]])
}
# === === === === === === === === 
# === Add Edge Attributes ===
# NOTE: Edges are weighted - each edge can represent multiple tweets
# Multiple values are stored as pipe-separated strings:
#   - Text content uses '|||' as separator (since text may contain '|')
#   - All other attributes use '|' as separator

# Get tweet_ids for all edges (some edges have multiple IDs separated by '|')
edge_tweet_ids <- E(g)$tweet_ids

# Function to collapse multiple values with appropriate separator
collapse_values <- function(values, is_text = FALSE) {
  # Remove NA values
  values <- values[!is.na(values)]
  if (length(values) == 0) return(NA_character_)
  
  # Use different separator for text vs other fields
  sep <- if (is_text) "|||" else "|"
  paste(values, collapse = sep)
}

setkey(d, id)

edge_lookup <- strsplit(edge_tweet_ids, "\\|") |>
  (\(splits) data.table(
    edge_idx = rep(seq_along(splits), lengths(splits)),
    tweet_id = unlist(splits)
  ))()

edge_data <- d[edge_lookup, on = .(id = tweet_id), nomatch = NA][
  , edge_idx := edge_lookup$edge_idx
]

edge_attrs_dt <- edge_data[, .(
  text = collapse_values(text, is_text = TRUE),
  timestamp_utc = collapse_values(as.character(timestamp_utc)),
  retweet_count = collapse_values(as.character(retweet_count)),
  like_count = collapse_values(as.character(like_count)),
  reply_count = collapse_values(as.character(reply_count)),
  hashtags = collapse_values(as.character(hashtags)),
  thread_tweet_depth = collapse_values(as.character(thread_tweet_depth)),
  thread_id = collapse_values(as.character(thread_id)),
  thread_size = collapse_values(as.character(thread_size)),
  thread_leaf_pc = collapse_values(as.character(thread_leaf_pc)),
  thread_root_id = collapse_values(as.character(thread_root_id)),
  thread_root_like_count = collapse_values(as.character(thread_root_like_count)),
  thread_root_retweet_count = collapse_values(as.character(thread_root_retweet_count)),
  thread_root_reply_count = collapse_values(as.character(thread_root_reply_count)),
  thread_root_user_name = collapse_values(as.character(thread_root_user_name)),
  thread_root_user_screen_name = collapse_values(as.character(thread_root_user_screen_name)),
  thread_root_party = collapse_values(as.character(thread_root_party)),
  thread_root_user_followers = collapse_values(as.character(thread_root_user_followers)),
  thread_root_user_friends = collapse_values(as.character(thread_root_user_friends)),
  thread_root_user_likes = collapse_values(as.character(thread_root_user_likes)),
  thread_root_user_tweets = collapse_values(as.character(thread_root_user_tweets)),
  
  people_score = collapse_values(as.character(people_score)),
  elite_score = collapse_values(as.character(elite_score)),
  antagonism_score = collapse_values(as.character(antagonism_score)),
  populism_score = collapse_values(as.character(populism_score))
), by = edge_idx]

edge_attrs_dt <- data.table(edge_idx = seq_along(edge_tweet_ids))[
  edge_attrs_dt, on = "edge_idx"
][, edge_idx := NULL]

g <- Reduce(
  function(graph, col) set_edge_attr(graph, col, value = edge_attrs_dt[[col]]),
  names(edge_attrs_dt),
  init = g
)

# add additional aggregates for populism dimensions values
edge_score_stats <- rbindlist(lapply(score_cols, function(col) {
  values <- edge_attr(g, col)
  splits <- strsplit(values, "\\|", fixed = TRUE)
  dt <- data.table(
    edge_idx = rep(seq_along(splits), lengths(splits)),
    val      = as.numeric(unlist(splits)),
    col_name = col
  )
  dt
}))[, .(mean = mean(val, na.rm = TRUE),
        median = median(val, na.rm = TRUE),
        sd     = {s <- sd(val, na.rm = TRUE); fifelse(is.na(s), 0, s)}),
    by = .(col_name, edge_idx)]
for (col in score_cols) {
  subset <- edge_score_stats[col_name == col][order(edge_idx)]
  g <- set_edge_attr(g, paste0(col, "_mean"),   value = subset$mean)
  g <- set_edge_attr(g, paste0(col, "_median"), value = subset$median)
  g <- set_edge_attr(g, paste0(col, "_sd"),     value = subset$sd)
}
# Sanitychecks
# Match rate
message(sprintf("Match rate: %.1f%%", 100 * sum(edge_lookup$tweet_id %in% d$id) / nrow(edge_lookup)))
# Edge count preservation
stopifnot(nrow(edge_attrs_dt) == length(edge_tweet_ids))
# Attributes added to graph
stopifnot(all(names(edge_attrs_dt) %in% edge_attr_names(g)))

# Vertex attributes (the aggregated stats)
V(g)$populism_score.mean |> mean(na.rm=T)
V(g)$populism_score.median |> mean(na.rm=T)
V(g)$populism_score.sd |> mean(na.rm=T)

# Edge attributes (pipe-separated per-tweet values)
E(g)$populism_score_mean |> mean(na.rm=T)
E(g)$populism_score_median |> mean(na.rm=T)
E(g)$populism_score_sd |> table()

# === === === === === === === === === === === === === === === === === === === ==
# Filter to only keep trees underneath politicians tweets

# Delete edges where thread_root_party is NA
g <- delete_edges(g, which(is.na(E(g)$thread_root_party)))

# Remove isolates (vertices with degree 0)
g <- delete_vertices(g, which(igraph::degree(g) == 0))

saveRDS(g, "../data/g.rds")

rm(list = ls())
.rs.restartR()
