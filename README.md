# 🎥 AWS Offline Video Analysis Pipeline

This project allows users to **upload video files to S3**, automatically trigger **Amazon Rekognition** to detect labels in the video, and finally send an email notification with the results via **SES**.

## 🧭 Architecture Overview

                  User uploads .mp4 / .mkv
                               │
                               ▼
┌────────────────────────────────────────────────────────────┐
│  S3 bucket :  raw/                                         │
│  • ObjectCreated:Put event                                 │
└───────────────┬────────────────────────────────────────────┘
                │ EventBridge → StartExecution
                ▼
┌────────────────────────────────────────────────────────────┐
│  Step Functions  (offline‑video‑analyse)                   │
│                                                           │
│  1️⃣ startLabelDetection.sync   ← Rekognition (labels)     │
│  2️⃣ getLabelDetection                                    │
│  3️⃣ startContentModeration.sync  (violence / weapons)     │
│  4️⃣ ★ Generate‑Thumbnail‑Lambda  (ffmpeg, see below)      │
│      • Input : {bucket,key, firstHitTimestamp}            │
│      • Output: {thumb_key="results/<video>.jpg"}          │
│  5️⃣ PutObject results/<video>.json                       │
│  6️⃣ Invoke Notify‑Email‑Lambda  ← passes labels + thumb  │
└─────────────────┬─────────────────────────────────────────┘
                  │
                  ▼
┌────────────────────────────────────────────────────────────┐
│  Lambda  video‑label‑email  (Python 3.11)                  │
│  • Builds MIME email: plain text + inline/attached JPEG    │
│  • Calls SES  SendRawEmail                                 │
└───────────────┬────────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│             📬  Recipient Inbox                            │
│  • Subject:  ⚠️ Crash/Crime detected — <video>.mp4          │
│  • Body   :  label summary                                 │
│  • Image  :  embedded thumbnail of first detection frame   │
└────────────────────────────────────────────────────────────┘
