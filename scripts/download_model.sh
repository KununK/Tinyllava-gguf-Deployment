#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
model_id="${MODEL_ID:-Zhang199/TinyLLaVA-Qwen2-0.5B-SigLIP}"
model_dir="${MODEL_DIR:-${repo_root}/hf_models/TinyLLaVA-Qwen2-0.5B-SigLIP}"

command -v hf >/dev/null 2>&1 || {
  echo "错误：未找到 hf 命令。请安装 huggingface_hub[cli]。" >&2
  exit 1
}

mkdir -p "${model_dir}"
hf download "${model_id}" --local-dir "${model_dir}"
