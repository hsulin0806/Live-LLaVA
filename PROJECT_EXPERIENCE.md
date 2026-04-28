# PROJECT_EXPERIENCE.md

> 給「全新進來的助理/開發者」的延續開發記憶。先讀這份，再動手。

## 專案目標（固定）

- 平台：**JetPack 7 / L4T R38 + CUDA 13.0 only**
- 影像流程：MP4 + USB Camera 可跑
- 部署：目標機可只用 `docker compose up -d`，不依賴 `jetson-containers` 安裝
- 首次可下載模型，第二次可吃快取離線啟動

## 已驗證可用的核心 image

- `nano_llm:r38.4.tegra-aarch64-cu130-24.04`

## 重要踩雷與結論

1. **JP7/CUDA13 相容性要靠本地 patch**（已在本 repo 內）
   - `jetson-containers/` 與 `NanoLLM/` 都有為 JP7 做過修補。

2. **MP4 decode 過去會卡 NVMM caps 問題**
   - 已修成 software decode 路徑可正常工作。

3. **jetson-utils Python/NumPy ABI 問題**
   - `numpy==1.26.4` 是穩定點，避免 import 崩潰。

4. **HF 視訊循環推論曾出現 cache_position crash**
   - 在 `NanoLLM/nano_llm/vision/video.py` 已調整避免循環中 cache 重用造成崩潰。

5. **字幕需求（使用者實測需求）**
   - 必須持續更新（非只推一次）
   - 可設 `--infer-interval-sec`、`--subtitle-hold-sec`
   - 字幕換行需可「吃滿畫面寬度再斷行」
   - `--subtitle-line-chars 0` 代表自動滿寬換行

6. **常見警告可先視為非阻塞**
   - `TRANSFORMERS_CACHE` deprecation warning
   - onnxruntime DRM device discovery warning
   - `clip_trt` TensorRT optimize 失敗會 fallback，不一定阻塞主流程

7. **CSI camera 錯誤與 USB camera 分離看待**
   - 沒有 `nvargus-daemon` 時 CSI 會報錯（預期）
   - USB `/dev/video0` 路徑可獨立正常

## 現行常用啟動範本（桌面顯示 + USB）

```bash
IMAGE_TAG=nano_llm:r38.4.tegra-aarch64-cu130-24.04-v2 \
DATA_DIR=/data \
CAM_INPUT=/dev/video0 \
VIDEO_OUTPUT=display://0 \
docker compose -f docker-compose.camera.yml up -d
```

## 接手者建議順序

1. 先跑上面範本確認「有畫面 + 有字幕 + 持續更新」。
2. 再調 `--max-new-tokens`、prompt、字幕參數。
3. 若要追求更準描述，再考慮模型切換/量化，不要先動底層相容 patch。
4. 改動後務必更新本檔（這份就是專案經驗累積點）。
