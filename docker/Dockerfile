FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg libsm6 libxext6 \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your code and model
COPY video_processor.py .
COPY yolov8n.pt .  # optional if needed

# Set default command
CMD ["python", "video_processor.py"]