import os
import boto3
from ultralytics import YOLO
import tempfile

# ---------- CONFIGURATION ----------
S3_BUCKET = os.getenv("S3_BUCKET")  # default bucket
PROCESSING_PREFIX = "processing/"
RESULTS_PREFIX = "results/"
MODEL_PATH = "best.pt"  # model included in Docker image
CONFIDENCE_THRESHOLD = 0.98  # minimum confidence to be considered high
# -----------------------------------

s3 = boto3.client("s3")

# Load YOLO model
print("Loading YOLO model...")
model = YOLO(MODEL_PATH)
print("Model loaded successfully!")

def process_images():
    """Fetch images from S3, classify, and move only one image to results depending on confidence."""
    response = s3.list_objects_v2(Bucket=S3_BUCKET, Prefix=PROCESSING_PREFIX)

    if "Contents" not in response:
        print("No images found in processing folder.")
        return

    images_info = []

    for item in response["Contents"]:
        key = item["Key"]
        if key.endswith("/"):
            continue

        with tempfile.NamedTemporaryFile(suffix=".jpg") as tmp_file:
            s3.download_file(S3_BUCKET, key, tmp_file.name)
            results = model.predict(tmp_file.name)
            top_result = results[0].probs.top1
            class_name = results[0].names[top_result]
            confidence = results[0].probs.top1conf.item()
            images_info.append({
                "key": key,
                "class_name": class_name.lower(),
                "confidence": confidence
            })
            print(f"Processed {key}: {class_name} ({confidence:.2f})")

    # Separate high-confidence car crashes and others
    high_conf = [img for img in images_info if img["class_name"] == "carcrash" and img["confidence"] >= CONFIDENCE_THRESHOLD]
    if high_conf:
        # Pick the one with highest confidence
        selected = max(high_conf, key=lambda x: x["confidence"])
    else:
        # Pick the highest confidence image below threshold
        selected = max(images_info, key=lambda x: x["confidence"])

    # Copy the selected image to results/
    result_key = selected["key"].replace(PROCESSING_PREFIX, RESULTS_PREFIX, 1)
    s3.copy_object(
        Bucket=S3_BUCKET,
        CopySource={"Bucket": S3_BUCKET, "Key": selected["key"]},
        Key=result_key
    )
    print(f"Selected image '{selected['key']}' ({selected['confidence']:.2f}) moved to {RESULTS_PREFIX}")

if __name__ == "__main__":
    print("Starting YOLO classification job...")
    process_images()
    print("Job completed.")
