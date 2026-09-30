# TinyLLaVA GGUF Deployment

将 [`Zhang199/TinyLLaVA-Qwen2-0.5B-SigLIP`](https://huggingface.co/Zhang199/TinyLLaVA-Qwen2-0.5B-SigLIP) 转换为 GGUF、量化文本模型，并通过带 TinyLLaVA 支持的 `llama.cpp` 在 CPU 或 CUDA 上运行。

本仓库用于部署复现和工作交接，只保存脚本、文档及固定的上游源码版本。模型权重、GGUF、编译产物和运行日志不会提交到 Git。

## 固定版本

| 组件 | 上游仓库 | 分支/提交 |
| --- | --- | --- |
| llama.cpp（TinyLLaVA fork） | `dnvtmf/llama.cpp` | `TinyLLaVA` / `4e2edbb28749852a9ff6afd522d69b5e6e4374cd` |
| TinyLLaVA Factory | `TinyLLaVA/TinyLLaVA_Factory` | `main` / `48a0bf1` |
| 模型 | `Zhang199/TinyLLaVA-Qwen2-0.5B-SigLIP` | Hugging Face 仓库当前文件 |

> `TinyLLaVA_Factory` 是转换阶段的 Python 依赖；仅运行已转换的 GGUF 时不需要它。

## 仓库结构

```text
.
├── README.md
├── scripts/
│   ├── build.sh
│   ├── convert.sh
│   ├── download_model.sh
│   ├── quantize.sh
│   └── run.sh
└── third_party/
    ├── llama.cpp/             # Git submodule
    └── TinyLLaVA_Factory/     # Git submodule
```

## 1. 克隆仓库

```bash
git clone --recursive https://github.com/KununK/Tinyllava-gguf-Deployment.git
cd Tinyllava-gguf-Deployment
```

如果克隆时没有使用 `--recursive`：

```bash
git submodule update --init --recursive
```

## 2. 系统依赖

Ubuntu/Debian：

```bash
sudo apt update
sudo apt install -y cmake build-essential libcurl4-openssl-dev python3-venv
```

原部署笔记中的 `cmak` 和 `libcurl4-openssl-de` 是截断的包名，这里已分别修正为 `cmake` 和 `libcurl4-openssl-dev`。

建议创建独立 Python 环境：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
```

安装 Hugging Face CLI、转换工具依赖和 TinyLLaVA Factory：

```bash
python -m pip install "huggingface_hub[cli]"
python -m pip install -r third_party/llama.cpp/tools/mtmd/requirements.txt
python -m pip install -e third_party/TinyLLaVA_Factory
```

原部署环境曾将 `TinyLLaVA_Factory/pyproject.toml` 中部分严格依赖版本放宽，以适配已有 CUDA/Python 环境。该临时修改没有纳入本仓库。若安装发生 PyTorch、CUDA 或 Python 版本冲突，应优先建立单独虚拟环境并记录最终验证版本，不建议直接无约束升级全部依赖。

## 3. 下载模型

```bash
./scripts/download_model.sh
```

等价命令：

```bash
mkdir -p hf_models
hf download Zhang199/TinyLLaVA-Qwen2-0.5B-SigLIP \
  --local-dir hf_models/TinyLLaVA-Qwen2-0.5B-SigLIP
```

## 4. 转换为 GGUF

默认转换为 F32：

```bash
./scripts/convert.sh f32
```

也可转换为 F16，以减少磁盘占用：

```bash
./scripts/convert.sh f16
```

转换脚本会生成独立的文本模型和视觉模型：

```text
gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-text-f32.gguf
gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-vision-f32.gguf
```

原部署的 F32 产物约为：

| 文件 | 大小 |
| --- | ---: |
| `model-text-f32.gguf` | 2.53 GB |
| `model-vision-f32.gguf` | 1.72 GB |

原部署的 F16 产物约为：

| 文件 | 大小 |
| --- | ---: |
| `model-text-f16.gguf` | 1.27 GB |
| `model-vision-f16.gguf` | 873 MB |

## 5. 编译 llama.cpp

CPU 构建：

```bash
./scripts/build.sh cpu
```

CUDA 构建：

```bash
./scripts/build.sh cuda
```

CUDA 构建前需要确保 `nvcc` 和目标 CUDA Toolkit 已进入当前 shell 的环境。原机器使用：

```bash
source switch-cuda 12.6
```

`switch-cuda` 是原部署机器提供的环境切换命令，并不是 Ubuntu、CUDA 或本仓库的标准命令。其他机器应使用自身的 CUDA module、`PATH` 和 `LD_LIBRARY_PATH` 配置方式。

## 6. 量化文本模型

F32 文本模型量化为 Q4_K_M：

```bash
./scripts/quantize.sh f32 Q4_K_M
```

输出：

```text
gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-text-Q4_K_M.gguf
```

原部署的 Q4_K_M 文本模型约为 491 MB。视觉模型不执行该文本量化步骤，运行时继续使用转换生成的 `model-vision-f32.gguf` 或 `model-vision-f16.gguf`。

## 7. 启动推理

使用 Q4_K_M 文本模型和 F32 视觉模型进入交互模式：

```bash
./scripts/run.sh
```

进入 CLI 后：

```text
> /image /path/to/your_image.jpg
> 请用中文描述图片内容，并回答一些问题。
```

等价的原始命令为：

```bash
third_party/llama.cpp/build/bin/llama-mtmd-cli \
  -m gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-text-Q4_K_M.gguf \
  --mmproj gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-vision-f32.gguf \
  -t 8 -c 4096 -v
```

线程数和上下文长度可以覆盖：

```bash
THREADS=16 CONTEXT_SIZE=4096 ./scripts/run.sh
```

也可以显式指定模型：

```bash
TEXT_MODEL=/path/to/model-text.gguf \
VISION_MODEL=/path/to/model-vision.gguf \
./scripts/run.sh
```

## 完整部署记录（整理版）

以下流程对应首次成功部署时的操作，路径已改成仓库相对路径：

```bash
# 0. 系统依赖
sudo apt install -y cmake build-essential libcurl4-openssl-dev

# 1. 获取本仓库及两个固定版本的上游源码
git clone --recursive https://github.com/KununK/Tinyllava-gguf-Deployment.git
cd Tinyllava-gguf-Deployment

# 2. 下载模型
mkdir -p hf_models
hf download Zhang199/TinyLLaVA-Qwen2-0.5B-SigLIP \
  --local-dir hf_models/TinyLLaVA-Qwen2-0.5B-SigLIP

# 3. TinyLLaVA -> GGUF
python -m pip install -e third_party/TinyLLaVA_Factory
export PYTHONPATH="$PWD/third_party/llama.cpp/gguf-py:${PYTHONPATH:-}"
python third_party/llama.cpp/tools/mtmd/convert_TinyLLaVA_to_gguf.py \
  -m hf_models/TinyLLaVA-Qwen2-0.5B-SigLIP \
  --dtype f32 \
  -o gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32

# 4a. CPU 构建
cmake -S third_party/llama.cpp -B third_party/llama.cpp/build \
  -DCMAKE_BUILD_TYPE=Release
cmake --build third_party/llama.cpp/build --config Release -j

# 4b. CUDA 构建（如需要，先切换到正确的 CUDA 环境）
cmake -S third_party/llama.cpp -B third_party/llama.cpp/build-cuda \
  -DCMAKE_BUILD_TYPE=Release -DGGML_CUDA=ON
cmake --build third_party/llama.cpp/build-cuda --config Release -j

# 5. 量化 text 模型
third_party/llama.cpp/build/bin/llama-quantize \
  gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-text-f32.gguf \
  gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-text-Q4_K_M.gguf \
  Q4_K_M

# 6. 启动交互测试
third_party/llama.cpp/build/bin/llama-mtmd-cli \
  -m gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-text-Q4_K_M.gguf \
  --mmproj gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/model-vision-f32.gguf \
  -t 8 -c 4096 -v
```

## 交接检查

查看依赖版本：

```bash
git submodule status
python --version
cmake --version
gcc --version
nvcc --version  # 仅 CUDA 环境
```

对生成的模型保存校验值：

```bash
sha256sum gguf/TinyLLaVA-Qwen2-0.5B-SigLIP-f32/*.gguf
```

排障要点：

- 找不到 `tinyllava`：确认执行过 `python -m pip install -e third_party/TinyLLaVA_Factory`。
- 找不到 `gguf`：确认安装了 `tools/mtmd/requirements.txt`，并检查 `PYTHONPATH`。
- 找不到 `llama-mtmd-cli`：确认构建使用的是本仓库固定的 TinyLLaVA fork，而不是普通官方分支。
- CUDA 构建失败：先确认 `nvcc --version`、驱动版本以及 CMake 检测到的 CUDA Toolkit。
- 内存不足：优先执行 F16 转换；转换和量化过程仍需预留足够内存与磁盘空间。

## 模型文件与许可证

- 本仓库不分发模型权重或 GGUF；请从模型原始页面下载，并遵守其许可证。
- 模型卡标注为 Apache-2.0；上游源码许可证分别以各 submodule 中的许可证文件为准。
- 若需要共享量化模型，建议放在单独的 Hugging Face 模型仓库，并附模型来源、转换参数、量化类型和 SHA-256。
