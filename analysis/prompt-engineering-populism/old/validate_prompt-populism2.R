library(arrow)
library(bit64)

library(googlesheets4)

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


llm <- read_sheet("https://docs.google.com/spreadsheets/d/1dCC8dRYiHFVBdL6gwIuurDJbsbSSA6YWYjYpz6hkvQc/edit?gid=807094131#gid=807094131", 
                  sheet = "prompt-populism2")
llm <- llm |> 
  data_modify(id = as.character(id)) |> 
  data_select(c("id", "text", ends_with("score"))) |> 
  data_modify(
    qwen_populism = ifelse(
      people_score > 0 & elite_score < 0,
      (people_score - elite_score) * antagonism_score,
      0
    )
  )

llm$people_score |> table() |> barplot(log = "y")
llm$elite_score |> table() |> barplot(log = "y")
llm$antagonism_score |> table() |> barplot(log = "y")
# === === === === === === === === === === === === === === === === === === === ==


tokenizer <- transformers$AutoTokenizer$from_pretrained(model_path)
model     <- transformers$AutoModelForSequenceClassification$from_pretrained(model_path)
model <- torch$compile(model)
model$eval()


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

results <- classify_texts(llm$text, batch_size = 2L)


llm$xid <- 1:nrow(llm)
results$xid <- 1:nrow(results)
d  <- data_join(llm, results, join = "left", by = "xid")

data_write(d, "validate-prompt-populism2.csv")
d <- data_read("validate-prompt-populism2.csv")
# === === === === === === === === === === === === === === === === === === === ==
# Explore results
# === === === === 
calc_accuracy <- function(table){ sum(diag(table)) / sum(table) }

# OVERVIEW
d |> 
  data_select(c(people_score, elite_score, antagonism_score, final_score,
              pred_people_centrism, pred_anti_elitism, pred_left_wing, pred_right_wing)) |> 
  correlation() |> 
  summary() |> 
  plot()

# POPULIST SCORE
table(d$pred_people_centrism, ifelse(d$people_score < 0,1,d$people_score)) 
table(d$pred_people_centrism, ifelse(d$people_score < 0,1,d$people_score)) |> calc_accuracy()

tree <- tree::tree(as.factor(people_score) ~ ., 
             data = d[,-c(1,2,6,7,8)] |> 
               data_select(-c(starts_with("prob"))))
summary(tree)
plot(tree)
text(tree)


# ANTI ELITISM
table(d$pred_anti_elitism, ifelse(d$elite_score < 0,1,d$elite_score)) 
table(d$pred_anti_elitism, ifelse(d$elite_score < 0,1,d$elite_score)) |> calc_accuracy()

tree <- tree::tree(as.factor(pred_anti_elitism) ~ ., 
             data = d[,-c(1,2,6,7,8)] |> 
               data_select(-c(starts_with("prob"))))
summary(tree)
plot(tree)
text(tree)



# FINAL SCORE

tree <- tree::tree(as.factor(final_score) ~ ., 
             data = d[,-c(1,2,7,8)] |> 
               data_select(-c(starts_with("prob"))))
summary(tree)
plot(tree)
text(tree)



d[,-c(1,2,12)] |> 
  FactoMineR::PCA()

save.image("bert_test")
load("bert_test")
