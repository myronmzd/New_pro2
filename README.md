# 🎥 AWS Offline Video Analysis Pipeline

This project enables users to **upload video files to S3**, automatically trigger **Amazon Rekognition** for label detection, and receive an email notification with results and a thumbnail via **SES**.

---

## 🧭 Architecture Overview

### Workflow

1. **User Uploads Video**
   - Upload `.mp4` or `.mkv` files to the S3 bucket under the `raw/` prefix.

2. **S3 Event Trigger**
   - An S3 `ObjectCreated:Put` event triggers an Amazon EventBridge rule.

3. **EventBridge Rule**
   - Filters for new video uploads and triggers an AWS Step Functions State Machine.

4. **Step Functions Orchestration**
   - **a. Lambda: Video Splitter**
     - Splits the video into images (frames) and stores them in a dump S3 bucket.
   - **b. Rekognition Label Detection**
     - Runs label detection on the video.
   - **c. Rekognition Content Moderation**
     - Checks for car crash or crime using custom labels.
   - **d. Lambda: Thumbnail Generator**
     - Uses FFmpeg to generate a thumbnail from the first detection hit.
   - **e. Save Results**
     - Stores detection results and thumbnail in S3.
   - **f. Lambda: Email Notification**
     - Sends an email with the summary and thumbnail via SES.

5. **Recipient Inbox**
   - Receives an email with a summary, timestamp, and inline thumbnail.

---

### Diagram

```text
<<<<<<< HEAD
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
        ┌─────────────────────────────────────────────────────┐
        │ Step Functions State Machine (ETL Orchestration)    │
        │                                                     │
        │  1️⃣ startLabelDetection.sync (Rekognition)          │
        │  2️⃣ getLabelDetection                               │
        │  3️⃣ startContentModeration.sync (violence/          │
        │     weapons)                                        │
        │  4️⃣ ★ Generate-Thumbnail-Lambda (ffmpeg)           │
        │     • Input : { bucket, key, firstHitTimestamp }    │
        │     • Output: { thumb_key = "results/xyz.jpg"}      │
        │  5️⃣ Save results to S3: results/<video>.json       │
        │  6️⃣ Invoke Lambda: video-label-email               │
        └─────────────┬───────────────────────────────────────┘
                      │
                      ▼
        ┌───────────────────────────────────────────────┐
        │ Lambda: video-label-email (Python 3.11)       │
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
=======
┌───────────────┐
│    User       │
│ Uploads Video │
└──────┬────────┘
       │
       ▼
┌─────────────────────────────┐
│      S3 Bucket (raw/)       │
│  - Stores uploaded videos   │
│  - Triggers EventBridge     │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│   EventBridge Rule          │
│  - Filters video uploads    │
│  - Triggers Step Functions  │
└──────┬──────────────────────┘
       │
       ▼
┌───────────────────────────────────────────────┐
│ Step Functions State Machine                  │
│ 1. Lambda: Split video into                   │
│        frames saves in S3(dump)               │
│ 2. Rekognition: Label detection               │
│ 3. Rekognition: Content moderation            │
│ 4. Lambda: Generate thumbnail (FFmpeg)        │
│ 5. Lambda: delete the files in S3(dump)       │
│ 6. Lambda: Send email with SES                │
└──────┬────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────┐
│   Recipient Email Inbox     │
│  - Receives summary & image │
└─────────────────────────────┘
>>>>>>> 1fe2ea9b1c761bfe2368ededb2f40573f5e20291
```

---

## 🚀 Features

- Upload video files to S3 (`.mp4`, `.mkv`)
- Automatic label and moderation detection using Amazon Rekognition
- Thumbnail generation using Lambda (FFmpeg)
- Results and thumbnail saved to S3
- Email notification with summary and thumbnail via SES

---

## 🛠️ Requirements

- AWS Account with S3, Rekognition, SES, Lambda, Step Functions permissions
- Python 3.11 for Lambda functions
- FFmpeg for thumbnail generation

---

## 📦 Usage

1. Upload a video file to the S3 bucket under the `raw/` prefix.
2. The pipeline is triggered automatically.
3. Check your email for the results and thumbnail.

---

## 📄 License



