import boto3
import os

ses_client = boto3.client("ses")
s3 = boto3.client("s3")

# Environment variables
OUTPUT_BUCKET = os.environ.get("S3_BUCKET_D")  # Dump bucket (contains results/images)
SENDER_EMAIL = os.environ.get("SENDER_EMAIL")
RECIPIENT_EMAIL = os.environ.get("RECIPIENT_EMAIL")

def lambda_handler(event, context):
    print("Received event:", event)

    # List objects in /results folder
    prefix = "results/"
    try:
        response = s3.list_objects_v2(
            Bucket=OUTPUT_BUCKET,
            Prefix=prefix
        )

        if "Contents" not in response:
            print("No images found in results folder.")
            return {"status": "no_results"}

        image_keys = [obj["Key"] for obj in response["Contents"] if obj["Key"].lower().endswith((".jpg", ".png"))]

        if not image_keys:
            print("No images found in results folder.")
            return {"status": "no_images"}

        # Generate S3 URLs (public-style; switch to presigned if bucket is private)
        image_urls = [
            f"https://{OUTPUT_BUCKET}.s3.amazonaws.com/{key}"
            for key in image_keys
        ]

        # Email content
        subject = "🚨 Alert: Car Crash Detected"
        body = f"""
A potential car crash event was detected.

📂 S3 Bucket: {OUTPUT_BUCKET}
📁 Folder: results/

🖼️ Detected Images:
{chr(10).join(image_urls)}

This is an automated alert.
        """

        # Send email via SES
        response = ses_client.send_email(
            Source=SENDER_EMAIL,
            Destination={"ToAddresses": [RECIPIENT_EMAIL]},
            Message={
                "Subject": {"Data": subject},
                "Body": {"Text": {"Data": body}}
            }
        )

        print("Email sent! Message ID:", response["MessageId"])
        return {"status": "success", "message_id": response["MessageId"]}

    except Exception as e:
        print("Error:", str(e))
        raise
