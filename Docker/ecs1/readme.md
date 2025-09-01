# S3 Video Frame Processor

Processes video files from S3 and extracts 1-second frames.

## Environment Variables
- `S3_BUCKET_R`: Input S3 URL (e.g., s3://input-bucket/raw/)
- `S3_BUCKET_D`: Output S3 URL (e.g., s3://output-bucket/processing/)

## Build
docker build -t s3-processor .

## Force rebuild (if cached)
docker build --no-cache -t s3-processor .

## Run
export S3_BUCKET_R="s3://your-input-bucket/raw/"
export S3_BUCKET_D="s3://your-output-bucket/processing/"

docker run --rm \
  -v ~/.aws:/root/.aws \
  -e S3_BUCKET_R \
  -e S3_BUCKET_D \
  s3-processor

## AWS ECR Deployment

### 1. Authenticate Docker to ECR
```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 236024603923.dkr.ecr.ap-south-1.amazonaws.com
```

### 2. Build Image for ECR
```bash
docker build -t video-splitter .
```

### 3. Tag Image
```bash
docker tag video-splitter:latest 236024603923.dkr.ecr.ap-south-1.amazonaws.com/video-splitter:latest
```

### 4. Push to ECR
```bash
docker push 236024603923.dkr.ecr.ap-south-1.amazonaws.com/video-splitter:latest
```

**Note:** Ensure you have the latest AWS CLI and Docker installed.


  Use the following steps to authenticate and push an image to your repository. For additional registry authentication methods, including the Amazon ECR credential helper, see Registry Authentication .
Retrieve an authentication token and authenticate your Docker client to your registry. Use the AWS CLI:
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 236024603923.dkr.ecr.ap-south-1.amazonaws.com
Note: If you receive an error using the AWS CLI, make sure that you have the latest version of the AWS CLI and Docker installed.
Build your Docker image using the following command. For information on building a Docker file from scratch see the instructions here . You can skip this step if your image is already built:
docker build -t video-splitter .
After the build completes, tag your image so you can push the image to this repository:
docker tag video-splitter:latest 236024603923.dkr.ecr.ap-south-1.amazonaws.com/video-splitter:latest
Run the following command to push this image to your newly created AWS repository:
docker push 236024603923.dkr.ecr.ap-south-1.amazonaws.com/video-splitter:latest