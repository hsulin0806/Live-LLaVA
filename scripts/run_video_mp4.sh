#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-nano_llm:r38.4.tegra-aarch64-cu130-24.04}"
DATA_DIR="${1:-/data}"
INPUT_MP4="${2:-/data/my_video.mp4}"
OUTPUT_MP4="${3:-/data/my_output.mp4}"
MODEL="${MODEL:-Efficient-Large-Model/VILA1.5-3b}"
PROMPT="${PROMPT:-What changes occurred in the video?}"

exec docker run --rm --runtime=nvidia --network host \
  -v "${DATA_DIR}:/data" \
  "${IMAGE_TAG}" \
  python3 -m nano_llm.vision.video \
    --model "${MODEL}" \
    --max-images 8 \
    --max-new-tokens 48 \
    --video-input "${INPUT_MP4}" \
    --video-output "${OUTPUT_MP4}" \
    --prompt "${PROMPT}"
