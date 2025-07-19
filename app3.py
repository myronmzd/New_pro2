# lambda_offline_crash_detection.py
"""
AWS Lambda: Offline crash‑detection pipeline (single function)
-------------------------------------------------------------
Triggered by an S3:ObjectCreated event when a **video** is
uploaded to the `raw/` prefix.  The function:
  1. Downloads the video to /tmp
  2. Uses **ffmpeg** (from a Lambda Layer) to extract frames at
     FRAME_RATE (default 1 FPS)
  3. Uploads each frame to S3 (frames/…) and calls DetectCustomLabels
  4. Sends an SNS email for frames where the model finds
     the label "Accident" (≥ 80 % confidence)
  5. Deletes non‑accident frames from S3
  6. Cleans /tmp to stay within the 10 GB limit

Prerequisites
-------------
* Lambda runtime: Python 3.12 (ARM64 works).
* Memory: 1024–2048 MB; Ephemeral storage: 2048–4096 MB.
* Layers:
    – FFmpeg static binary layer (e.g. github.com/serverlesspub/ffmpeg‑aws‑lambda‑layer)
* IAM:
    – rekognition:DetectCustomLabels
    – s3:{GetObject,PutObject,DeleteObject,DeleteObjectVersion,DeleteObjects}
    – sns:Publish
* Environment variables:
    MODEL_ARN        – ARN of your Rekognition Custom Labels model version
    SNS_TOPIC_ARN    – SNS topic for alerts
    FRAME_BUCKET     – Bucket where frames live (may be same as the video bucket)
    FRAME_RATE       – Frames‑per‑second to sample (default "1")
    MIN_CONFIDENCE   – Confidence threshold (default "80")
* /opt/bin/ffmpeg must exist (provided by the layer).
"""

import os, json, uuid, glob, shutil, logging, subprocess, urllib.parse
from typing import List

import boto3

s3  = boto3.client("s3")
rek = boto3.client("rekognition")
sns = boto3.client("sns")

MODEL_ARN      = os.environ["MODEL_ARN"]
SNS_TOPIC_ARN  = os.environ["SNS_TOPIC_ARN"]
FRAME_BUCKET   = os.environ.get("FRAME_BUCKET")  # if None → use source bucket
FRAME_RATE     = int(os.environ.get("FRAME_RATE", "1"))
MIN_CONFIDENCE = float(os.environ.get("MIN_CONFIDENCE", "80"))
FFMPEG_BIN     = "/opt/bin/ffmpeg"  # path in popular Lambda layers
TMP_DIR        = "/tmp"

log = logging.getLogger()
log.setLevel(logging.INFO)

def _extract_frames(video_path: str, out_dir: str) -> None:
    """Run ffmpeg to extract JPEGs at FRAME_RATE FPS into *out_dir*."""
    cmd = [
        FFMPEG_BIN,
        "-i", video_path,
        "-vf", f"fps={FRAME_RATE}",
        os.path.join(out_dir, "frame_%06d.jpg"),
    ]
    log.info("Running ffmpeg: %s", " ".join(cmd))
    subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)


def _detect_crash(s3_bucket: str, s3_key: str) -> bool:
    """Return True if the model finds label 'Accident' >= MIN_CONFIDENCE."""
    resp = rek.detect_custom_labels(
        ProjectVersionArn=MODEL_ARN,
        Image={"S3Object": {"Bucket": s3_bucket, "Name": s3_key}},
        MinConfidence=MIN_CONFIDENCE,
    )
    return any(
        lbl["Name"].lower() in {"accident", "crash"} and lbl["Confidence"] >= MIN_CONFIDENCE
        for lbl in resp.get("CustomLabels", [])
    )


def _send_alert(frame_urls: List[str], video_key: str) -> None:
    """Publish an SNS email with presigned URLs of crash frames."""
    if not frame_urls:
        return
    body = {
        "video": video_key,
        "crash_frames": frame_urls,
    }
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"🚨 Crash detected in {os.path.basename(video_key)}",
        Message=json.dumps(body, indent=2),
    )


def handler(event, context):
    # 1. Parse S3 event
    record       = event["Records"][0]["s3"]
    video_bucket = record["bucket"]["name"]
    video_key    = urllib.parse.unquote_plus(record["object"]["key"])
    basename     = os.path.splitext(os.path.basename(video_key))[0]

    frame_bucket = FRAME_BUCKET or video_bucket

    # 2. Download to /tmp
    local_video = os.path.join(TMP_DIR, f"{basename}-{uuid.uuid4()}.mp4")
    log.info("Downloading s3://%s/%s to %s", video_bucket, video_key, local_video)
    s3.download_file(video_bucket, video_key, local_video)

    # 3. Extract frames
    frame_dir = os.path.join(TMP_DIR, f"frames-{uuid.uuid4()}")
    os.makedirs(frame_dir, exist_ok=True)
    _extract_frames(local_video, frame_dir)

    crash_urls   = []
    delete_keys  = []

    # 4. Process each frame
    for frame_path in sorted(glob.glob(os.path.join(frame_dir, "*.jpg"))):
        frame_name = os.path.basename(frame_path)
        s3_key     = f"frames/{basename}/{frame_name}"
        s3.upload_file(frame_path, frame_bucket, s3_key)
        log.debug("Uploaded frame to s3://%s/%s", frame_bucket, s3_key)

        if _detect_crash(frame_bucket, s3_key):
            presigned = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": frame_bucket, "Key": s3_key},
                ExpiresIn=86_400,
            )
            crash_urls.append(presigned)
        else:
            delete_keys.append({"Key": s3_key})

    # 5. Alert and cleanup
    _send_alert(crash_urls, video_key)

    if delete_keys:
        # Batch delete up to 1000 at once
        for i in range(0, len(delete_keys), 1000):
            s3.delete_objects(Bucket=frame_bucket, Delete={"Objects": delete_keys[i:i+1000]})

    # Local cleanup
    shutil.rmtree(frame_dir, ignore_errors=True)
    os.remove(local_video)

    return {
        "video": video_key,
        "crash_frames": len(crash_urls),
        "processed_frames": len(delete_keys) + len(crash_urls),
    }
