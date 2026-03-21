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
library(tidyvader)

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

# === Add Vader Scores ===
d |> 
  head() |> 
  tidyvader::vader(text) |> 
  select(compound, pos, neu, neg) |> 
  pull(compound)

d$vader_sentiment <- d |> 
  tidyvader::vader(text) |> 
  pull(compound)

# Aggregate to user level (take first/most recent values per user)
vertex_lookup <- d[, .SD[1], by = user_id, .SDcols = c(
  "user_name",
  "user_screen_name",
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

# ADD POPULISM LABELS & Sentiment scores
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

# CONSTRUCT USERLEVEL POPULISM
# since populism is defined by how strongly a tweet performed at one axis we need to aggregate each dimension separately to again construct a userlevel populism score.
# since this consists of multiple tweets its error
user_level_populism <- user_level_populism <- d[, .(
  n_tweets = .N,
  people_neg_3 = sum(people_score == -3, na.rm = TRUE),
  people_neg_2 = sum(people_score == -2, na.rm = TRUE),
  people_neg_1 = sum(people_score == -1, na.rm = TRUE),
  people_0     = sum(people_score == 0, na.rm = TRUE),
  people_pos_1 = sum(people_score == 1, na.rm = TRUE),
  people_pos_2 = sum(people_score == 2, na.rm = TRUE),
  people_pos_3 = sum(people_score == 3, na.rm = TRUE),
  elite_neg_3 = sum(elite_score == -3, na.rm = TRUE),
  elite_neg_2 = sum(elite_score == -2, na.rm = TRUE),
  elite_neg_1 = sum(elite_score == -1, na.rm = TRUE),
  elite_0     = sum(elite_score == 0, na.rm = TRUE),
  elite_pos_1 = sum(elite_score == 1, na.rm = TRUE),
  elite_pos_2 = sum(elite_score == 2, na.rm = TRUE),
  elite_pos_3 = sum(elite_score == 3, na.rm = TRUE),
  
  antagonism_0     = sum(antagonism_score == 0, na.rm = TRUE),
  antagonism_1     = sum(antagonism_score == 1, na.rm = TRUE),
  antagonism_2     = sum(antagonism_score == 2, na.rm = TRUE),
  antagonism_3     = sum(antagonism_score == 3, na.rm = TRUE),
  antagonism_4     = sum(antagonism_score == 4, na.rm = TRUE),
  antagonism_5     = sum(antagonism_score == 5, na.rm = TRUE),
  antagonism_6     = sum(antagonism_score == 6, na.rm = TRUE),
  
  vader_sentiment_mean  = mean(vader_sentiment),
  vader_sentiment_sd  = sd(vader_sentiment)
), by = .(user_id, user_screen_name, party, thread_root_party)][, `:=`(
  
  people_score = (people_neg_3 * -3 + people_neg_2 * -2 + people_neg_1 * -1 +
                    people_pos_1 *  1 + people_pos_2 *  2 + people_pos_3 *  3) / n_tweets,
  people_sd    = sqrt(
    (people_neg_3 * 9 + people_neg_2 * 4 + people_neg_1 * 1 +
       people_pos_1 * 1 + people_pos_2 * 4 + people_pos_3 * 9) / n_tweets -
      ((people_neg_3 * -3 + people_neg_2 * -2 + people_neg_1 * -1 +
          people_pos_1 *  1 + people_pos_2 *  2 + people_pos_3 *  3) / n_tweets)^2
  ),
  
  elite_score  = (elite_neg_3 * -3 + elite_neg_2 * -2 + elite_neg_1 * -1 +
                    elite_pos_1 *  1 + elite_pos_2 *  2 + elite_pos_3 *  3) / n_tweets,
  elite_sd     = sqrt(
    (elite_neg_3 * 9 + elite_neg_2 * 4 + elite_neg_1 * 1 +
       elite_pos_1 * 1 + elite_pos_2 * 4 + elite_pos_3 * 9) / n_tweets -
      ((elite_neg_3 * -3 + elite_neg_2 * -2 + elite_neg_1 * -1 +
          elite_pos_1 *  1 + elite_pos_2 *  2 + elite_pos_3 *  3) / n_tweets)^2
  ),
  
  antag_score  = (antagonism_1 * 1 + antagonism_2 * 2 + antagonism_3 * 3 +
                    antagonism_4 * 4 + antagonism_5 * 5 + antagonism_6 * 6) / n_tweets,
  antag_sd     = sqrt(
    (antagonism_1 * 1 + antagonism_2 * 4 + antagonism_3 * 9 +
       antagonism_4 * 16 + antagonism_5 * 25 + antagonism_6 * 36) / n_tweets -
      ((antagonism_1 * 1 + antagonism_2 * 2 + antagonism_3 * 3 +
          antagonism_4 * 4 + antagonism_5 * 5 + antagonism_6 * 6) / n_tweets)^2
  )
)][, `:=`(
  # Standard errors of the means
  people_se = people_sd / sqrt(n_tweets),
  elite_se  = elite_sd  / sqrt(n_tweets),
  antag_se  = antag_sd  / sqrt(n_tweets),
  vader_sentiment_se  = vader_sentiment_sd / sqrt(n_tweets)
  
)][, populism_score := fifelse(
  people_score > 0 & elite_score < 0,
  fifelse(antag_score > 0,
          (people_score - elite_score) * antag_score,
          people_score - elite_score),
  0
)][, populism_se := fifelse(
  people_score > 0 & elite_score < 0,
  fifelse(antag_score > 0,
          # SE for (a - b) * c
          sqrt(
            antag_score^2 * (people_se^2 + elite_se^2) +
              (people_score - elite_score)^2 * antag_se^2
          ),
          # SE for (a - b)
          sqrt(people_se^2 + elite_se^2)),
  0
)]
write_parquet(user_level_populism, "../data/user_level_populism.parquet")


pop_matched <- user_level_populism[match(V(g)$name, user_level_populism$user_id)]

for (col in c("people_score", "people_se", "elite_score", "elite_se",
              "antag_score", "antag_se", "populism_score", "populism_se",
              "vader_sentiment_mean", "vader_sentiment_se")) {
  g <- set_vertex_attr(g, col, value = pop_matched[[col]])
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


# Sanitychecks
# Match rate
message(sprintf("Match rate: %.1f%%", 100 * sum(edge_lookup$tweet_id %in% d$id) / nrow(edge_lookup)))
# Edge count preservation
stopifnot(nrow(edge_attrs_dt) == length(edge_tweet_ids))
# Attributes added to graph
stopifnot(all(names(edge_attrs_dt) %in% edge_attr_names(g)))

# Vertex attributes (the aggregated stats)
V(g)$populism_score |> mean(na.rm=T)

# === === === === === === === === === === === === === === === === === === === ==
# Filter to only keep trees underneath politicians tweets

# Delete edges where thread_root_party is NA
g <- delete_edges(g, which(is.na(E(g)$thread_root_party)))

# Remove isolates (vertices with degree 0)
g <- delete_vertices(g, which(igraph::degree(g) == 0))

saveRDS(g, "../data/g.rds")
