library(arrow)
library(tidyverse)
library(bit64)

data_path = "/home/thhaase/Documents/synosys_masterthesis"

# Load your data
raw <- read_parquet(paste0(data_path,"/rawbit64.parquet"))
reftweets <- read_parquet(paste0(data_path,"/reftweetsbit64.parquet"))

# === DIAGNOSTIC 1: Are there tweets in reftweets NOT in raw? ===
tweets_only_in_ref <- reftweets %>%
  filter(!id %in% raw$id)

cat("Tweets ONLY in reftweets:", nrow(tweets_only_in_ref), "\n")
cat("Percentage:", round(100 * nrow(tweets_only_in_ref) / nrow(reftweets), 1), "%\n")

# === DIAGNOSTIC 2: Check broken reply chains ===
# For REPLIES only (ignore retweets/quotes for reply network)
replies_raw <- raw %>% filter(!is.na(to_tweetid))

# How many replies point to tweets NOT in raw?
broken_links_raw <- replies_raw %>%
  filter(!to_tweetid %in% raw$id)

cat("\nIn raw only:\n")
cat("  Total replies:", nrow(replies_raw), "\n")
cat("  Replies to missing tweets:", nrow(broken_links_raw), "\n")
cat("  Broken chain %:", round(100 * nrow(broken_links_raw) / nrow(replies_raw), 1), "%\n")

# How many of those missing tweets are in reftweets?
recovered_by_reftweets <- broken_links_raw %>%
  filter(to_tweetid %in% reftweets$id)

cat("  Recovered by reftweets:", nrow(recovered_by_reftweets), "\n")

# === DIAGNOSTIC 3: Full dataset ===
full_data <- rbind(raw, tweets_only_in_ref) %>% distinct(id, .keep_all = TRUE)

replies_full <- full_data %>% filter(!is.na(to_tweetid))
broken_links_full <- replies_full %>%
  filter(!to_tweetid %in% full_data$id)

cat("\nWith reftweets added:\n")
cat("  Total replies:", nrow(replies_full), "\n")
cat("  Replies to missing tweets:", nrow(broken_links_full), "\n")
cat("  Broken chain %:", round(100 * nrow(broken_links_full) / nrow(replies_full), 1), "%\n")