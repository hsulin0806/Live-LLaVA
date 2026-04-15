# nano_llm-unified (Private Monorepo)

這個專案把以下兩個專案合併成單一 repo：

- `jetson-containers`（容器建置與執行）
- `NanoLLM`（`nano_llm` Python 套件與範例）

請直接看教學：

- `JP7_從編譯到執行_mp4_攝影機教學.md`


## Quick Start (without jetson-containers runtime)

```bash
./scripts/run_video_mp4.sh /data /data/my_video.mp4 /data/my_output.mp4
```

See `JP7_從編譯到執行_mp4_攝影機教學.md` for full steps.


- 部署機器可只用 Docker 執行（不用安裝 jetson-containers），詳見 `JP7_從編譯到執行_mp4_攝影機教學.md`。
