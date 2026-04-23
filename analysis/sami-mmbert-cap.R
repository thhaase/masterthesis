library(arrow)
library(tidyverse)
library(reticulate)

use_condaenv("mmbert", conda = "/home/thhaase/miniforge3/bin/conda")
transformers <- import("transformers")
pipe <- transformers$pipeline("text-classification", model = "Sami92/mmbert-cap")

setwd("~/Github/masterthesis/analysis")
d <- read_parquet("../data/d_raw.parquet")

batch_size <- 8
batches <- split(d$text, ceiling(seq_along(d$text) / batch_size))

results_raw <- vector("list", length(batches))
for (i in seq_along(batches)) {
  cat(sprintf("Batch %d / %d\n", i, length(batches)))
  results_raw[[i]] <- pipe(batches[[i]])
}

df_results <- map_dfr(list_c(results_raw), ~ data.frame(label = .x$label, score = .x$score))

d <- bind_cols(head(d,nrow(df_results)), df_results) |> 
  mutate(populism_score = ifelse(people_score > 0 & elite_score < 0,
                                 ifelse(antagonism_score > 0,
                                        (people_score - elite_score) * antagonism_score,
                                        people_score - elite_score),
                                 0)
  )

 
ggplot(d, aes(x = populism_score, y=label)) +
  geom_point(alpha = 0.3, position = position_jitter(height = 0.2)) +
  labs(y = "", x="Populism Score") +
  theme_classic()
