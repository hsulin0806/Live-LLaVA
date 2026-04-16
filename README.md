# NanoLLM Unified (JetPack 7) - MP4 / USB Camera Tutorial

本 README 僅保留 **從編譯到執行 MP4 / USB 攝影機** 的部署教學。  
其他完整功能與原始說明請見：
- NanoLLM 原專案：https://github.com/dusty-nv/NanoLLM
- jetson-containers 原專案：https://github.com/dusty-nv/jetson-containers

---

## 目標

- 可編譯 `nano_llm` image（JP7 + CUDA 13.0）
- 可直接用 `docker run` 執行 MP4 推論
- 可直接用 `docker run` 執行 USB 攝影機推論
- 目標部署機器不需要安裝 `jetson-containers`

---

## 1) 編譯 Image（建置機器）

```bash
cd jetson-containers
bash install.sh
CUDA_VERSION=13.0 jetson-containers build nano_llm
```

預設使用：
- `nano_llm:r38.4.tegra-aarch64-cu130-24.04`

---

## 2) MP4 推論（docker run）

```bash
docker run --rm --runtime=nvidia --network host \
  -v /data:/data \
  nano_llm:r38.4.tegra-aarch64-cu130-24.04 \
  python3 -m nano_llm.vision.video \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 48 \
    --video-input /data/my_video.mp4 \
    --video-output /data/my_output.mp4 \
    --prompt 'What changes occurred in the video?'
```

---

## 3) USB 攝影機推論（docker run）

```bash
docker run --rm --runtime=nvidia --network host \
  -v /data:/data \
  --device /dev/video0:/dev/video0 \
  nano_llm:r38.4.tegra-aarch64-cu130-24.04 \
  python3 -m nano_llm.vision.video \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 48 \
    --video-input /dev/video0 \
    --video-output /data/usb_output.mp4 \
    --prompt 'What changes occurred in the video?'
```

---

## 4) 跨機快速部署（部署機器不用 jetson-containers）

建置機器匯出 image：

```bash
docker save nano_llm:r38.4.tegra-aarch64-cu130-24.04 | gzip > nano_llm-r38.4-cu130.tar.gz
```

目標機器匯入 image：

```bash
gunzip -c nano_llm-r38.4-cu130.tar.gz | docker load
```

匯入後直接跑第 2 或第 3 節的 `docker run` 指令即可。

---

## 5) 常見問題

- `/dev/video0` 不存在：
  ```bash
  ls -l /dev/video*
  ```
- CSI 相機不是 USB，請改用 `csi://0` 並確認 `nvargus-daemon` 正常。
- 首次模型下載較慢，第二次會走快取。

---

## 補充

如果你要看更完整版本（含腳本與補充說明），請看：
- `JP7_從編譯到執行_mp4_攝影機教學.md`
- `scripts/run_video_mp4.sh`
- `scripts/run_video_camera.sh`
- `PROJECT_EXPERIENCE.md`（給新助理/新開發者的延續開發記憶）
