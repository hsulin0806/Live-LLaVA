#!/usr/bin/env bash
set -ex

cd /opt
git clone --depth=1 https://github.com/NVIDIA-AI-IOT/torch2trt

cd torch2trt
ls -R /tmp/torch2trt
cp /tmp/torch2trt/flattener.py torch2trt


# Install TensorRT python bindings for current interpreter
PY_TAG=$(python3 -c 'import sys; print(f"cp{sys.version_info.major}{sys.version_info.minor}")')
TRT_WHEEL=$(find /usr -name "tensorrt-*-${PY_TAG}-*-linux_aarch64.whl" -print -quit)

if [ -f "$TRT_WHEEL" ]; then
    echo "Installing TensorRT wheel for ${PY_TAG}: $TRT_WHEEL"
    uv pip install "$TRT_WHEEL"
else
    echo "No TensorRT wheel found for ${PY_TAG}, trying system dist-packages fallback"
    if [ -d /usr/lib/python3/dist-packages ]; then
        SITE_PACKAGES=$(python3 -c 'import site; print(site.getsitepackages()[0])')
        echo "/usr/lib/python3/dist-packages" > "${SITE_PACKAGES}/_system_dist_packages.pth"
    fi

    python3 - <<'PY'
import sys
try:
    import tensorrt
    print(f"Using TensorRT python fallback: {tensorrt.__version__}")
except Exception as e:
    raise SystemExit(f"TensorRT python bindings not available for this Python ({sys.version}): {e}")
PY
fi

# JP7/cu130 builds can miss TensorRT dev link targets during torch2trt plugin link step.
# Install python package only by default (no native plugins), which is sufficient for nano_llm runtime path.
python3 setup.py install

# Optional native build path (disabled by default)
if [ "${TORCH2TRT_BUILD_NATIVE:-0}" = "1" ]; then
    sed 's|^set(CUDA_ARCHITECTURES.*|#|g' -i CMakeLists.txt
    sed 's|Catch2_FOUND|False|g' -i CMakeLists.txt

    cmake -B build \
      -DCUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} \
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5 .

    cmake --build build --target install
    ldconfig
fi

uv pip install --no-build-isolation onnx-graphsurgeon
