FROM python:3.11-slim

# Install system dependencies required by OpenCV
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir boto3 opencv-python

# Set working directory
WORKDIR /app

# Copy your code
COPY process.py .

# Run script
CMD ["python", "process.py"]
