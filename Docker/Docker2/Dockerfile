# syntax=docker/dockerfile:1
FROM python:3.12-slim

# Prevent Python from writing pyc files and buffer issues
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies for OpenCV and Ultralytics
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg libgl1 libglib2.0-0 libsm6 libxext6 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependencies first (for better caching)
COPY requirements.txt .

# Install Python packages
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cpu

# Copy model and code
COPY best.pt .
COPY app.py .

# Run app.py when the container starts
CMD ["python", "app.py"]
