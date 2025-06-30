# 🎥 AWS Offline Video Analysis Pipeline

This project allows users to **upload video files to S3**, automatically trigger **Amazon Rekognition** to detect labels in the video, and finally send an email notification with the results via **SES**.

---

## 🧭 Architecture Overview

```text
        User uploads .mp4 / .mkv
                    │
                    ▼
        ┌───────────────────────────────┐
        │      S3 bucket: raw/          │
        │  • Key: raw/yyyy/mm/dd/       │
        │    video.mp4                  │
        │  • Trigger: ObjectCreated:Put │
        └─────────────┬─────────────────┘
                      │
                      ▼
        ┌───────────────────────────────┐
        │   Amazon EventBridge Rule     │
        │  • Source: "aws.s3"           │
        │  • Filters "ObjectCreated"    │
        │    events                     │
        │  • Target: Step Functions     │
        │    (offline-video-analyse)    │
        └─────────────┬─────────────────┘
                      │ StartExecution({ bucket, key })
                      ▼
        ┌──────────────────────────────────────────────┐
        │ Step Functions State Machine (ETL Orchestration) │
        │                                                │
        │  1️⃣ startLabelDetection.sync (Rekognition)    │
        │  2️⃣ getLabelDetection                         │
        │  3️⃣ startContentModeration.sync (violence/    │
        │     weapons)                                   │
        │  4️⃣ ★ Generate-Thumbnail-Lambda (ffmpeg)      │
        │     • Input : { bucket, key, firstHitTimestamp }│
        │     • Output: { thumb_key = "results/xyz.jpg"} │
        │  5️⃣ Save results to S3: results/<video>.json  │
        │  6️⃣ Invoke Lambda: video-label-email          │
        └─────────────┬──────────────────────────────────┘
                      │
                      ▼
        ┌──────────────────────────────────────────────┐
        │ Lambda: video-label-email (Python 3.11)      │
        │  • Loads detection JSON + image from S3       │
        │  • Builds MIME email with inline/attached JPEG│
        │  • Calls Amazon SES → SendRawEmail            │
        └─────────────┬─────────────────────────────────┘
                      │
                      ▼
        ┌──────────────────────────────────────────────┐
        │              📬 Recipient Inbox              │
        │  • Subject: ⚠️ Crash/Crime detected –        │
        │    <video>.mp4                               │
        │  • Body   : Label summary + timestamp        │
        │  • Image  : Inline thumbnail of detection    │
        └──────────────────────────────────────────────┘
```

---

## Features

- Upload video files to S3 (`.mp4`, `.mkv`)
- Automatic label and moderation detection using Amazon Rekognition
- Thumbnail generation using Lambda (FFmpeg)
- Results and thumbnail saved to S3
- Email notification with summary and thumbnail via SES

---

## Requirements

- AWS Account with S3, Rekognition, SES, Lambda, Step Functions permissions
- Python 3.11 for Lambda functions
- FFmpeg for thumbnail generation

---

## Usage

1. Upload a video file to the S3 bucket under the `raw/` prefix.
2. The pipeline is triggered automatically.
3. Check your email for the results and thumbnail.

---

## License
