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
    # Get S3 event info
    input_key = event['Records'][0]['s3']['object']['key']
    print(f"Processing video: s3://{INPUT_BUCKET}/raw/{input_key}")

    # Temp file to store video
    tmp_video = tempfile.NamedTemporaryFile(delete=False)
    local_video_path = tmp_video.name

    # Download from input bucket
    s3.download_file(INPUT_BUCKET, input_key, local_video_path)

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
            frame_filename = f"{os.path.splitext(os.path.basename(input_key))[0]}_frame_{saved_count:05d}.jpg"
            local_frame_path = os.path.join(tempfile.gettempdir(), frame_filename)
            cv2.imwrite(local_frame_path, frame)

            # Upload to output bucket
            s3.upload_file(local_frame_path, OUTPUT_BUCKET, frame_filename)
            print(f"Uploaded {frame_filename} to {OUTPUT_BUCKET}")

            saved_count += 1

        frame_count += 1

    cap.release()
    os.remove(local_video_path)

    return {
        "statusCode": 200,
        "body": f"Processed {saved_count} frames from {input_key}"
    }
