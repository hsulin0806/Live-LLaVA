#---
# name: clip_trt
# group: vit
# depends: [pytorch, torchvision, transformers, torch2trt]
# test: test.py
# notes: TensorRT optimized CLIP/SigLIP from https://github.com/dusty-nv/clip_trt
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ADD https://api.github.com/repos/dusty-nv/clip_trt/git/refs/heads/main /tmp/clip_trt_version.json

RUN git clone https://github.com/dusty-nv/clip_trt /opt/clip_trt && \
    cd /opt/clip_trt && \
    uv pip install -r requirements.txt && \
    uv pip install psutil && \
    (uv pip install --no-build-isolation . || (echo '/opt/clip_trt' > /opt/venv/lib/python3.12/site-packages/clip_trt.pth)) && \
    (uv pip show clip_trt || true) && \
    mkdir -p ~/.cache && \
    ln -s /data/models/clip ~/.cache/clip_trt

#ENV PYTHONPATH="${PYTHONPATH}:/opt/clip_trt"
