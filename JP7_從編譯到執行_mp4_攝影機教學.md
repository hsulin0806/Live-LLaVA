# JP7 從編譯到執行（MP4 / 攝影機）

> 本專案支援兩種路徑：
> 1) 用 `jetson-containers` 編譯 image
> 2) **不使用 `jetson-containers`，直接用 Docker 執行**（已提供腳本）

## A. 編譯 image（需要時）

```bash
cd jetson-containers
bash install.sh
CUDA_VERSION=13.0 jetson-containers build nano_llm
```

## B. 不用 jetson-containers，直接 Docker 執行（建議）

先確認本機已有 image（預設 tag）：

```bash
docker image inspect nano_llm:r38.4.tegra-aarch64-cu130-24.04 >/dev/null
```

### MP4

```bash
./scripts/run_video_mp4.sh /data /data/my_video.mp4 /data/my_output.mp4
```

等價原始命令：

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

### 攝影機

CSI：

```bash
./scripts/run_video_camera.sh /data csi://0 /data/cam_output.mp4
```

USB：

```bash
./scripts/run_video_camera.sh /data /dev/video0 /data/cam_output.mp4
```

## C. 常見問題

- 若 CSI 失敗，先確認 `nvargus-daemon` 與相機硬體。
- 若 image 不存在，先走 A 編譯一次。
- 若模型首次下載較慢，第二次會走快取。
