provider "aws" {
  region = var.aws_region
}


resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "s3-object-created"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": [var.s3_bucket]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "stepfunction" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  arn       = var.stepfunction_arn
  role_arn  = aws_iam_role.events.arn
}

resource "aws_iam_role" "events" {
  name = "events_invoke_stepfunctions"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
}

data "aws_iam_policy_document" "events_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

# Create an SNS topic for notifications
resource "aws_sns_topic" "file_processing_topic" {
  name = "file-processing-topic"
}

# Email subscription for SNS topic
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.file_processing_topic.arn  
  protocol  = "email"
  endpoint  = var.email_endpoint  # Add this variable to your variables.tf
}



