# 🎥 AWS Offline Video Analysis Pipeline

This project allows users to **upload video files to S3**, automatically trigger **Amazon Rekognition** to detect labels in the video, and finally send an email notification with the results via **SES**.

## 🧭 Architecture Overview

              User uploads .mp4 / .mkv
                          │
                          ▼
┌──────────────────────────────────────────────────────┐
│                   S3 bucket : raw/                   │
│ • Key: raw/yyyy/mm/dd/video.mp4                      │
│ • Trigger: ObjectCreated:Put event                   |
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│              Amazon EventBridge Rule                 │
│ • Source: "aws.s3"                                   │
│ • Filters "ObjectCreated" events                     │
│ • Target: Step Functions (offline-video-analyse)     │
└──────────────┬───────────────────────────────────────┘
               │ StartExecution({ bucket, key })        
               ▼
┌──────────────────────────────────────────────────────┐
│     Step Functions State Machine (ETL Orchestration) │
│                                                      │
│  1️⃣ startLabelDetection.sync (Rekognition - labels) │
│  2️⃣ getLabelDetection                               │
│  3️⃣ startContentModeration.sync (violence / weapons)│
│  4️⃣ ★ Generate-Thumbnail-Lambda (ffmpeg)            │
│     • Input : { bucket, key, firstHitTimestamp }     │
│     • Output: { thumb_key = "results/xyz.jpg" }      │
│  5️⃣ Save results to S3: results/<video>.json        │
│  6️⃣ Invoke Lambda: video-label-email                │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│       Lambda: video-label-email (Python 3.11)        │
│ • Loads detection JSON + image from S3               │
│ • Builds MIME email with inline/attached JPEG        │
│ • Calls Amazon SES → SendRawEmail                    │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│                  📬  Recipient Inbox                 │
│ • Subject:  ⚠️ Crash/Crime detected – <video>.mp4    │
│ • Body   :  Label summary + timestamp                │
│ • Image  :  Inline thumbnail of detection            │
└──────────────────────────────────────────────────────┘
