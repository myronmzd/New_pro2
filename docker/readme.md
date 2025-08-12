# YOLOv8 Video Processor Docker Container

This Docker container processes videos using YOLOv8 object detection and is designed to run on AWS Fargate.

## Fixed Issues

- ✅ Corrected file structure and build context
- ✅ Fixed Dockerfile paths and dependencies
- ✅ Added health check endpoint for Fargate compatibility
- ✅ Removed user switching that caused permission issues
- ✅ Added proper error handling and logging
- ✅ Created Windows-compatible build scripts

## Quick Start

### For Windows Users

1. **Build and push to ECR:**
   ```cmd
   cd docker
   build_and_push.bat us-east-1
   ```

### For Linux/Mac Users

1. **Build and push to ECR:**
   ```bash
   cd docker
   chmod +x build_and_push.sh
   ./build_and_push.sh us-east-1
   ```

### Local Testing

1. **Test locally with Docker Compose:**
   ```bash
   cd docker
   docker-compose up --build
   ```

2. **Test health endpoint:**
   ```bash
   curl http://localhost:8080/health
   ```

## Environment Variables

Required for Fargate:
- `AWS_REGION`: AWS region (e.g., us-east-1)
- `RAW_BUCKET`: S3 bucket containing input videos
- `PROCESSED_BUCKET`: S3 bucket for processed outputs
- `INPUT_S3_KEY`: S3 key of the video to process

## Troubleshooting

### Common Issues:

1. **"App not found" error**: Fixed by correcting file paths and build context
2. **Permission denied**: Fixed by removing non-root user configuration
3. **Health check failures**: Added proper health endpoint on port 8080
4. **Build context errors**: Fixed Dockerfile COPY paths

### Logs:
Check CloudWatch logs for your Fargate service to debug issues.

### Local Testing:
Always test locally first using the provided test scripts before deploying to Fargate.