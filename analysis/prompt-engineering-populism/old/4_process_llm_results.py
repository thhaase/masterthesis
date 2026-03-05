import pandas as pd
import numpy as np

data_path = "/home/thhaase/Documents/synosys_internship"

# ---- Load Data ----

dd = pd.read_parquet(f"{data_path}/dd.parquet")
llm_coding_Qwen3B = pd.read_parquet(f"{data_path}/Cluster/llm_coding_Qwen2.5-3B-Instruct.parquet")
llm_coding_gpt120B = pd.read_parquet(f"{data_path}/Cluster/llm_coding2_gpt-oss-120b.parquet")
llm_coding_Qwen235B = pd.read_parquet(f"{data_path}/Cluster/llm_coding_Qwen3-235B-A22B-Instruct-2507-FP8.parquet") \
    .drop(columns=["holistic_redplanation", "holistic_reddescription", "note"])

print(llm_coding_Qwen3B.head())
print(llm_coding_gpt120B.head())
print(llm_coding_Qwen235B.head())
print(dd.head())
 
# ---- Merge Datasets ----

qwen3b_clean = llm_coding_Qwen3B.set_index('id').add_prefix('qwen3b_').reset_index()
gpt_clean = llm_coding_gpt120B.set_index('id').add_prefix('gpt120b_').reset_index()
qwen235b_clean = llm_coding_Qwen235B.set_index('id').add_prefix('qwen235b_').reset_index()

d = dd.merge(qwen3b_clean, on='id', how='left') \
    .merge(gpt_clean, on='id', how='left') \
    .merge(qwen235b_clean, on='id', how='left')

# ---- Calculate Populism Scores ----
# Logic: If (populist > 0 AND elitist < 0), then (populist - elitist) * intensity. Else 0.

d['qwen3b_populism'] = np.where(
    (d['qwen3b_populist_score'] > 0) & (d['qwen3b_elitist_score'] < 0),
    (d['qwen3b_populist_score'] - d['qwen3b_elitist_score']) * d['qwen3b_intensity_score'],
    0
)

d['gpt120b_populism'] = np.where(
    (d['gpt120b_populist_score'] > 0) & (d['gpt120b_elitist_score'] < 0),
    (d['gpt120b_populist_score'] - d['gpt120b_elitist_score']) * d['gpt120b_intensity_score'],
    0
)

d['qwen235b_populism'] = np.where(
    (d['qwen235b_populist_score'] > 0) & (d['qwen235b_elitist_score'] < 0),
    (d['qwen235b_populist_score'] - d['qwen235b_elitist_score']) * d['qwen235b_intensity_score'],
    0
)

d['llm_populism_mean'] = d[['gpt120b_populism', 'qwen235b_populism']].mean(axis=1)

# ---- Save Data ----
d.to_parquet(f'{data_path}/d_with_llm_results.parquet')