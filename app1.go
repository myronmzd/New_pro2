package main

import (
    "context"
    "fmt"

    "github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-lambda-go/lambda"
    "github.com/aws/aws-sdk-go/aws/session"
    "github.com/aws/aws-sdk-go/service/rekognition"
    "github.com/aws/aws-sdk-go/service/s3"
    "github.com/aws/aws-sdk-go/service/sns"
)

func handler(ctx context.Context, s3Event events.S3Event) error {
    sess := session.Must(session.NewSession())
    s3client := s3.New(sess)
    rekog := rekognition.New(sess)
    snsClient := sns.New(sess)

    for _, record := range s3Event.Records {
        bucket := record.S3.Bucket.Name
        key := record.S3.Object.Key

        // Call Rekognition
        input := &rekognition.DetectCustomLabelsInput{
            Image: &rekognition.Image{
                S3Object: &rekognition.S3Object{
                    Bucket: &bucket,
                    Name:   &key,
                },
            },
            ProjectVersionArn: "YOUR_REKOGNITION_MODEL_ARN",
        }
        result, err := rekog.DetectCustomLabels(input)
        if err != nil {
            return err
        }

        // If car crash detected, send to SNS
        for _, label := range result.CustomLabels {
            if *label.Name == "CarCrash" && *label.Confidence > 80 {
                _, err := snsClient.Publish(&sns.PublishInput{
                    Message:  fmt.Sprintf("Car crash detected in %s/%s", bucket, key),
                    TopicArn: aws.String("YOUR_SNS_TOPIC_ARN"),
                })
                if err != nil {
                    return err
                }
            }
        }

        // Delete image from S3
        _, err = s3client.DeleteObject(&s3.DeleteObjectInput{
            Bucket: &bucket,
            Key:    &key,
        })
        if err != nil {
            return err
        }
    }
    return nil
}

func main() {
    lambda.Start(handler)
}