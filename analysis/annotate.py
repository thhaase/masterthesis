import os
os.environ["HF_HOME"] = "/data/cat/ws/thha024h-masterthesis/hf_models"
import json
import re
import pandas as pd
from pathlib import Path
from vllm import LLM, SamplingParams

# ——————————————————————————————————————————————————————————————————————————————

#DATA   = "data/bt_follow_2022-02-07_2022-02-14_reftweets_dedup.csv"
#DATA   = "data/bt_follow_2022-02-07_2022-02-14_tweets.csv"
DATA    = "data/bt_track_2022-02-07_2022-02-14_reftweets_dedup.csv"
#DATA    = "data/bt_track_2022-02-07_2022-02-14_tweets.csv"
PROMPT_PATH = "prompt-populism.md"
MODEL  = "hf_models/Qwen3-235B-A22B-Instruct-2507-FP8/"

# ——————————————————————————————————————————————————————————————————————————————

d = pd.read_csv(DATA)

# WHEN TESTING THE SCRIPT
#d = d.head(50)


with open(PROMPT_PATH, "r") as f:
    PROMPT = f.read()

# ——————————————————————————————————————————————————————————————————————————————

llm_kwargs = dict(
    model=MODEL,
    tensor_parallel_size=4
)

sampling_params = SamplingParams(
    temperature=0.2,
    top_p=0.9,
    max_tokens=4048
)
llm = LLM(**llm_kwargs)
tokenizer = llm.get_tokenizer()

to_annotate = d[["id", "text"]].reset_index(drop=True)

# ——————————————————————————————————————————————————————————————————————————————

# PROCESS TEXT
prompts_list = []
rows_list = []
for row in to_annotate.itertuples():
    conversation = [
        {"role": "system", "content": PROMPT},
        {"role": "user",   "content": row.text},
    ]
    formatted_prompt = tokenizer.apply_chat_template(
        conversation,
        tokenize=False,
        add_generation_prompt=True,
    )
    prompts_list.append(formatted_prompt)
    rows_list.append(row)

print(f"Starting inference on {len(prompts_list)} items...")
outputs = llm.generate(prompts_list, sampling_params)

# ——————————————————————————————————————————————————————————————————————————————

STR_KEYS = [
    "holistic_redescription",
    "social_actors_analysis",
    "populist_explanation",
    "elitist_explanation",
    "intensity_explanation",
]
NUM_KEYS = [
    "populist_score",
    "elitist_score",
    "intensity_score",
]
d_results = []
for row, output in zip(rows_list, outputs):
    answer = output.outputs[0].text

    # --- 1. Attempt Standard JSON Parsing ---
    try:
        json_str = answer[answer.find("{"):answer.rfind("}") + 1]
        answer_data = json.loads(json_str)
    except (json.JSONDecodeError, ValueError, AttributeError):
        # --- 2. Regex Fallback ---
        try:
            parsed = {}

            for key in STR_KEYS:
                match = re.search(
                    rf'"{key}"\s*:\s*"(.*?)"\s*(?:,|}}\s*$)',
                    answer,
                    re.DOTALL,
                )
                if match:
                    parsed[key] = match.group(1).replace('"', "'")
                else:
                    parsed[key] = None

            for key in NUM_KEYS:
                match = re.search(rf'"{key}"\s*:\s*(-?\d+)', answer)
                if match:
                    parsed[key] = int(match.group(1))
                else:
                    parsed[key] = None

            answer_data = parsed
        except Exception as regex_error:
            answer_data = {
                "error": f"Parse Failed: {regex_error}",
                "raw_output": answer,
            }

    d_results.append({"id": row.id, **answer_data})

# ——————————————————————————————————————————————————————————————————————————————

# Convert annotations to DataFrame and left-join to original
d_annotations = pd.DataFrame(d_results)
d_out = d.merge(d_annotations, on="id", how="left")

# ——————————————————————————————————————————————————————————————————————————————

# Save as parquet: derive name from DATA
stem = Path(DATA).stem  # e.g. "bt_follow_2022-02-07_2022-02-14_tweets"
out_path = Path(DATA).parent / f"{stem}_annotated_populism.parquet"
d_out.to_parquet(out_path, index=False)
print(f"Saved {len(d_out)} rows to {out_path}")