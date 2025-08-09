# Use PyTorch official base image with Python 3.11 & CUDA runtime already included
FROM pytorch/pytorch:2.2.2-cuda12.1-cudnn8-runtime

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsm6 \
    libxext6 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip first
RUN pip install --upgrade pip

# Install Python packages (skip torch if already installed in base image)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu121

# Copy application code
COPY video_processor.py .

# Optional: download model at container start if not present
ENV YOLO_MODEL_URL=https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.pt
RUN echo '#!/bin/bash\n' \
         'if [ ! -f yolov8n.pt ]; then\n' \
         '  echo "Downloading YOLOv8 model..."\n' \
         '  curl -L -o yolov8n.pt $YOLO_MODEL_URL\n' \
         'fi\n' \
         'exec "$@"\n' \
         > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Set default command
CMD ["python", "video_processor.py"]
