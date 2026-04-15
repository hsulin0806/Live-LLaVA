# Installation

## JetPack 7 (L4T R38) + CUDA 13.0 (validated flow)

If you are on JetPack 7 (for example L4T `38.4.x`) and need CUDA `13.0` only, use a patched `jetson-containers` build chain and run NanoLLM from the resulting local image tag:

```bash
# clone once
git clone https://github.com/dusty-nv/jetson-containers
cd jetson-containers
bash install.sh

# build NanoLLM image (JP7 + CUDA 13.0)
CUDA_VERSION=13.0 jetson-containers build nano_llm

# run it
jetson-containers run nano_llm:r38.4.tegra-aarch64-cu130-24.04
```

### Quick runtime smoke tests

```bash
# import smoke
python3 - <<'PY'
import numpy, jetson_utils
print('numpy', numpy.__version__)
print('videoSource', hasattr(jetson_utils, 'videoSource'))
PY
```

```bash
# mp4 smoke (replace file path if needed)
python3 -u - <<'PY'
from jetson_utils import videoSource
src = videoSource('/data/smoke.mp4')
img = src.Capture(timeout=5000)
print('capture_ok', img is not None)
PY
```

### Offline 2nd-run cache check (HuggingFace)

```bash
# first run with network to warm cache
python3 - <<'PY'
from huggingface_hub import snapshot_download
print(snapshot_download('hf-internal-testing/tiny-random-bert'))
PY

# second run offline
HF_HUB_OFFLINE=1 python3 - <<'PY'
from huggingface_hub import snapshot_download
print(snapshot_download('hf-internal-testing/tiny-random-bert', local_files_only=True))
PY
```

> Note: `csi://0` requires `nvargus-daemon` and camera device availability on host. In headless/test environments without Argus, camera open may timeout but should not crash.

Having a complex set of dependencies, currently the recommended installation method is by running the Docker container image built by [jetson-containers](https://github.com/dusty-nv/jetson-containers).  First, clone and install that repo:

```bash
git clone https://github.com/dusty-nv/jetson-containers
bash jetson-containers/install.sh
```

Then you can start the `nano_llm` container like this:

```bash
jetson-containers run $(autotag nano_llm)
```

For this private development fork, public image release cadence/listing is not used. Build and run your own image tags from this repo/branch (for example `nano_llm:r38.4.tegra-aarch64-cu130-24.04`).

### Container Images (private fork)

This project is maintained as private development. There is no public monthly/bi-weekly image release stream in this fork.

Use locally built tags, for example:

```bash
jetson-containers run nano_llm:r38.4.tegra-aarch64-cu130-24.04
```

### Running Models

Once in the container, you should be able to `import nano_llm` in a Python3 interpreter, and run the various example commands from the docs like:

```bash
python3 -m nano_llm.chat --model meta-llama/Llama-2-7b-chat-hf --api=mlc --quantization q4f16_ft
```

Or you can run the container & chat command in one go like this:

```bash
jetson-containers run \
  --env HUGGINGFACE_TOKEN=hf_abc123def \
  $(./autotag nano_llm) \
  python3 -m nano_llm.chat --api=mlc \
    --model meta-llama/Llama-2-7b-chat-hf \
    --quantization q4f16_ft
```

Setting your `$HUGGINGFACE_TOKEN` is for models requiring authentication to download (like Llama-2)

### Building In Other Containers

You can either add NanoLLM on top of your container by using it as a base image, or using NanoLLM as the base image in your Dockerfile.  When doing the former use the `--base` argument to `jetson-containers/build.sh` to build it off your container:

```
jetson-containers/build.sh --base my_container:latest --name my_container:llm nano_llm
```

Doing so will also install all the needed dependencies on top of your container (including CUDA, PyTorch, the LLM inference APIs, ect).  It should be based on the same version of Ubuntu as JetPack.  

And in the event that you want to add your own container on top of NanoLLM - thereby skipping its build process - then you can just use a FROM statement (like `FROM dustynv/nano_llm:r36.2.0`) at the top of your Dockerfile.  Or you can make your own [package](https://github.com/dusty-nv/jetson-containers/blob/master/docs/packages.md) with jetson-containers for it. 
