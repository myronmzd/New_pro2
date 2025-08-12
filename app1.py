import boto3
import os

ses_client = boto3.client('ses')

# Replace with your verified sender and recipient email
SENDER_EMAIL = os.environ.get("SENDER_EMAIL")  # e.g., alerts@yourdomain.com
RECIPIENT_EMAIL = os.environ.get("RECIPIENT_EMAIL")  # e.g., admin@yourdomain.com

def lambda_handler(event, context):
    print("Received event:", event)

    # Extract info from Step Function input
    video_key = event.get("video_key")
    bucket = event.get("bucket")
    details = event.get("details", {})

    if not video_key or not bucket:
        raise ValueError("Missing required input: video_key or bucket")

    # Generate a public or internal S3 URL (if public access is granted)
    video_url = f"https://s3.amazonaws.com/{bucket}/{video_key}"

    subject = "🚨 Video Alert: Crash or Crime Event Detected"
    body = f"""
A new event has been detected in a processed video.

📂 S3 Bucket: {bucket}
🎥 Video Key: {video_key}
🔗 Video URL: {video_url}

📝 Additional Info:
{details}

This message was automatically sent by your Step Function workflow.
    """

    try:
        response = ses_client.send_email(
            Source=SENDER_EMAIL,
            Destination={
                'ToAddresses': [RECIPIENT_EMAIL]
            },
            Message={
                'Subject': {'Data': subject},
                'Body': {
                    'Text': {'Data': body}
                }
            }
        )
        print("Email sent! Message ID:", response['MessageId'])
        return {"status": "success", "message_id": response['MessageId']}

    except Exception as e:
        print("Error sending email:", str(e))
        raise
