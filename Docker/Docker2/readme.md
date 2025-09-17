# S3 Video Frame Processor

Processes video files from S3 and extracts 1-second frames.

## Environment Variables
- `S3_BUCKET_R`: Input S3 URL (e.g., s3://input-bucket/raw/)
- `S3_BUCKET_D`: Output S3 URL (e.g., s3://output-bucket/processing/)

## Build
docker build -t s3-crash-detector .

## Force rebuild (if cached)
docker build --no-cache -t s3-crash-detector .

## Run
export S3_BUCKET_R="s3://your-input-bucket/raw/"
export S3_BUCKET_D="s3://your-output-bucket/processing/"

docker run --rm \
  -v ~/.aws:/root/.aws \
  -e S3_BUCKET_R \
  -e S3_BUCKET_D \
  s3-crash-detector

## AWS ECR Deployment

### 1. Authenticate Docker to ECR
```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 236024603923.dkr.ecr.ap-south-1.amazonaws.com
```

### 2. Build Image for ECR
```bash
docker build -t carcrash-detector .
```

### 3. Tag Image
```bash
docker tag carcrash-detector:latest 236024603923.dkr.ecr.ap-south-1.amazonaws.com/carcrash-detector:latest
```

### 4. Push to ECR
```bash
docker push 236024603923.dkr.ecr.ap-south-1.amazonaws.com/carcrash-detector:latest
```

**Note:** Ensure you have the latest AWS CLI and Docker installed.