#  AWS Sentiment Analysis Pipeline

This project enables users to **upload text or image files to S3**, automatically trigger **ECS Fargate via Step Functions** for sentiment analysis, and receive an email notification with results and a report via **SES**.

---

##  Architecture Overview

### Workflow

1. **User Uploads Data**
   - Upload `.txt` or `.png/.jpg` files to the S3 bucket under the `raw/` prefix.

2. **S3 Event Trigger**
   - An S3 `ObjectCreated:Put` event triggers an Amazon EventBridge rule.

3. **EventBridge Rule**
   - Filters for new file uploads and triggers an AWS Step Functions State Machine.

4. **Step Functions Orchestration**
   - **a. CheckInputType**: Determines file type (text/image)
   - **b. ECS Tasks**: Run sentiment analysis based on file type
   - **c. GenerateReport**: Aggregates results into summary
   - **d. SendEmail**: Delivers analysis report via SES
   - **e. Cleanup**: Removes temporary files

5. **Recipient Inbox**
   - Receives an email with sentiment analysis results and summary.

---

### Architecture Diagram

```text
┌─────────────────────────────────────────────┐
│                   USER                      │
│   Uploads data (text / images) to S3 bucket │
└──────────────────────────┬──────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────┐
│                   S3 BUCKET                 │
│  • raw/          → incoming data            │
│  • processed/    → intermediate results     │
│  • results/      → final outputs            │
└──────────────────────────┬──────────────────┘
           S3 Event: ObjectCreated (prefix = raw/)
                           │
                           ▼
┌─────────────────────────────────────────────┐
│                 EVENTBRIDGE                 │
│  • Detects new uploads in raw/              │
│  • Triggers Step Functions state machine    │
└──────────────────────────┬──────────────────┘
                           ▼
┌─────────────────────────────────────────────┐
│              STEP FUNCTIONS WORKFLOW        │
│─────────────────────────────────────────────│
│ 1️⃣ **CheckInputType**                       │
│     - S3 ListObjectsV2                      │
│     - Determine file type (text / image)    │
│     - Choice state directs next step        │
│─────────────────────────────────────────────│
│ 2️⃣ **If Image → ECS Task 1**                │
│     - Runs image sentiment analysis         │
│     - Uploads JSON results to S3 (results/) │
│─────────────────────────────────────────────│
│ 3️⃣ **If Text → ECS Task 2**                 │
│     - Runs text sentiment analysis          │
│     - Uploads JSON results to S3 (results/) │
│─────────────────────────────────────────────│
│ 4️⃣ **CheckResultsAvailability**             │
│     - Uses S3 ListObjectsV2                 │
│     - Waits until result file(s) exist      │
│─────────────────────────────────────────────│
│ 5️⃣ **GenerateReport (Lambda)**              │
│     - Aggregates outputs from S3/results/   │
│     - Formats summary (text + image data)   │
│─────────────────────────────────────────────│
│ 6️⃣ **SendEmail (SES)**                      │
│     - Sends analysis report to user email   │
│     - Includes summary + optional thumbnail │
│─────────────────────────────────────────────│
│ 7️⃣ **Cleanup (Lambda)**                     │
│     - Deletes temporary files (raw/processed)│
│     - Maintains only final results          │
│─────────────────────────────────────────────│
│ 🔴 **Fail States (Fallbacks)**               │
│     - Handle: FileTypeError, ECSFailure,    │
│               ResultNotFound, EmailFailure  │
└──────────────────────────┬──────────────────┘
                           ▼
┌─────────────────────────────────────────────┐
│                    SNS                      │
│  • Publishes success/failure notifications  │
│  • Notifies monitoring or admin channels    │
└──────────────────────────┬──────────────────┘
                           ▼
┌─────────────────────────────────────────────┐
│                    SES                      │
│  • Sends final report to end-user email     │
│  • "Your sentiment analysis is ready!"      │
└──────────────────────────┬──────────────────┘
                           ▼
┌─────────────────────────────────────────────┐
│                  USER EMAIL                 │
│     📧 Receives sentiment analysis report   │
└─────────────────────────────────────────────┘
```

##  Features

- Upload text files (`.txt`) and image files (`.png`, `.jpg`) to S3
- Sentiment analysis for text using NLP models on ECS Fargate
- Image sentiment analysis using computer vision on ECS Fargate
- Automated file type detection and routing
- Results aggregation and report generation
- Email notification with analysis summary via SES
- Automatic cleanup of temporary files

---

##  Requirements

- AWS Account with S3, ECS Fargate, SES, Lambda, Step Functions, EventBridge, SNS permissions
- Python 3.11 for Lambda functions and ECS tasks
- NLP libraries (transformers, nltk) for text sentiment analysis
- Computer vision libraries (PIL, opencv) for image sentiment analysis

---

##  Usage

1. Upload a text file (`.txt`) or image file (`.png`, `.jpg`) to the S3 bucket under the `raw/` prefix.
2. The pipeline automatically detects file type and runs appropriate sentiment analysis.
3. Check your email for the sentiment analysis results and summary report.

---

##  Cost Estimation

| Service Component           | Details                                     | Estimated Cost (₹)    |
|----------------------------|---------------------------------------------|------------------------|
| S3 Storage                 | Text/image files + results                  | 50–100                 |
| ECS Fargate (CPU tasks)    | Sentiment analysis processing               | 200–400                |
| Lambda Functions           | Report generation, cleanup                  | 20–50                  |
| Step Functions, EventBridge, SNS, SES | Orchestration, notifications    | 50–100                 |
| **Total Estimated Cost**   | Per 1000 file processing                    | **~₹320 – ₹650**       |

### Notes:
- Costs are for CPU-based sentiment analysis using standard NLP models
- Text processing is generally faster and cheaper than image analysis
- All costs are approximate and **subject to change**. Check AWS pricing for your region before planning.

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
   terraform show tfplan

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

## use this again and again in test so 

aws s3 rm s3://input-bucket-s05breji/raw/ --recursive
aws s3 rm s3://dump-video-image-s05breji/processing/ --recursive
aws s3 rm s3://dump-video-image-s05breji/results/ --recursive
aws s3 cp sample.txt s3://input-bucket-s05breji/raw/   # text file
aws s3 cp image.jpg s3://input-bucket-s05breji/raw/   # image file

aws stepfunctions delete-state-machine --state-machine-arn arn:aws:states:ap-south-1:236024603923:stateMachine:sentiment-analysis-pipeline

##  License

MIT License - See LICENSE file for details.
