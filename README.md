# Live-LLaVA

Live-LLaVA provides prompt-driven video understanding for edge devices, supporting both MP4 files and USB camera streams with real-time subtitle output.

Upstream project: <https://github.com/hsulin0806/nano_llm-unified>

- **Category**: General Edge Vision AI

<p align="center">
  <img src="assets/video_vila_wildfire.gif" width="70%" />
</p>

---

## Live-LLaVA

- **Video LLM Inference (MP4 / Camera)**  
  Run visual-language inference from MP4 files or live USB camera input.
- **JetPack 7 / CUDA 13.0 Deployment Flow**  
  Includes build and run commands for Jetson-based deployment.
- **Docker-based Portability**  
  Supports image export/import for fast cross-device deployment.

## Supported Platform

| Platform | Hardware Spec | OS | Runtime |
|---|---|---|---|
| NVIDIA Jetson family | Jetson device with GPU acceleration | JetPack 7 / Ubuntu 24.04 | Docker + NVIDIA runtime |

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
