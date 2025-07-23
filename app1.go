package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/sfn"
	"github.com/aws/aws-sdk-go/service/sns"
)

var (
	sess            = session.Must(session.NewSession())
	s3Client        = s3.New(sess)
	sfnClient       = sfn.New(sess)
	snsClient       = sns.New(sess)
	rawBucket       = os.Getenv("S3_BUCKET_R")
	dumpBucket      = os.Getenv("S3_BUCKET_D")
	stepFunctionArn = os.Getenv("STEP_FUNCTION_ARN")
	snsTopicArn     = os.Getenv("SNS_TOPIC_ARN")
	frameRate       = os.Getenv("FRAME_RATE")
	minConfidence   = os.Getenv("MIN_CONFIDENCE") // could be passed to next stage
)

func handler(ctx context.Context, s3Event events.S3Event) error {
	for _, record := range s3Event.Records {
		videoKey := record.S3.Object.Key

		log.Printf("Video upload detected: %s", videoKey)

		tmpVideo := "/tmp/input.mp4"
		outputPattern := "/tmp/frame-%03d.jpg"

		// Step 1: Download video
		obj, err := s3Client.GetObject(&s3.GetObjectInput{
			Bucket: aws.String(rawBucket),
			Key:    aws.String(videoKey),
		})
		if err != nil {
			return fmt.Errorf("failed to download video: %v", err)
		}
		defer obj.Body.Close()

		outFile, err := os.Create(tmpVideo)
		if err != nil {
			return fmt.Errorf("failed to create temp video file: %v", err)
		}
		io.Copy(outFile, obj.Body)
		outFile.Close()

		// Step 2: Extract frames using ffmpeg
		cmd := exec.Command("ffmpeg", "-i", tmpVideo, "-vf", fmt.Sprintf("fps=%s", frameRate), outputPattern)
		if out, err := cmd.CombinedOutput(); err != nil {
			log.Printf("ffmpeg error: %s", string(out))
			return fmt.Errorf("ffmpeg failed: %v", err)
		}

		// Step 3: Upload extracted frames
		frames, _ := filepath.Glob("/tmp/frame-*.jpg")
		if len(frames) == 0 {
			return fmt.Errorf("no frames generated")
		}

		for _, path := range frames {
			frameFile, _ := os.Open(path)
			buf := new(bytes.Buffer)
			io.Copy(buf, frameFile)
			frameFile.Close()

			frameKey := fmt.Sprintf("frames/%s/%s", filepath.Base(videoKey), filepath.Base(path))
			_, err := s3Client.PutObject(&s3.PutObjectInput{
				Bucket: aws.String(dumpBucket),
				Key:    aws.String(frameKey),
				Body:   bytes.NewReader(buf.Bytes()),
			})
			if err != nil {
				log.Printf("failed to upload frame: %v", err)
			} else {
				log.Printf("uploaded frame: %s", frameKey)
			}
		}

		// Step 4: Trigger Step Function
		inputJSON, _ := json.Marshal(map[string]string{
			"video_key":      videoKey,
			"bucket":         dumpBucket,
			"min_confidence": minConfidence,
		})
		_, err = sfnClient.StartExecution(&sfn.StartExecutionInput{
			StateMachineArn: aws.String(stepFunctionArn),
			Input:           aws.String(string(inputJSON)),
		})
		if err != nil {
			log.Printf("Failed to start Step Function: %v", err)
		} else {
			log.Println("Step Function execution started")
		}

		// Step 5: Optional SNS Notification
		message := fmt.Sprintf("Video %s processed, %d frames uploaded.", videoKey, len(frames))
		_, err = snsClient.Publish(&sns.PublishInput{
			TopicArn: aws.String(snsTopicArn),
			Message:  aws.String(message),
		})
		if err != nil {
			log.Printf("SNS publish failed: %v", err)
		} else {
			log.Println("SNS notification sent.")
		}
	}

	return nil
}

func main() {
	lambda.Start(handler)
}
