# Live-LLaVA

Live-LLaVA provides prompt-driven video understanding for edge devices, supporting both MP4 files and USB camera streams with real-time subtitle output.

Upstream project: <https://github.com/hsulin0806/nano_llm-unified>

- **Category**: General Edge Vision AI

<p align="center">
  <img src="assets/video_vila_wildfire.gif" width="70%" />
</p>

---

## LLaVA

* LLaVA (Large Language and Vision Assistant)
Combines visual input with a large language model, enabling general-purpose visual-language understanding for captioning, question answering, and scene interpretation.

* Streaming Video Inference Pipeline
Supports continuous inference from MP4 files and live USB camera streams, enabling real-time scene understanding on edge devices.

* Edge Deployment Optimization
Uses Docker-based deployment on JetPack 7 / CUDA 13 platforms to improve portability and simplify deployment across Jetson devices.

## Supported Platform

| Platform | Hardware Spec | OS | Edge AI SDK |
|---|---|---|---|
| AIR-075 | NVIDIA Jetson Thor - RAM: 128/64 GB, Storage: 512 GB | JetPack 7.1 | [Install](https://docs.edge-ai-sdk.advantech.com/docs/Hardware/AI_System/Nvidia/Jetson%20Thor/AIR-075) |

---

# Setup

## Step 1: Download this project
```bash
mkdir -p /opt/Advantech/EdgeAI/EdgeAIHub
cd /opt/Advantech/EdgeAI/EdgeAIHub
git clone https://github.com/hsulin0806/Live-LLaVA
cd Live-LLaVA
```

## Step 2: Prepare build environment
```bash
cd jetson-containers
bash install.sh
```

## Step 3: Verify camera device (for USB camera mode)
```bash
ls -l /dev/video*
```
If no video device is found, check host-side camera connection first.

---

# Development and Deployment

## Setup 1: Build Docker image
```bash
cd jetson-containers
CUDA_VERSION=13.0 jetson-containers build nano_llm

cd ../NanoLLM
docker build -t nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2 -f Dockerfile.overlay .
```

## Setup 2: Run MP4 inference
```bash
IMAGE_TAG=nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2 \
DATA_DIR=/data \
INPUT_MP4=/data/my_video.mp4 \
VIDEO_OUTPUT=display://0 \
docker compose -f docker-compose.mp4.yml up -d
```

## Setup 3: Run USB camera inference
```bash
IMAGE_TAG=nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2 \
DATA_DIR=/data \
CAM_INPUT=/dev/video0 \
VIDEO_OUTPUT=display://0 \
docker compose -f docker-compose.camera.yml up -d
```

## Result
- MP4 mode: infer and subtitle output in display window.
- USB camera mode: live scene caption updates at configured interval.

<p align="center">
  <img src="assets/video_vila_wildfire.gif" width="70%" />
</p>
