# Live-LLaVA

Live-LLaVA provides prompt-driven video understanding for edge devices, supporting both MP4 files and USB camera streams with real-time subtitle output.

Upstream project: <https://github.com/hsulin0806/nano_llm-unified>

- **Category**: General Edge Vision AI

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
docker run --runtime=nvidia --network host --ipc=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -e DISPLAY=:1 \
  -e QT_X11_NO_MITSHM=1 \
  -e TOKENIZERS_PARALLELISM=false \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /data:/data \
  nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2 \
  python3 -m nano_llm.vision.video \
    --api hf \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 64 \
    --video-input /data/my_video.mp4 \
    --video-output display://0 \
    --prompt 'What changes occurred in the video?' \
    --infer-interval-sec 2.5 \
    --subtitle-hold-sec 2.5 \
    --subtitle-max-chars 220 \
    --subtitle-line-chars 0 \
    --subtitle-max-lines 4
```

## Setup 3: Run USB camera inference
```bash
docker run --runtime=nvidia --network host --ipc=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -e DISPLAY=:1 \
  -e QT_X11_NO_MITSHM=1 \
  -e TOKENIZERS_PARALLELISM=false \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /data:/data \
  --device /dev/video0:/dev/video0 \
  nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2 \
  python3 -m nano_llm.vision.video \
    --api hf \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 64 \
    --video-input /dev/video0 \
    --video-output display://0 \
    --prompt 'What changes occurred in the video?' \
    --infer-interval-sec 2.5 \
    --subtitle-hold-sec 2.5 \
    --subtitle-max-chars 220 \
    --subtitle-line-chars 0 \
    --subtitle-max-lines 4
```

## Setup 4: Cross-device deployment (optional)
Build machine export:
```bash
docker save nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2 | gzip > nano_llm-r38.4-cu130-v2.tar.gz
```

Target machine import:
```bash
gunzip -c nano_llm-r38.4-cu130-v2.tar.gz | docker load
```

## Result
- MP4 mode: infer and subtitle output in display window.
- USB camera mode: live scene caption updates at configured interval.

---

## Notes

- If `/dev/video0` does not exist:
  ```bash
  ls -l /dev/video*
  ```
- If you see `unrecognized arguments: --infer-interval-sec ...`, use the `...-v2` image tag.
- First-time model download can take longer due to cache warm-up.
