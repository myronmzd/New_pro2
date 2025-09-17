import boto3
import os
import cv2
import tempfile
from urllib.parse import urlparse

s3 = boto3.client("s3")

def parse_bucket_and_prefix(s3_url):
    parsed = urlparse(s3_url)
    bucket = parsed.netloc
    prefix = parsed.path.lstrip("/")
    return bucket, prefix

# --- Read env vars ---
S3_BUCKET_R, raw_prefix = parse_bucket_and_prefix(os.environ["S3_BUCKET_R"])
S3_BUCKET_D, output_prefix = parse_bucket_and_prefix(os.environ["S3_BUCKET_D"])

print("DEBUG - S3_BUCKET_R:", S3_BUCKET_R, "prefix:", raw_prefix)
print("DEBUG - S3_BUCKET_D:", S3_BUCKET_D, "prefix:", output_prefix)

def download_from_s3(bucket, key, local_path):
    print(f"Downloading from s3://{bucket}/{key} to {local_path}...")
    s3.download_file(bucket, key, local_path)
    return local_path

def upload_to_s3(local_path, bucket, key):
    s3.upload_file(local_path, bucket, key)
    print(f"Uploaded {local_path} → s3://{bucket}/{key}")

def split_video_to_frames(video_path, bucket, prefix, video_name):
    print(f"Opening video {video_path}...")
    cap = cv2.VideoCapture(video_path)
    fps = int(cap.get(cv2.CAP_PROP_FPS)) or 0.2
    frame_interval = fps  # 1 frame per second
    frame_count = 0
    saved_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if frame_count % frame_interval == 0:
            filename = f"frame_{saved_count:05d}.jpg"
            local_frame = os.path.join(tempfile.gettempdir(), filename)
            cv2.imwrite(local_frame, frame)

            # Upload frame to S3 under unique video folder
            key = f"{prefix}{filename}"
            upload_to_s3(local_frame, bucket, key)
            saved_count += 1

        frame_count += 1

    cap.release()
    print(f"Finished splitting. Total frames saved: {saved_count}")

def list_mp4_files(bucket, prefix):
    mp4_files = []
    continuation_token = None

    while True:
        kwargs = {"Bucket": bucket, "Prefix": prefix}
        if continuation_token:
            kwargs["ContinuationToken"] = continuation_token

        response = s3.list_objects_v2(**kwargs)

        for obj in response.get("Contents", []):
            key = obj["Key"]
            if key.lower().endswith(".mp4"):
                mp4_files.append(key)

        if response.get("IsTruncated"):
            continuation_token = response["NextContinuationToken"]
        else:
            break

    return mp4_files

def main():
    mp4_files = list_mp4_files(S3_BUCKET_R, raw_prefix)

    if not mp4_files:
        print("No MP4 files found.")
        return

    print(f"Found {len(mp4_files)} MP4 files to process.")

    for video_key in mp4_files:
        print(f"Processing: {video_key}")

        with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as tmp_file:
            local_video = tmp_file.name

        # Download from S3
        download_from_s3(S3_BUCKET_R, video_key, local_video)

        # Extract video name without extension
        video_name = os.path.splitext(os.path.basename(video_key))[0]

        # Split into frames and upload
        split_video_to_frames(local_video, S3_BUCKET_D, output_prefix, video_name)

        # Clean up
        os.remove(local_video)

    print("All videos processed successfully.")

if __name__ == "__main__":
    main()
