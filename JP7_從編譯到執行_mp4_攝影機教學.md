# JP7 從編譯到執行（MP4 / 攝影機）

> 目標：能編譯 image，並能用 `nano_llm.vision.video` 跑 MP4 或相機輸入。  
> 適用：JetPack 7（L4T R38）+ CUDA 13.0。

## 1) 進入建置目錄

```bash
cd jetson-containers
```

## 2) 安裝依賴

```bash
bash install.sh
```

## 3) 編譯 nano_llm image

```bash
CUDA_VERSION=13.0 jetson-containers build nano_llm
```

## 4) 執行 MP4 推論

先準備資料夾（把影片放進去）：

```bash
mkdir -p /data
# 例如：/data/my_video.mp4
```

執行指令（你指定的版本）：

```bash
jetson-containers run $(autotag nano_llm) \
  python3 -m nano_llm.vision.video \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 48 \
    --video-input /data/my_video.mp4 \
    --video-output /data/my_output.mp4 \
    --prompt 'What changes occurred in the video?'
```

## 5) 執行攝影機推論

CSI 相機範例：

```bash
jetson-containers run $(autotag nano_llm) \
  python3 -m nano_llm.vision.video \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 48 \
    --video-input csi://0 \
    --video-output /data/cam_output.mp4 \
    --prompt 'What changes occurred in the video?'
```

USB 攝影機常見可用：

```bash
--video-input /dev/video0
```

## 6) 常見問題

- 如果 `autotag nano_llm` 沒有回傳你預期的 tag，先確認 build 已成功。
- 如果 CSI 失敗，先確認主機 `nvargus-daemon` 正常、相機可用。
- 若需要固定已驗證 tag，可改用：

```bash
jetson-containers run nano_llm:r38.4.tegra-aarch64-cu130-24.04 ...
```
