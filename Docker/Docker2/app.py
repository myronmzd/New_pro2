import os
import boto3
import tempfile
import cv2
from ultralytics import YOLO
from botocore.exceptions import ClientError

# ---------- CONFIGURATION ----------
S3_BUCKET = os.getenv("S3_BUCKET")
PROCESSING_PREFIX = os.getenv("PROCESSING_PREFIX", "processing/")
RESULTS_PREFIX = os.getenv("RESULTS_PREFIX", "results/")
MODEL_PATH = os.getenv("MODEL_PATH", "best.pt")
CONFIDENCE_THRESHOLD = float(os.getenv("CONFIDENCE_THRESHOLD", 0.99))
TARGET_IMAGE_SIZE = (640, 640)  # YOLO input size
BATCH_SIZE = 4  # CPU-friendly batch size
# -----------------------------------

# Initialize S3 client
s3 = boto3.client("s3")

# Load YOLO model
print("Loading YOLO model...")
model = YOLO(MODEL_PATH)
print("Model loaded successfully!")

def resize_image_cv2(img_array, target_size=TARGET_IMAGE_SIZE):
    """Resize a NumPy image array."""
    return cv2.resize(img_array, target_size, interpolation=cv2.INTER_AREA)

def download_images_from_s3(keys):
    """Download images from S3 and return list of local paths and original keys."""
    local_paths = []
    valid_keys = []
    for key in keys:
        if key.endswith("/"):  # Skip directories
            continue
        try:
            tmp_file = tempfile.NamedTemporaryFile(suffix=".jpg", delete=False)
            s3.download_file(S3_BUCKET, key, tmp_file.name)
            img = cv2.imread(tmp_file.name)
            if img is None:
                continue
            # Resize image for YOLO
            resized_img = resize_image_cv2(img)
            cv2.imwrite(tmp_file.name, resized_img)
            local_paths.append(tmp_file.name)
            valid_keys.append(key)
        except ClientError as e:
            print(f"[ERROR] Failed to download {key}: {e}")
    return local_paths, valid_keys

def batch_chunks(lst, batch_size=BATCH_SIZE):
    """Yield successive batch-sized chunks from list."""
    for i in range(0, len(lst), batch_size):
        yield lst[i:i + batch_size]

def process_images_batch():
    """Fetch images from S3, run batch YOLO predictions, and move matching images to results."""
    try:
        response = s3.list_objects_v2(Bucket=S3_BUCKET, Prefix=PROCESSING_PREFIX)
    except ClientError as e:
        print(f"[ERROR] Failed to list S3 objects: {e}")
        return

    if "Contents" not in response:
        print("[INFO] No images found in processing folder.")
        return

    s3_keys = [item["Key"] for item in response["Contents"]]
    local_paths, valid_keys = download_images_from_s3(s3_keys)

    if not local_paths:
        print("[INFO] No valid images downloaded.")
        return

    images_info = []

    # Process images in batches
    for chunk_paths, chunk_keys in zip(batch_chunks(local_paths), batch_chunks(valid_keys)):
        results_batch = model.predict(chunk_paths, verbose=False)

        for key, res in zip(chunk_keys, results_batch):
            if not res or len(res) == 0:
                continue
            # Top classification result
            top_result = res.probs.top1
            class_name = res.names[top_result]
            confidence = res.probs.top1conf.item()
            images_info.append({
                "key": key,
                "class_name": class_name.lower(),
                "confidence": confidence,
            })
            print(f"[INFO] Processed {key}: {class_name} ({confidence:.2f})")

    if not images_info:
        print("[INFO] No predictions obtained.")
        return

    # Filter for carcrash images with confidence >= 1.0
    high_conf_carcrash = [
        img for img in images_info
        if img["class_name"] == "carcrash" and img["confidence"] >= 1.0
    ]

    # If more than one image matches, copy all of them to results/
    if len(high_conf_carcrash) > 1:
        print(f"[INFO] Found {len(high_conf_carcrash)} high-confidence car crash images.")
        for img in high_conf_carcrash:
            result_key = img["key"].replace(PROCESSING_PREFIX, RESULTS_PREFIX, 1)
            try:
                s3.copy_object(
                    Bucket=S3_BUCKET,
                    CopySource={"Bucket": S3_BUCKET, "Key": img["key"]},
                    Key=result_key
                )
                print(f"[SUCCESS] Copied {img['key']} to {RESULTS_PREFIX}")
            except ClientError as e:
                print(f"[ERROR] Failed to copy {img['key']}: {e}")
    else:
        print("[INFO] Not enough high-confidence car crash images found. Nothing copied.")

if __name__ == "__main__":
    print("[INFO] Starting YOLO batch classification job...")
    process_images_batch()
    print("[INFO] Job completed.")
