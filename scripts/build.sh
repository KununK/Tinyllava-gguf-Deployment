#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
llama_dir="${repo_root}/third_party/llama.cpp"
backend="${1:-cpu}"

if [[ ! -f "${llama_dir}/CMakeLists.txt" ]]; then
  echo "错误：submodule 未初始化，请运行 git submodule update --init --recursive。" >&2
  exit 1
fi

case "${backend}" in
  cpu)
    build_dir="${llama_dir}/build"
    cmake_args=()
    ;;
  cuda)
    build_dir="${llama_dir}/build-cuda"
    cmake_args=(-DGGML_CUDA=ON)
    ;;
  *)
    echo "用法：$0 [cpu|cuda]" >&2
    exit 2
    ;;
esac

cmake -S "${llama_dir}" -B "${build_dir}" \
  -DCMAKE_BUILD_TYPE=Release "${cmake_args[@]}"
cmake --build "${build_dir}" --config Release -j "${BUILD_JOBS:-$(nproc)}"
