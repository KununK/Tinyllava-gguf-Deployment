#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
llama_dir="${repo_root}/third_party/llama.cpp"
factory_dir="${repo_root}/third_party/TinyLLaVA_Factory"
model_dir="${MODEL_DIR:-${repo_root}/hf_models/TinyLLaVA-Qwen2-0.5B-SigLIP}"
dtype="${1:-f32}"
output_dir="${OUTPUT_DIR:-${repo_root}/gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-${dtype}}"

case "${dtype}" in
  f32|f16|bf16|q8_0) ;;
  *)
    echo "错误：dtype 应为 f32、f16、bf16 或 q8_0。" >&2
    exit 2
    ;;
esac

[[ -f "${model_dir}/config.json" ]] || {
  echo "错误：模型不存在：${model_dir}。请先运行 scripts/download_model.sh。" >&2
  exit 1
}
[[ -d "${factory_dir}/tinyllava" ]] || {
  echo "错误：TinyLLaVA_Factory submodule 未初始化。" >&2
  exit 1
}

mkdir -p "${output_dir}"
export PYTHONPATH="${llama_dir}/gguf-py:${factory_dir}:${PYTHONPATH:-}"

python "${llama_dir}/tools/mtmd/convert_TinyLLaVA_to_gguf.py" \
  --model-dir "${model_dir}" \
  --dtype "${dtype}" \
  --output-dir "${output_dir}"
