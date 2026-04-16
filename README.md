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
docker run --runtime=nvidia --network host --ipc=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -e DISPLAY=:1 \
  -e QT_X11_NO_MITSHM=1 \
  -e TOKENIZERS_PARALLELISM=false \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /data:/data \
  nano_llm:r38.4.tegra-aarch64-cu130-24.04 \
  python3 -m nano_llm.vision.video \
    --api hf \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 64 \
    --video-input /data/my_video.mp4 \
    --video-output display://0 \
    --prompt 'What changes occurred in the video?' \
    --infer-interval-sec 2.5 \
    --subtitle-hold-sec 2.5 \
    --subtitle-max-chars 220 \
    --subtitle-line-chars 0 \
    --subtitle-max-lines 4
```

---

## 3) USB 攝影機推論（docker run）

```bash
docker run --runtime=nvidia --network host --ipc=host \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  -e DISPLAY=:1 \
  -e QT_X11_NO_MITSHM=1 \
  -e TOKENIZERS_PARALLELISM=false \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /data:/data \
  --device /dev/video0:/dev/video0 \
  nano_llm:r38.4.tegra-aarch64-cu130-24.04 \
  python3 -m nano_llm.vision.video \
    --api hf \
    --model Efficient-Large-Model/VILA1.5-3b \
    --max-images 8 \
    --max-new-tokens 64 \
    --video-input /dev/video0 \
    --video-output display://0 \
    --prompt 'What changes occurred in the video?' \
    --infer-interval-sec 2.5 \
    --subtitle-hold-sec 2.5 \
    --subtitle-max-chars 220 \
    --subtitle-line-chars 0 \
    --subtitle-max-lines 4
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

> 備註：跨機部署時，**不要**帶本機開發路徑掛載（例如 `-v /home/.../NanoLLM:/opt/NanoLLM`）。
> 那個只適用於你要在本機即時覆蓋程式碼測試。

---

## 5) 常見問題

- `/dev/video0` 不存在：
  ```bash
  ls -l /dev/video*
  ```
- CSI 相機不是 USB，請改用 `csi://0` 並確認 `nvargus-daemon` 正常。
- 首次模型下載較慢，第二次會走快取。

---

## 6) 常用參數說明（`python3 -m nano_llm.vision.video`）

- `--api hf`
  - 使用 Hugging Face 後端載入模型。

- `--model Efficient-Large-Model/VILA1.5-3b`
  - 指定使用的 VLM 模型。
  - 支援的 VLM（本專案整理）
    - `liuhaotian/llava-v1.5-7b`
    - `liuhaotian/llava-v1.5-13b`
    - `liuhaotian/llava-v1.6-vicuna-7b`
    - `liuhaotian/llava-v1.6-vicuna-13b`
    - `NousResearch/Obsidian-3B-V0.5`
    - `Efficient-Large-Model/VILA-2.7b`
    - `Efficient-Large-Model/VILA-7b`
    - `Efficient-Large-Model/VILA-13b`
    - `Efficient-Large-Model/VILA1.5-3b`
    - `Efficient-Large-Model/Llama-3-VILA1.5-8b`
    - `Efficient-Large-Model/VILA1.5-13b`

- `--max-images 8`
  - 保留最近 8 張影格做上下文，適合「變化偵測」類 prompt。

- `--max-new-tokens 64`
  - 每次回覆最多生成 token 數。越大通常可輸出更長句子，但延遲也可能增加。

- `--video-input /dev/video0`
  - 輸入來源。可用 USB 攝影機（`/dev/video0`）或 MP4 路徑（如 `/data/my_video.mp4`）。

- `--video-output display://0`
  - 將影像輸出到桌面視窗。若要輸出影片檔，可改成 `/data/output.mp4`。

- `--prompt 'What changes occurred in the video?'`
  - 每輪推論問題。可改成你要的描述風格。

- `--infer-interval-sec 2.5`
  - 每隔幾秒觸發一次新推論（控制更新頻率）。

- `--subtitle-hold-sec 2.5`
  - 字幕停留秒數。時間到後由下一次推論結果覆蓋。

- `--subtitle-max-chars 220`
  - 單次字幕最多顯示字元數，避免超長輸出塞爆畫面。

- `--subtitle-line-chars 0`
  - 每行字數上限；`0` 代表自動依畫面寬度換行（先盡量從左上到右上）。

- `--subtitle-max-lines 4`
  - 字幕最多顯示行數，超過會截斷。

---

## 補充

如果你要看更完整版本（含腳本與補充說明），請看：
- `JP7_從編譯到執行_mp4_攝影機教學.md`
- `scripts/run_video_mp4.sh`
- `scripts/run_video_camera.sh`
- `PROJECT_EXPERIENCE.md`（給新助理/新開發者的延續開發記憶）
