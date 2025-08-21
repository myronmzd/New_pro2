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

┌─────────────────┐
│      User       │
│  Uploads Video  │
└────────┬────────┘
         │ .mp4/.mkv
         ▼
┌──────────────────────────────────┐
│        S3 Bucket                 │
│  ┌─────────────────────────────┐ │
│  │ raw/ (input videos)         │ │
│  └─────────────────────────────┘ │
│  ┌─────────────────────────────┐ │
│  │ processed/ (results)        │ │
│  └─────────────────────────────┘ │
└────────┬─────────────────────────┘
         │ S3 Event (Object Created, raw/)
         ▼
┌─────────────────────────────────┐
│        EventBridge              │
│  - Matches raw/ prefix          │
│  - Triggers Step Function       │
└────────┬────────────────────────┘
         ▼
┌───────────────────────────────────────────┐
│              Step Functions               │
│                                           │
│ 1️⃣ **CheckBucketContents**               │
│    - S3 ListObjectsV2                     │
│    - Choice: is file video (.mp4/.mkv)?   │
│                                           │
│ 2️⃣ **ECS RunTask1= Splits video**         │
│    - Splits video into frames (images)    │
│    - Uploads frames to S3                 │
│                                           │
│ 3️⃣ **CheckProcessingImages**             │
│    - S3 ListObjectsV2                     │
│    - Choice: are processing images ready? │
│                                           │
│ 4️⃣ **ECS RunTask2 = runs Rekognition      │
│       on images   **                       │
│    - Runs container task for Rekognition  │
│    - Saves inference results              │
│                                           │
│ 5️⃣ **SaveResults**                       │
│    - Writes output JSON/results to S3     │
│                                           │
│ 6️⃣ **CheckResultsFiles**                 │
│    - S3 ListObjectsV2                     │
│    - Choice: are results available?       │
│                                           │
│ 7️⃣ **Lambda (Send Email)**               │
│    - Formats results                      │
│    - Calls SES to send summary            │
│                                           │
│ 8️⃣ **Cleanup**                           │
│    - Deletes temporary objects            │
│                                           │
│ 🔴 Fail States: FailVideo, FailProcessing,│
│    FailResults handle errors at each step │
└───────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│              SNS                 │
│  - Publishes processing alert    │
│  - Notifies subscribers          │
└──────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│              SES                 │
│  - Sends email to user           │
│  - Includes thumbnail + summary  │
└──────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────┐
│          User Email              │
│  📧 Detection results received   │
└──────────────────────────────────┘

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

## Terraform

   # 1. Initialize the working directory
   terraform init

   # 2. Validate configuration syntax
   terraform validate

   # 3. Show what Terraform will do (plan the changes)
   terraform plan

   # 4. Save plan to a file (optional)
   terraform plan -out=tfplan

   # 5. Apply the planned changes
   terraform apply

   # 6. Apply changes automatically without approval prompt
   terraform apply -auto-approve

   # 7. Apply from a saved plan
   terraform apply tfplan

   # 8. Destroy all resources managed by Terraform
   terraform destroy

   # 9. Destroy with auto-approve
   terraform destroy -auto-approve

   # 10. Format Terraform code (HCL)
   terraform fmt

   # 11. Show Terraform state
   terraform show

   # 12. List the current workspace
   terraform workspace show

   # 13. Create a new workspace
   terraform workspace new dev

   # 14. Switch workspace
   terraform workspace select dev

   # 15. List all workspaces
   terraform workspace list

   # 16. Output values defined in the configuration
   terraform output

   # 17. Output value for a specific key
   terraform output <key>


## Same error to resolve againa 

Option 1 — Using dos2unix

```bash
sudo apt-get update && sudo apt-get install -y dos2unix
dos2unix /workspaces/New_pro2/.devcontainer/setup.sh
```
## 📄 License

MIT License - See LICENSE file for details.