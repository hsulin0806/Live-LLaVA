#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2}"
DATA_DIR="${1:-/data}"
INPUT_MP4="${2:-/data/my_video.mp4}"
VIDEO_OUTPUT="${3:-display://0}"
MODEL="${MODEL:-Efficient-Large-Model/VILA1.5-3b}"
PROMPT="${PROMPT:-What changes occurred in the video?}"

export IMAGE_TAG DATA_DIR MODEL INPUT_MP4 VIDEO_OUTPUT PROMPT
exec docker compose -f docker-compose.mp4.yml up -d
