#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2}"
DATA_DIR="${1:-/data}"
CAM_INPUT="${2:-/dev/video0}"
VIDEO_OUTPUT="${3:-display://0}"
MODEL="${MODEL:-Efficient-Large-Model/VILA1.5-3b}"
PROMPT="${PROMPT:-What changes occurred in the video?}"

exec docker run --runtime=nvidia --network host --ipc=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -e DISPLAY="${DISPLAY:-:1}" \
  -e QT_X11_NO_MITSHM=1 \
  -e TOKENIZERS_PARALLELISM=false \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "${DATA_DIR}:/data" \
  --device /dev/video0:/dev/video0 \
  "${IMAGE_TAG}" \
  python3 -m nano_llm.vision.video \
    --api hf \
    --model "${MODEL}" \
    --max-images 8 \
    --max-new-tokens 64 \
    --video-input "${CAM_INPUT}" \
    --video-output "${VIDEO_OUTPUT}" \
    --prompt "${PROMPT}" \
    --infer-interval-sec 2.5 \
    --subtitle-hold-sec 2.5 \
    --subtitle-max-chars 220 \
    --subtitle-line-chars 0 \
    --subtitle-max-lines 4
