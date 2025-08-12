@echo off
setlocal enabledelayedexpansion

REM Get AWS region and account ID
if "%1"=="" (
    for /f "tokens=*" %%i in ('aws configure get region') do set AWS_REGION=%%i
) else (
    set AWS_REGION=%1
)

for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%i

set REPO_NAME=yolov8-video-processor
if "%2"=="" (
    set TAG=latest
) else (
    set TAG=%2
)

set IMAGE_URI=%ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%REPO_NAME%:%TAG%

echo Building and pushing Docker image...
echo Region: %AWS_REGION%
echo Account: %ACCOUNT_ID%
echo Repository: %REPO_NAME%
echo Tag: %TAG%
echo Image URI: %IMAGE_URI%

REM Create repository if it doesn't exist
aws ecr describe-repositories --repository-names %REPO_NAME% --region %AWS_REGION% >nul 2>&1
if errorlevel 1 (
    echo Creating ECR repository...
    aws ecr create-repository --repository-name %REPO_NAME% --region %AWS_REGION%
)

REM Login to ECR
echo Logging in to ECR...
for /f "tokens=*" %%i in ('aws ecr get-login-password --region %AWS_REGION%') do (
    echo %%i | docker login --username AWS --password-stdin %ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
)

REM Build and push
echo Building Docker image...
cd docker\app
docker build -t %REPO_NAME%:%TAG% -f ..\docker\Dockerfile .
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Tagging image...
docker tag %REPO_NAME%:%TAG% %IMAGE_URI%

echo Pushing to ECR...
docker push %IMAGE_URI%
if errorlevel 1 (
    echo Push failed!
    exit /b 1
)

echo.
echo Successfully pushed image: %IMAGE_URI%
echo Use this value for your Fargate task definition ContainerImage parameter.