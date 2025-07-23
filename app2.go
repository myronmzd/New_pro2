package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/rekognition"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sns"
)

var (
	sess          = session.Must(session.NewSession())
	s3Client      = s3.New(sess)
	rekClient     = rekognition.New(sess)
	snsClient     = sns.New(sess)
	dumpBucket    = os.Getenv("S3_BUCKET_D")
	modelArn      = os.Getenv("MODEL_ARN")
	snsTopicArn   = os.Getenv("SNS_TOPIC_ARN")
	minConfidence = os.Getenv("MIN_CONFIDENCE")
)

func handler(ctx context.Context, s3Event events.S3Event) error {
	crashDetected := false
	crashImageKey := ""

	for _, record := range s3Event.Records {
		imgKey := record.S3.Object.Key
		log.Printf("Processing image: %s", imgKey)

		// Step 1: Download image from S3
		obj, err := s3Client.GetObject(&s3.GetObjectInput{
			Bucket: aws.String(dumpBucket),
			Key:    aws.String(imgKey),
		})
		if err != nil {
			log.Printf("Failed to get image: %v", err)
			continue
		}
		defer obj.Body.Close()

		imgBuf := new(bytes.Buffer)
		io.Copy(imgBuf, obj.Body)

		// Step 2: Detect custom label (car crash)
		detectRes, err := rekClient.DetectCustomLabels(&rekognition.DetectCustomLabelsInput{
			Image: &rekognition.Image{
				Bytes: imgBuf.Bytes(),
			},
			MinConfidence:     aws.Float64(stringToFloat(minConfidence)),
			ProjectVersionArn: aws.String(modelArn),
		})
		if err != nil {
			log.Printf("Rekognition failed: %v", err)
			continue
		}

		hasCrash := false
		for _, label := range detectRes.CustomLabels {
			if strings.ToLower(*label.Name) == "carcrash" && *label.Confidence >= stringToFloat(minConfidence) {
				hasCrash = true
				break
			}
		}

		if hasCrash && !crashDetected {
			crashDetected = true
			crashImageKey = imgKey

			log.Printf("Crash detected in image: %s", imgKey)

			// Step 3: Send to SNS (Base64 or URL)
			imgB64 := base64.StdEncoding.EncodeToString(imgBuf.Bytes())

			msg := map[string]string{
				"bucket":       dumpBucket,
				"key":          imgKey,
				"image_base64": imgB64,
			}
			msgBytes, _ := json.Marshal(msg)

			_, err = snsClient.Publish(&sns.PublishInput{
				TopicArn: aws.String(snsTopicArn),
				Message:  aws.String(string(msgBytes)),
				Subject:  aws.String("🚨 Car Crash Detected"),
			})
			if err != nil {
				log.Printf("SNS send failed: %v", err)
			}
		}
	}

	// Step 4: Delete all images except the crash image
	if crashDetected {
		log.Printf("Cleaning up all non-crash frames...")
		for _, record := range s3Event.Records {
			key := record.S3.Object.Key
			if key != crashImageKey {
				_, err := s3Client.DeleteObject(&s3.DeleteObjectInput{
					Bucket: aws.String(dumpBucket),
					Key:    aws.String(key),
				})
				if err != nil {
					log.Printf("Failed to delete image: %s, error: %v", key, err)
				} else {
					log.Printf("Deleted image: %s", key)
				}
			}
		}
	}

	return nil
}

func stringToFloat(s string) float64 {
	f, _ := fmt.Sscanf(s, "%f", new(float64))
	return *new(float64)
}

func main() {
	lambda.Start(handler)
}
