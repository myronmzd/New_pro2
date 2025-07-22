provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Application = "video-crash-detector"
    Owner       = "bob"
  }
}

resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = "s3-object-created"
  description = "Capture S3 object creation events"
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": [var.s3_bucket_raw]
      },
      "object": {
        "key": [{
          "prefix": "raw/"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "stepfunction" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  arn       = var.stepfunction_arn
  role_arn  = aws_iam_role.events.arn
  
  # Transform the S3 event into the format expected by Step Functions
  input_transformer {
    input_paths = {
      bucket = "$.detail.bucket.name",
      key    = "$.detail.object.key"
    }
    input_template = <<EOF
{
  "bucket": "<bucket>",
  "key": "<key>"
}
EOF
  }
}

resource "aws_iam_role" "events" {
  name = "events_invoke_stepfunctions"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
  tags = local.common_tags
  
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

resource "aws_iam_role_policy" "allow_step_function" {
  name = "allow_start_execution"
  role = aws_iam_role.events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "states:StartExecution"
        Resource = var.stepfunction_arn
      }
    ]
  })
  
  
}

# Create an SNS topic for notifications
resource "aws_sns_topic" "file_processing_topic" {
  name = "file-processing-topic"
  tags = local.common_tags
}

# Email subscription for SNS topic
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.file_processing_topic.arn  
  protocol  = "email"
  endpoint  = var.email_endpoint 
}



