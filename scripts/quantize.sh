#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dtype="${1:-f32}"
quant_type="${2:-Q4_K_M}"
model_dir="${MODEL_DIR:-${repo_root}/gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-${dtype}}"
input_model="${model_dir}/model-text-${dtype}.gguf"
output_model="${model_dir}/model-text-${quant_type}.gguf"

quantize_bin="${LLAMA_QUANTIZE:-${repo_root}/third_party/llama.cpp/build/bin/llama-quantize}"
if [[ ! -x "${quantize_bin}" ]]; then
  cuda_bin="${repo_root}/third_party/llama.cpp/build-cuda/bin/llama-quantize"
  [[ -x "${cuda_bin}" ]] && quantize_bin="${cuda_bin}"
fi

[[ -x "${quantize_bin}" ]] || {
  echo "错误：找不到 llama-quantize，请先运行 scripts/build.sh。" >&2
  exit 1
}
[[ -f "${input_model}" ]] || {
  echo "错误：找不到输入模型：${input_model}" >&2
  exit 1
}

"${quantize_bin}" "${input_model}" "${output_model}" "${quant_type}"
