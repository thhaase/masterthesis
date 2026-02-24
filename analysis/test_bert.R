library(arrow)
library(bit64)

library(easystats)

# set up python
library(reticulate)
use_condaenv("~/miniforge3/envs/master_thesis/bin/python3.11", required = TRUE)
torch         <- import("torch")
transformers  <- import("transformers")

# set paths
setwd("~/Github/masterthesis/analysis")
data_path = "/home/thhaase/Documents/synosys_masterthesis"
model_path <- "./hf_models/PopBERT"


llm <- read_parquet(paste0(data_path,"/../synosys_internship/d_with_llm_results.parquet"))
llm <- llm |> 
  data_modify(id = as.character(id)) |> 
  data_select(c("id", "text", ends_with("score"))) |> 
  data_select(-c(starts_with("qwen3b"))) |> 
  data_modify(
    gpt120b_populism = ifelse(
      gpt120b_populist_score > 0 & gpt120b_elitist_score < 0,
      (gpt120b_populist_score - gpt120b_elitist_score) * gpt120b_intensity_score,
      0
    ),
    qwen235b_populism = ifelse(
      qwen235b_populist_score > 0 & qwen235b_elitist_score < 0,
      (qwen235b_populist_score - qwen235b_elitist_score) * qwen235b_intensity_score,
      0
    ),
    llm_populism_mean = (gpt120b_populism + qwen235b_populism) / 2
  )

# === === === === === === === === === === === === === === === === === === === ==


tokenizer <- transformers$AutoTokenizer$from_pretrained(model_path)
model     <- transformers$AutoModelForSequenceClassification$from_pretrained(model_path)
model <- torch$compile(model)
#model$eval()


classify_texts <- function(
    texts,
    batch_size  = 8L,
    label_names = c("anti_elitism", "people_centrism", "left_wing", "right_wing"),
    thresholds  = c(0.415961, 0.295400, 0.429109, 0.302714)
) {
  total_texts <- length(texts)
  n_batches   <- ceiling(total_texts / batch_size)
  
  # 1. Pre-allocate R matrix to prevent memory fragmentation
  prob_matrix <- matrix(NA_real_, nrow = total_texts, ncol = length(label_names))
  
  message(sprintf(
    "Starting classification of %d text%s in %d batch%s (batch size: %d) | Labels: %s",
    total_texts, if (total_texts == 1L) "" else "s",
    n_batches, if (n_batches  == 1L) "" else "es",
    batch_size, paste(label_names, collapse = ", ")
  ))
  message(strrep("-", 60))
  
  t_start <- proc.time()[["elapsed"]]
  
  for (i in seq(1, total_texts, by = batch_size)) {
    batch_end <- min(i + batch_size - 1L, total_texts)
    
    # 2. Pass R character vector directly to Python (no as.list)
    batch_texts <- texts[i:batch_end]
    batch_num   <- ceiling(i / batch_size)
    
    pct     <- round(batch_end / total_texts * 100)
    t_now   <- proc.time()[["elapsed"]]
    elapsed <- t_now - t_start
    
    eta_str <- if (batch_num > 1L) {
      remaining <- (n_batches - batch_num + 1L) * (elapsed / (batch_num - 1L))
      sprintf("  ETA: ~%.0fs", remaining)
    } else ""
    
    message(sprintf(
      "[Batch %d/%d] Texts %d-%d (%3d%%) | elapsed: %.1fs%s",
      batch_num, n_batches, i, batch_end, pct, elapsed, eta_str
    ))
    
    # 3. Dynamic Padding: "longest" ensures padding only matches the batch max
    inputs <- tokenizer(
      batch_texts,
      padding        = "longest", 
      truncation     = TRUE,
      max_length     = 512L,
      return_tensors = "pt"
    )
    
    with(torch$no_grad(), {
      outputs <- model(
        input_ids      = inputs$input_ids,
        attention_mask = inputs$attention_mask
      )
    })
    
    # 4. Pull NumPy array once and block-assign into the pre-allocated R matrix
    probs_batch <- torch$sigmoid(outputs$logits)$detach()$cpu()$numpy()
    prob_matrix[i:batch_end, ] <- probs_batch
  }
  
  message(strrep("-", 60))
  message(sprintf("Finished inference in %.1fs. Assembling results ...", proc.time()[["elapsed"]] - t_start))
  
  # 5. Fast base-R assembly
  prob_df <- as.data.frame(prob_matrix) |> 
    setNames(paste0("prob_", label_names))
  
  # 6. Vectorized thresholding across the entire matrix instantly
  pred_matrix <- sweep(prob_matrix, 2, thresholds, ">")
  mode(pred_matrix) <- "integer" # Fast logical-to-integer (1/0) conversion
  
  pred_df <- as.data.frame(pred_matrix) |> 
    setNames(paste0("pred_", label_names))
  
  final_df <- cbind(prob_df, pred_df)
  
  # Summary
  pred_sums <- colSums(pred_matrix)
  message("Prediction summary (positive labels):")
  for (j in seq_along(label_names)) {
    message(sprintf(
      "  %-20s  %d / %d  (%.1f%%)",
      label_names[j], pred_sums[j], total_texts,
      pred_sums[j] / total_texts * 100
    ))
  }
  message(strrep("-", 60))
  
  final_df
}


# === === === === === === === === === === === === === === === === === === === ==

sample <- llm |>
  data_filter(rowSums(data_select(llm,exclude = c("text", "ID", "gpt120b_intensity_score", "qwen235b_intensity_score")) > 0, na.rm = TRUE) > 0) |> 
  data_filter(rownames(llm) %in% sample(1:nrow(llm), 100))

results <- classify_texts(sample$text, batch_size = 2L)


sample$xid <- 1:nrow(sample)
results$xid <- 1:nrow(results)
d  <- data_join(sample, results, join = "left", by = "xid")

data_write(d, "bert_test2.csv")
d <- data_read("bert_test.csv")
# === === === === === === === === === === === === === === === === === === === ==
# Explore results
# === === === === 
calc_accuracy <- function(table){ sum(diag(table)) / sum(table) }

# OVERVIEW
d |> 
  data_select(-c(id,xid,text)) |> 
  data_select(
    c(
      starts_with("gpt120b"),
      #starts_with("prob"),
      starts_with("pred")
      )
    ) |> 
  correlation() |> 
  summary() |> 
  plot()

d |> 
  data_select(-c(id,xid,text)) |> 
  data_select(
    c(
      starts_with("qwen235b"),
      #starts_with("prob"),
      starts_with("pred")
    )
  ) |> 
  correlation(method = "polychoric") |> 
  summary() |> 
  plot()

# POPULIST SCORE
d |> 
  data_select(c(qwen235b_populist_score,
                prob_people_centrism)) |> 
  correlation(method = "biserial") |> summary()
 
d |> 
  data_select(c(gpt120b_populist_score,
                prob_people_centrism)) |> 
  correlation(method = "biserial") |> summary()


tree <- tree::tree(as.factor(pred_people_centrism) ~ ., 
             data = d[,-c(1,2,12)] |> 
               data_select(-c(starts_with("prob"))))
summary(tree)
plot(tree)
text(tree)


# ANTI ELITISM
table(d$pred_anti_elitism, ifelse(d$qwen235b_elitist_score < 0,1,d$qwen235b_elitist_score)) 
table(d$pred_anti_elitism, ifelse(d$qwen235b_elitist_score < 0,1,d$qwen235b_elitist_score)) |> calc_accuracy()

table(d$pred_anti_elitism, ifelse(d$gpt120b_elitist_score < 0,1,d$gpt120b_elitist_score))
table(d$pred_anti_elitism, ifelse(d$gpt120b_elitist_score < 0,1,d$gpt120b_elitist_score)) |> calc_accuracy()

table(d$pred_people_centrism, ifelse(d$qwen235b_populism > 0,1,d$qwen235b_populism))
table(d$pred_people_centrism, ifelse(d$gpt120b_populism > 0,1,d$gpt120b_populism))



tree <- tree::tree(as.factor(pred_anti_elitism) ~ ., 
             data = d[,-c(1,2,12)] |> 
               data_select(-c(starts_with("prob"))))
summary(tree)
plot(tree)
text(tree)



# FINAL SCORE

tree <- tree::tree(as.factor(llm_populism_mean) ~ ., 
             data = d[,-c(1,2,12)] |> 
               data_select(-c(starts_with("gpt"), 
                              starts_with("qwen"),
                              starts_with("prob"))))
summary(tree)
plot(tree)
text(tree)



d[,-c(1,2,12)] |> 
  FactoMineR::PCA()

save.image("bert_test")
load("bert_test")
