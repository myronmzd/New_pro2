# 🎥 AWS Offline Video Analysis Pipeline

This project enables users to **upload video files to S3**, automatically trigger **YOLOv8 on Fargate** for crash/crime detection, and receive an email notification with results and a thumbnail via **SES**.

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
   - **a. Fargate Task (Python + YOLOv8)**
     - Loads video from S3 and detects crash/crime events.
     - Generates thumbnail and JSON results.
     - Uploads processed data to S3 (processed/).
   - **b. Lambda: Email Notification**
     - Sends an email with the summary and thumbnail via SES.
   - **c. SNS Topic**
     - Publishes alert/summary message.

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
┌──────────────────────────────┐
│ S3 Bucket (raw/)             │
│ - Stores uploaded videos     │
│ - Triggers EventBridge       │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│ EventBridge Rule             │
│ - Filters object create      │
│ - Triggers Step Functions    │
└──────┬───────────────────────┘
       │
       ▼
┌────────────────────────────────────────────┐
│ Step Functions                             │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │ Fargate Task (Python + YOLOv8)       │  │
│  │ - Loads video from S3                │  │
│  │ - Detects crash/crime events         │  │
│  │ - Generates thumbnail + JSON         │  │
│  │ - Uploads to S3 (processed/)         │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │ Lambda Function (Python)            │  │
│  │ - Sends Email via SES               │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │ SNS Topic                            │  │
│  │ - Publishes alert/summary message    │  │
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

## 🚀 Features

- Upload video files to S3 (`.mp4`, `.mkv`)
- Crash/crime detection using YOLOv8 on Fargate
- Thumbnail generation using Fargate task
- Results and thumbnail saved to S3
- Email notification with summary and thumbnail via SES

---

## 🛠️ Requirements

- AWS Account with S3, Fargate, SES, Lambda, Step Functions, SNS permissions
- Python 3.11 for Lambda functions and Fargate tasks
- YOLOv8 for video analysis

---

## 📦 Usage

1. Upload a video file to the S3 bucket under the `raw/` prefix.
2. The pipeline is triggered automatically.
3. Check your email for the results and thumbnail.

---

## 📄 License

MIT License - See LICENSE file for details.