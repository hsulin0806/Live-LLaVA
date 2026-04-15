#---
# name: onnxruntime
# group: ml
# config: config.py
# depends: [cuda, cudastack:standard, cmake, python, numpy, onnx]
# test: test.py
# notes: https://github.com/microsoft/onnxruntime
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG ONNXRUNTIME_VERSION \
    ONNXRUNTIME_BRANCH \
    ONNXRUNTIME_FLAGS \
    ONNXRUNTIME_WHEEL_URL="" \
    FORCE_BUILD=off

ENV ONNXRUNTIME_WHEEL_URL=${ONNXRUNTIME_WHEEL_URL}

COPY install.sh build.sh /tmp/onnxruntime/

RUN /tmp/onnxruntime/install.sh || /tmp/onnxruntime/build.sh
