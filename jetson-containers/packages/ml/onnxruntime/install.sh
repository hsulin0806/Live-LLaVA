#!/usr/bin/env bash
set -ex

if [ "$FORCE_BUILD" == "on" ]; then
	echo "Forcing build of onnxruntime ${ONNXRUNTIME_VERSION} (branch=${ONNXRUNTIME_BRANCH}, flags=${ONNXRUNTIME_FLAGS})"
	exit 1
fi

if [ -n "${ONNXRUNTIME_WHEEL_URL}" ]; then
	echo "Trying external ONNX Runtime wheel: ${ONNXRUNTIME_WHEEL_URL}"
	if uv pip install "${ONNXRUNTIME_WHEEL_URL}"; then
		python3 -c 'import onnxruntime as ort; print(ort.__version__); print(ort.get_available_providers())'
		exit 0
	fi
	echo "External wheel install failed, falling back to tarpack/source build"
fi

tarpack install onnxruntime-gpu-${ONNXRUNTIME_VERSION}
uv pip install onnxruntime-gpu==${ONNXRUNTIME_VERSION}

python3 -c 'import onnxruntime as ort; print(ort.__version__); print(ort.get_available_providers())'
