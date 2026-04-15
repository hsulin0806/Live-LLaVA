#!/usr/bin/env bash
# Install cuDNN
set -eux

echo "Installing cuDNN ${CUDNN_VERSION}..."

cd ${TMP:-/tmp}

if [ -n "${CUDNN_URL:-}" ]; then
    # Download cuDNN .deb file
    wget ${WGET_FLAGS} ${CUDNN_URL}

    # Install the repository package
    dpkg -i *.deb

    # Copy keyring
    cp /var/cudnn-*-repo-*/cudnn-*-keyring.gpg /usr/share/keyrings/ 2>/dev/null || true
    cp /var/cudnn-*-repo-*-*/cudnn-local-*-keyring.gpg /usr/share/keyrings/ 2>/dev/null || true
else
    # Fallback to CUDA network repo packages (used for JP7 CUDA 13.0)
    REPO_ARCH="x86_64"
    if [ "${CUDA_ARCH:-}" = "tegra-aarch64" ] || [ "${IS_TEGRA:-0}" = "1" ] || [ "$(uname -m)" = "aarch64" ]; then
        REPO_ARCH="arm64"
    fi
    wget ${WGET_FLAGS} \
      "https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/${REPO_ARCH}/cuda-keyring_1.1-1_all.deb" \
      -O cuda-keyring.deb
    dpkg -i cuda-keyring.deb
fi


# Update and install cuDNN packages
apt-get update
apt-get install -y --no-install-recommends ${CUDNN_PACKAGES}

# Cleanup
dpkg -P ${CUDNN_DEB} 2>/dev/null || true
dpkg --purge cuda-keyring 2>/dev/null || true
rm -f /etc/apt/sources.list.d/cuda-*-keyring.list
rm -f /etc/apt/preferences.d/cuda-repository-pin-600
rm -f /usr/share/keyrings/cuda-archive-keyring.gpg
rm -rf /var/lib/apt/lists/*
apt-get clean
rm -rf /tmp/*.deb
rm -rf /*.deb
echo "cuDNN ${CUDNN_VERSION} installed successfully"
