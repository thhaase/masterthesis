library(tidyverse)

data_path = "/home/thhaase/Documents/synosys_masterthesis"

p <- read_csv(paste0(data_path,"/politicians.csv"))
pp <- read_csv(paste0(data_path,"/politicians_enrichment_duckduckgo.csv"))              

pp <- pp |> 
  mutate(politician_name = str_extract(query, "(?<=%22).+?(?=%22)") |>
           str_replace_all("\\+", " ")) |> 
  select(politician_name, result_1)

p <- p |>
  left_join(pp, by = "politician_name") |>
  mutate(x_url = coalesce(x_url, result_1)) |>
  select(-result_1)

p$x_url |> is.na() |> sum()

write.csv(p, paste0(data_path,"/politicians.csv"))

rm(list = ls())
