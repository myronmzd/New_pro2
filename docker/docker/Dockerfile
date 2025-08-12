# multi-stage is possible, but keep it simple for reliability
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# system deps for opencv and ffmpeg
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# copy and install pip deps
COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# copy app
COPY app /app

# set a non-root user (optional)
RUN useradd -ms /bin/bash appuser || true
USER appuser

ENTRYPOINT ["python", "/app/main.py"]
