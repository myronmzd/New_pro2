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
┌────────────────────────────────────────────┐
│ Step Functions State Machine               │
│ 1. Video Processing & Analysis             │
│    - Rekognition label detection           │
│    - Content moderation                    │
│    - Thumbnail generation                  │
│    - Save results to S3                    │
│ 2. Email Notification via SES             │
└────────────────────────────────────────────┘
```

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

MIT License - See LICENSE file for details.