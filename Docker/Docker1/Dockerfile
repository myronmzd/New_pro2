# Use Python slim image
FROM python:3.11-slim

# Prevent Python from writing .pyc files and enable stdout logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install only required system dependencies for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsm6 \
    libxext6 \
    libgl1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies in one layer
RUN pip install --no-cache-dir boto3 opencv-python-headless

# Set working directory
WORKDIR /app

# Copy only the Python file (keep layers small)
COPY process.py .

# Use a non-root user for better security
RUN useradd -m appuser
USER appuser

# Final command to run your script
CMD ["python", "process.py"]
