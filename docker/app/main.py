import os
import sys
import json
import tempfile
import boto3
import traceback
import threading
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from ultralytics import YOLO
import cv2

s3 = boto3.client("s3", region_name=os.environ.get("AWS_REGION"))

RAW_BUCKET = os.environ.get("RAW_BUCKET")
PROCESSED_BUCKET = os.environ.get("PROCESSED_BUCKET")
INPUT_KEY = os.environ.get("INPUT_S3_KEY")  # lambda overrides this at run time

if not INPUT_KEY:
    print("No INPUT_S3_KEY found, exiting.")
    sys.exit(1)

def download_s3(bucket, key, local_path):
    print(f"Downloading s3://{bucket}/{key} to {local_path}")
    s3.download_file(bucket, key, local_path)

def upload_s3(bucket, key, local_path, content_type=None):
    print(f"Uploading {local_path} -> s3://{bucket}/{key}")
    extra_args = {}
    if content_type:
        extra_args['ContentType'] = content_type
    s3.upload_file(local_path, bucket, key, ExtraArgs=extra_args)

def make_thumbnail(video_path, thumbnail_path):
    cap = cv2.VideoCapture(video_path)
    success, frame = cap.read()
    if not success:
        raise RuntimeError("Could not read frame for thumbnail.")
    # save jpg
    cv2.imwrite(thumbnail_path, frame)
    cap.release()

def run_yolo(video_path, output_json_path):
    print("Loading YOLO model (this may download weights if not present)...")
    model = YOLO("yolov8n.pt")  # light model - ultralytics will auto-download weights
    print("Running inference...")
    results = model.predict(source=video_path, save=False, imgsz=640, conf=0.25, device="0" if os.environ.get("CUDA_VISIBLE_DEVICES") else "cpu")
    # results is an iterable; convert to JSON-like structure
    all_dets = []
    for r in results:
        boxes = []
        # r.boxes is a Boxes object; extract xyxy, conf, cls
        for box in r.boxes:
            xyxy = box.xyxy.tolist()[0] if hasattr(box.xyxy, "tolist") else list(map(float, box.xyxy))
            conf = float(box.conf.tolist()[0]) if hasattr(box.conf, "tolist") else float(box.conf)
            cls = int(box.cls.tolist()[0]) if hasattr(box.cls, "tolist") else int(box.cls)
            boxes.append({
                "xyxy": xyxy,
                "confidence": conf,
                "class": cls,
                "class_name": model.names.get(cls, str(cls))
            })
        all_dets.append({
            "boxes": boxes,
            "speed": getattr(r, "speed", None)
        })
    # write json
    with open(output_json_path, "w") as fh:
        json.dump({"detections": all_dets, "video": os.path.basename(video_path)}, fh, indent=2)
    print("Wrote JSON:", output_json_path)

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy"}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass  # Suppress default logging

def start_health_server():
    """Start health check server in background thread"""
    server = HTTPServer(('0.0.0.0', 8080), HealthHandler)
    server.serve_forever()

def process_video():
    """Main video processing function"""
    try:
        with tempfile.TemporaryDirectory() as tmp:
            local_video = os.path.join(tmp, "input_video")
            download_s3(RAW_BUCKET, INPUT_KEY, local_video)

            thumb_path = os.path.join(tmp, "thumbnail.jpg")
            make_thumbnail(local_video, thumb_path)

            results_json = os.path.join(tmp, "results.json")
            run_yolo(local_video, results_json)

            # upload outputs under processed/<original-key>/
            base_prefix = f"processed/{INPUT_KEY}"
            upload_s3(PROCESSED_BUCKET, f"{base_prefix}/thumbnail.jpg", thumb_path, content_type="image/jpeg")
            upload_s3(PROCESSED_BUCKET, f"{base_prefix}/results.json", results_json, content_type="application/json")
            print("Processing complete.")
            return True
    except Exception:
        traceback.print_exc()
        return False

def main():
    # Start health check server in background
    health_thread = threading.Thread(target=start_health_server, daemon=True)
    health_thread.start()
    print("Health check server started on port 8080")
    
    # Check if this is a one-time processing job or long-running service
    if INPUT_KEY:
        # One-time processing
        success = process_video()
        sys.exit(0 if success else 1)
    else:
        # Long-running service mode (for Fargate services)
        print("Running in service mode - waiting for tasks...")
        while True:
            time.sleep(30)  # Keep container alive

if __name__ == "__main__":
    main()
