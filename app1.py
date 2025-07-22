import os, json, uuid, glob, shutil, logging, subprocess, urllib.parse
import boto3

# AWS clients
s3 = boto3.client("s3")

# ENV variables
RAW_BUCKET  = os.environ["S3_BUCKET_R"]   # Input bucket
DUMP_BUCKET = os.environ["S3_BUCKET_D"]   # Output bucket
FRAME_RATE  = int(os.environ.get("FRAME_RATE", "1"))  # Default = 1 FPS
# Check common locations for ffmpeg
if os.path.exists("/opt/bin/ffmpeg"):
    FFMPEG_BIN = "/opt/bin/ffmpeg"
elif os.path.exists("/var/task/ffmpeg"):
    FFMPEG_BIN = "/var/task/ffmpeg"
elif os.path.exists("/tmp/ffmpeg"):
    FFMPEG_BIN = "/tmp/ffmpeg"
else:
    FFMPEG_BIN = "ffmpeg"  # Try to use from PATH
TMP_DIR     = "/tmp"

# Logging
log = logging.getLogger()
log.setLevel(logging.INFO)

def _extract_frames(video_path: str, out_dir: str) -> None:
    """Extract frames from video using ffmpeg at specified frame rate."""
    # Try to locate ffmpeg
    try:
        # Log the ffmpeg path being used
        log.info(f"Using ffmpeg from: {FFMPEG_BIN}")
        
        # List directory contents to help debug
        if FFMPEG_BIN.startswith("/opt"):
            log.info(f"Contents of /opt: {os.listdir('/opt') if os.path.exists('/opt') else 'directory not found'}")
            if os.path.exists('/opt/bin'):
                log.info(f"Contents of /opt/bin: {os.listdir('/opt/bin')}")
        
        cmd = [
            FFMPEG_BIN,
            "-i", video_path,
            "-vf", f"fps={FRAME_RATE}",
            os.path.join(out_dir, "frame_%06d.jpg"),
        ]
        log.info("Running ffmpeg: %s", " ".join(cmd))
        subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    except FileNotFoundError:
        log.error(f"ffmpeg not found at {FFMPEG_BIN}")
        # Try to download a static ffmpeg binary as fallback
        try:
            fallback_ffmpeg = "/tmp/ffmpeg"
            if not os.path.exists(fallback_ffmpeg):
                log.info("Attempting to use AWS CLI to extract frames instead")
                # Use simpler approach without ffmpeg
                raise NotImplementedError("Fallback extraction not implemented")
            else:
                cmd[0] = fallback_ffmpeg
                log.info("Retrying with fallback ffmpeg: %s", " ".join(cmd))
                subprocess.check_call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
        except Exception as e:
            log.error(f"Fallback extraction failed: {str(e)}")
            raise

def handler(event, context):
    # Step 1: Get video file info from S3 event
    record = event["Records"][0]["s3"]
    input_bucket = record["bucket"]["name"]
    video_key = urllib.parse.unquote_plus(record["object"]["key"])
    basename = os.path.splitext(os.path.basename(video_key))[0]

    if input_bucket != RAW_BUCKET:
        log.warning("Unexpected bucket. Expected: %s, Got: %s", RAW_BUCKET, input_bucket)

    # Step 2: Download video to /tmp
    local_video = os.path.join(TMP_DIR, f"{basename}-{uuid.uuid4()}.mp4")
    log.info("Downloading video: s3://%s/%s", input_bucket, video_key)
    log.info("Expected bucket from env: %s", RAW_BUCKET)
    
    try:
        # Check if the object exists and get its size
        response = s3.head_object(Bucket=input_bucket, Key=video_key)
        file_size = response.get('ContentLength', 0)
        
        # Check if file size exceeds /tmp capacity (512 MB by default)
        if file_size > 450 * 1024 * 1024:  # 450 MB to leave some buffer
            log.error(f"Video file too large: {file_size / (1024 * 1024):.2f} MB exceeds /tmp capacity")
            raise ValueError(f"Video file too large: {file_size / (1024 * 1024):.2f} MB")
            
        log.info(f"Object exists ({file_size / (1024 * 1024):.2f} MB), proceeding with download")
        s3.download_file(input_bucket, video_key, local_video)
    except Exception as e:
        log.error("Error accessing S3: %s", str(e))
        raise

    # Step 3: Extract frames
    frame_dir = os.path.join(TMP_DIR, f"frames-{uuid.uuid4()}")
    os.makedirs(frame_dir, exist_ok=True)
    _extract_frames(local_video, frame_dir)

    # Step 4: Upload frames to dump bucket
    uploaded_frames = 0
    for frame_path in sorted(glob.glob(os.path.join(frame_dir, "*.jpg"))):
        frame_name = os.path.basename(frame_path)
        dump_key = f"frames/{basename}/{frame_name}"

        s3.upload_file(frame_path, DUMP_BUCKET, dump_key)
        uploaded_frames += 1
        log.info("Uploaded frame to s3://%s/%s", DUMP_BUCKET, dump_key)

    # Clean local files
    shutil.rmtree(frame_dir, ignore_errors=True)
    if os.path.exists(local_video):
        os.remove(local_video)

    return {
        "video_key": video_key,
        "uploaded_frames": uploaded_frames
    }