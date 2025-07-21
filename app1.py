import os, json, uuid, glob, shutil, logging, subprocess, urllib.parse
from typing import List
import boto3

# AWS clients
s3 = boto3.client("s3")
rek = boto3.client("rekognition")
sns = boto3.client("sns")

# ENV variables
MODEL_ARN      = os.environ["MODEL_ARN"]
SNS_TOPIC_ARN  = os.environ["SNS_TOPIC_ARN"]
DUMP_BUCKET    = os.environ["DUMP_BUCKET"]
FRAME_RATE     = int(os.environ.get("FRAME_RATE", "1"))  # 1 frame per second
MIN_CONFIDENCE = float(os.environ.get("MIN_CONFIDENCE", "80"))
FFMPEG_BIN     = "/opt/bin/ffmpeg"
TMP_DIR        = "/tmp"

log = logging.getLogger()
log.setLevel(logging.INFO)

def _extract_frames(video_path: str, out_dir: str) -> None:
    """Extract 1 FPS frames from video into local folder."""
    cmd = [
        FFMPEG_BIN,
        "-i", video_path,
        "-vf", f"fps={FRAME_RATE}",
        os.path.join(out_dir, "frame_%06d.jpg"),
    ]
    log.info("Running ffmpeg: %s", " ".join(cmd))
    subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

def _detect_crash(bucket: str, key: str) -> bool:
    """Run Rekognition Custom Labels on frame."""
    resp = rek.detect_custom_labels(
        ProjectVersionArn=MODEL_ARN,
        Image={"S3Object": {"Bucket": bucket, "Name": key}},
        MinConfidence=MIN_CONFIDENCE,
    )
    return any(
        lbl["Name"].lower() in {"accident", "crash"} and lbl["Confidence"] >= MIN_CONFIDENCE
        for lbl in resp.get("CustomLabels", [])
    )

def _send_alert(crash_urls: List[str], video_key: str) -> None:
    """Send SNS email with crash image URLs."""
    if not crash_urls:
        return
    msg = {
        "video": video_key,
        "crash_frames": crash_urls,
    }
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"🚨 Crash detected in {os.path.basename(video_key)}",
        Message=json.dumps(msg, indent=2),
    )

def handler(event, context):
    # Step 1: Get the video from S3 input bucket
    record = event["Records"][0]["s3"]
    input_bucket = record["bucket"]["name"]
    video_key = urllib.parse.unquote_plus(record["object"]["key"])
    basename = os.path.splitext(os.path.basename(video_key))[0]

    # Step 2: Download video to /tmp
    local_video = os.path.join(TMP_DIR, f"{basename}-{uuid.uuid4()}.mp4")
    log.info("Downloading s3://%s/%s to %s", input_bucket, video_key, local_video)
    s3.download_file(input_bucket, video_key, local_video)

    # Step 3: Extract frames using ffmpeg
    frame_dir = os.path.join(TMP_DIR, f"frames-{uuid.uuid4()}")
    os.makedirs(frame_dir, exist_ok=True)
    _extract_frames(local_video, frame_dir)

    crash_urls = []
    delete_keys = []

    # Step 4: Upload frames to DUMP_BUCKET & check for crash
    for frame_path in sorted(glob.glob(os.path.join(frame_dir, "*.jpg"))):
        frame_name = os.path.basename(frame_path)
        dump_key = f"frames/{basename}/{frame_name}"

        s3.upload_file(frame_path, DUMP_BUCKET, dump_key)
        log.debug("Uploaded frame to s3://%s/%s", DUMP_BUCKET, dump_key)

        if _detect_crash(DUMP_BUCKET, dump_key):
            url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": DUMP_BUCKET, "Key": dump_key},
                ExpiresIn=86400,
            )
            crash_urls.append(url)
        else:
            delete_keys.append({"Key": dump_key})

    # Step 5: Send alert with crash frames
    _send_alert(crash_urls, video_key)

    # Step 6: Delete non-crash frames from dump bucket
    for i in range(0, len(delete_keys), 1000):
        s3.delete_objects(Bucket=DUMP_BUCKET, Delete={"Objects": delete_keys[i:i+1000]})

    # Step 7: Clean local files
    shutil.rmtree(frame_dir, ignore_errors=True)
    if os.path.exists(local_video):
        os.remove(local_video)

    return {
        "video": video_key,
        "crash_frames": len(crash_urls),
        "deleted_frames": len(delete_keys),
        "total_frames": len(delete_keys) + len(crash_urls),
    }