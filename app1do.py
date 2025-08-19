import boto3
import cv2
import os
import tempfile

# AWS clients
s3 = boto3.client("s3")

# Read env variables
INPUT_BUCKET = os.environ.get("S3_BUCKET_R")   # Raw bucket (video source)
OUTPUT_BUCKET = os.environ.get("S3_BUCKET_D")  # Dump bucket (frames)
FRAME_RATE = int(os.environ.get("FRAME_RATE", "1"))  # 1 frame per second by default

def lambda_handler(event, context):
    """
    Lambda handler triggered by S3 upload (new video).
    Splits video into frames and stores them in output bucket.
    """

    # Get bucket & key from event (Step Function or S3 trigger)
    input_bucket = event.get("input_bucket", INPUT_BUCKET)  # from step funtion "input-bucket-77wmhh3q"
    key = event.get("key")  # from step funtion "raw/Untitled.mp4"

    if not input_bucket or not key:
        return {"statusCode": 400, "body": "Missing input_bucket or key"}

    print(f"Processing video: s3://{input_bucket}/{key}")

    # Temp file to store video
    tmp_video = tempfile.NamedTemporaryFile(delete=False)
    local_video_path = tmp_video.name
    tmp_video.close()

    # Download from input bucket
    s3.download_file(input_bucket, key, local_video_path)

    # Process video with OpenCV
    cap = cv2.VideoCapture(local_video_path)
    fps = int(cap.get(cv2.CAP_PROP_FPS)) or 30
    interval = max(1, fps // FRAME_RATE)  # how many frames to skip

    frame_count = 0
    saved_count = 0

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        if frame_count % interval == 0:
            frame_filename = f"{os.path.splitext(os.path.basename(key))[0]}_frame_{saved_count:05d}.jpg"
            local_frame_path = os.path.join(tempfile.gettempdir(), frame_filename)
            cv2.imwrite(local_frame_path, frame)

            # Upload to output bucket
            s3.upload_file(local_frame_path, OUTPUT_BUCKET, frame_filename)
            print(f"Uploaded {frame_filename} to {OUTPUT_BUCKET}")

            os.remove(local_frame_path)  # ✅ cleanup frame
            saved_count += 1

        frame_count += 1

    cap.release()
    os.remove(local_video_path)

    return {
        "statusCode": 200,
        "body": f"Processed {saved_count} frames from {key}"
    }
