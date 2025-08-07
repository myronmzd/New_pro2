import os
import json
import boto3
import cv2
from ultralytics import YOLO
from PIL import Image
import numpy as np

class VideoProcessor:
    def __init__(self):
        self.s3 = boto3.client('s3')
        self.rekognition = boto3.client('rekognition')
        self.input_bucket = os.environ['INPUT_BUCKET']
        self.output_bucket = os.environ['OUTPUT_BUCKET']
        self.model = YOLO('yolov8n.pt')  # Load YOLOv8 model
        
    def process_video(self, video_key):
        # Download video from S3
        local_video = '/tmp/video.mp4'
        self.s3.download_file(self.input_bucket, video_key, local_video)
        
        # Process video with AI model
        cap = cv2.VideoCapture(local_video)
        results = []
        frame_count = 0
        
        while cap.read()[0]:
            ret, frame = cap.read()
            if not ret:
                break
                
            # Run YOLO detection
            detections = self.model(frame)
            
            # Check for crash/crime events
            for detection in detections:
                if self.is_crash_or_crime(detection):
                    # Generate thumbnail
                    thumbnail_path = f'/tmp/thumbnail_{frame_count}.jpg'
                    cv2.imwrite(thumbnail_path, frame)
                    
                    # Upload thumbnail to S3
                    thumbnail_key = f"thumbnails/{video_key}_frame_{frame_count}.jpg"
                    self.s3.upload_file(thumbnail_path, self.output_bucket, thumbnail_key)
                    
                    results.append({
                        'frame': frame_count,
                        'detection': detection.names,
                        'confidence': float(detection.conf.max()),
                        'thumbnail': thumbnail_key
                    })
                    break
            
            frame_count += 1
        
        cap.release()
        
        # Save results JSON
        results_key = f"results/{video_key}_results.json"
        self.s3.put_object(
            Bucket=self.output_bucket,
            Key=results_key,
            Body=json.dumps(results),
            ContentType='application/json'
        )
        
        return results
    
    def is_crash_or_crime(self, detection):
        # Simple logic to detect crash/crime events
        crash_classes = ['car', 'truck', 'motorcycle', 'person']
        detected_classes = [detection.names[int(cls)] for cls in detection.boxes.cls]
        return any(cls in crash_classes for cls in detected_classes)

if __name__ == "__main__":
    processor = VideoProcessor()
    
    # Get video key from environment or event
    video_key = os.environ.get('VIDEO_KEY', 'raw/sample_video.mp4')
    
    try:
        results = processor.process_video(video_key)
        print(f"Processing complete. Found {len(results)} events.")
    except Exception as e:
        print(f"Error processing video: {str(e)}")
        raise