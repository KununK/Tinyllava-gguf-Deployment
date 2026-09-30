#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
model_dir="${repo_root}/gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32"
text_model="${TEXT_MODEL:-${model_dir}/model-text-Q4_K_M.gguf}"
vision_model="${VISION_MODEL:-${model_dir}/model-vision-f32.gguf}"

cli_bin="${LLAMA_MTMD_CLI:-${repo_root}/third_party/llama.cpp/build/bin/llama-mtmd-cli}"
if [[ ! -x "${cli_bin}" ]]; then
  cuda_bin="${repo_root}/third_party/llama.cpp/build-cuda/bin/llama-mtmd-cli"
  [[ -x "${cuda_bin}" ]] && cli_bin="${cuda_bin}"
fi

[[ -x "${cli_bin}" ]] || {
  echo "错误：找不到 llama-mtmd-cli，请先运行 scripts/build.sh。" >&2
  exit 1
}
[[ -f "${text_model}" ]] || {
  echo "错误：找不到文本模型：${text_model}" >&2
  exit 1
}
[[ -f "${vision_model}" ]] || {
  echo "错误：找不到视觉模型：${vision_model}" >&2
  exit 1
}

exec "${cli_bin}" \
  --model "${text_model}" \
  --mmproj "${vision_model}" \
  --threads "${THREADS:-8}" \
  --ctx-size "${CONTEXT_SIZE:-4096}" \
  --verbose \
  "$@"
