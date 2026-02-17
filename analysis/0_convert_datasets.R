library(arrow)
library(tidyverse)
library(bit64)

data_path = "/home/thhaase/Documents/synosys_masterthesis"

ids <- c("id", "to_tweetid", "retweeted_id", "quoted_id", 
         "user_id", "to_userid", "retweeted_user_id", "quoted_user_id")

col_spec_char <- cols(
  .default = col_guess(),
  !!!setNames(rep(list(col_character()), length(ids)), ids)
)

# === === === === === === === === === === === === === === === === === === === ==

raw <- rbind(
  read_csv(paste0(data_path,"/bt_follow_2022-02-07_2022-02-14_tweets.csv"),
           col_types = col_spec_char),
  read_csv(paste0(data_path,"/bt_track_2022-02-07_2022-02-14_tweets.csv"),
           col_types = col_spec_char)
)

# Save version with character IDs
write_parquet(raw, paste0(data_path,"/raw.parquet"))

# Convert to bit64 integer64 and save
rawbit64 <- raw %>%
  mutate(across(all_of(ids), as.integer64))

write_parquet(rawbit64, paste0(data_path,"/rawbit64.parquet"))

# === === === === === === === === === === === === === === === === === === === ==

reftweets <- rbind(
  read_csv(paste0(data_path,"/bt_follow_2022-02-07_2022-02-14_reftweets_dedup.csv"),
           col_types = col_spec_char),
  read_csv(paste0(data_path,"/bt_track_2022-02-07_2022-02-14_reftweets_dedup.csv"),
           col_types = col_spec_char)
)

# Save version with character IDs
write_parquet(reftweets, paste0(data_path,"/reftweets.parquet"))

# Convert to bit64 integer64 and save
reftweetsbit64 <- reftweets %>%
  mutate(across(all_of(ids), as.integer64))

write_parquet(reftweetsbit64, paste0(data_path,"/reftweetsbit64.parquet"))

raw |> as.data.frame() |> head(2)

#rm(list = ls())