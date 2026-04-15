#---
# name: jetson-utils
# group: multimedia
# depends: [cuda, cudastack:standard, python, cmake, gstreamer]
# test: [test.sh]
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG JETSON_UTILS_REPO=dusty-nv/jetson-utils \
    JETSON_UTILS_BRANCH=master \
    JETSON_UTILS_CMAKE=on \
    JETSON_UTILS_PIP=on

RUN if [ "$JETSON_UTILS_CMAKE" = "on" ]; then \
        apt-get update ; \
        apt-get install -y --no-install-recommends \
		    libglew-dev \
		    glew-utils \
		    libsoup2.4-dev \
		    libjson-glib-dev \
        libgstrtspserver-1.0-0 \
        libgstrtspserver-1.0-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-nice \
        libnss-mdns \
		    avahi-utils && \
        rm -rf /var/lib/apt/lists/* && \
        apt-get clean ; \
    fi

ADD https://api.github.com/repos/${JETSON_UTILS_REPO}/git/refs/heads/${JETSON_UTILS_BRANCH} /tmp/jetson_utils_version.json

RUN git clone --branch=${JETSON_UTILS_BRANCH} --depth=1 https://github.com/${JETSON_UTILS_REPO} /opt/jetson-utils

RUN if [ "$JETSON_UTILS_CMAKE" = "on" ]; then \
        sed -i 's/set(PYTHON_BINDING_VERSIONS 2.7 3.6 3.7)/set(PYTHON_BINDING_VERSIONS 3.12)/' /opt/jetson-utils/python/CMakeLists.txt ; \
        sed -i 's/compute_53,code=sm_53 -gencode arch=compute_62,code=sm_62/compute_87,code=sm_87 -gencode arch=compute_110,code=sm_110 -gencode arch=compute_120,code=sm_120 -gencode arch=compute_121,code=sm_121/' /opt/jetson-utils/CMakeLists.txt ; \
        sed -i 's/compute_72,code=sm_72/compute_120,code=sm_120/' /opt/jetson-utils/CMakeLists.txt ; \
        for f in /opt/jetson-utils/network/IPv4.h /opt/jetson-utils/cpp/network/IPv4.h; do \
            [ -f "$f" ] && sed -i '/#include <string>/a #include <cstdint>' "$f" ; \
        done ; \
        for f in /opt/jetson-utils/network/Networking.h /opt/jetson-utils/cpp/network/Networking.h; do \
            [ -f "$f" ] && sed -i '/#include "IPv6.h"/i #include <cstdint>' "$f" ; \
        done ; \
        for f in /opt/jetson-utils/filesystem.h /opt/jetson-utils/cpp/parsers/filesystem.h; do \
            [ -f "$f" ] && sed -i '/#include <vector>/a #include <cstdint>' "$f" ; \
        done ; \
        sed -i 's@nppGetStreamContext(&nppStreamContext);@memset(\&nppStreamContext, 0, sizeof(nppStreamContext));@' /opt/jetson-utils/cuda/cudaBayer.cpp ; \
        sed -i '/#include <cuda\/cuda_runtime.h>/a #include <cstring>' /opt/jetson-utils/cuda/cudaBayer.cpp ; \
        sed -i 's/import_array();/import_array();\n\tPy_RETURN_NONE;/' /opt/jetson-utils/python/bindings/PyNumpy.cpp ; \
        sed -i 's/ss << "enable-max-performance=1 ";/\/\/ JP7: disable unsupported nvv4l2decoder property/' /opt/jetson-utils/codec/gstDecoder.cpp ; \
        sed -i 's/const bool enable_nvmm = true;/const bool enable_nvmm = false;/' /opt/jetson-utils/codec/gstDecoder.cpp ; \
        sed -i 's/if( enable_nvmm || mOptions.codecType == videoOptions::CODEC_V4L2 )/if( enable_nvmm )/' /opt/jetson-utils/codec/gstDecoder.cpp ; \
        sed -i 's/if( !discover() )/if( mOptions.resource.protocol != "file" \&\& !discover() )/' /opt/jetson-utils/codec/gstDecoder.cpp ; \
        sed -i '/LogInfo(LOG_GSTREAMER "gstDecoder -- creating decoder for %s\\n", mOptions.resource.location.c_str());/a \
if( mOptions.resource.protocol == "file" \&\& mOptions.codec == videoOptions::CODEC_UNKNOWN ) { \
    if( mOptions.resource.extension == "h265" ) mOptions.codec = videoOptions::CODEC_H265; \
    else mOptions.codec = videoOptions::CODEC_H264; \
}' /opt/jetson-utils/codec/gstDecoder.cpp ; \
        sed -i 's/return "nvv4l2decoder";/switch(codec) { case videoOptions::CODEC_H265: return "avdec_h265"; case videoOptions::CODEC_MJPEG: return "jpegdec"; default: return "avdec_h264"; }/' /opt/jetson-utils/codec/gstUtility.cpp ; \
        /opt/venv/bin/python -m pip install --no-cache-dir 'numpy==1.26.4' ; \
        cd /opt/jetson-utils ; \
        mkdir build ; \
        cd build ; \
        cmake ../ ; \
        make -j$(nproc) ; \
        make install -j$(nproc) ; \
    fi

RUN if [ "$JETSON_UTILS_PIP" = "on" ]; then \
        cd /opt/jetson-utils ; \
        /opt/venv/bin/python -m pip install --no-cache-dir -e . ; \
    else \
        cp -a /usr/lib/python3.12/dist-packages/jetson_utils /opt/venv/lib/python3.12/site-packages/ ; \
        cp -a /usr/lib/python3.12/dist-packages/jetson /opt/venv/lib/python3.12/site-packages/ ; \
        cp -a /usr/lib/python3.12/dist-packages/Jetson /opt/venv/lib/python3.12/site-packages/ ; \
        cp -a /usr/lib/python3.12/dist-packages/jetson_utils_python.so /opt/venv/lib/python3.12/site-packages/ ; \
    fi

RUN /opt/venv/bin/python - <<'PY'
import importlib.util
import pathlib
sp = pathlib.Path('/opt/venv/lib/python3.12/site-packages')
assert (sp / 'jetson_utils').exists(), 'jetson_utils package missing in venv'
assert (sp / 'jetson_utils_python.so').exists(), 'jetson_utils_python.so missing in venv'
assert importlib.util.find_spec('jetson_utils') is not None, 'jetson_utils module not discoverable'
print('jetson-utils python files staged in venv')
PY
