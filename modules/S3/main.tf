provider "aws" {
  region = var.aws_region
}
locals {
  common_tags = {
    Application = "video-crash-detector"
    Owner       = "bob"
  }
}
# --------------------------------------------------------------------
# Random suffix to keep bucket names globally unique
# --------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}


resource "aws_s3_bucket" "raw" {
  bucket        = "offline-video-raw-${random_string.suffix.result}"
  force_destroy = true
  tags = local.common_tags
}

# Enable EventBridge notifications for the raw bucket
resource "aws_s3_bucket_notification" "raw_bucket_notification" {
  bucket = aws_s3_bucket.raw.id

  eventbridge = true
}

resource "aws_s3_bucket" "dump_bucket" {
  bucket        = "dump-video-image-${random_string.suffix.result}"
  force_destroy = true
  tags = local.common_tags
}

# --------------------------------------------------------------------
# Block all public access – strongly recommended for private pipelines
# --------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
}

resource "aws_s3_bucket_public_access_block" "dump" {
  bucket                  = aws_s3_bucket.dump_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



# ############################################
#   IAM ROLES                                 #
# ############################################
resource "aws_iam_role" "s3_raw_role" {
  name = "s3_raw_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role" "s3_dump_role" {
  name = "s3_dump_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = [
          "lambda.amazonaws.com",
          "states.amazonaws.com"
        ]
      }
    }]
  })
  tags = local.common_tags
}
# ############################################
#   IAM POLICIES                               #
# ############################################
resource "aws_iam_policy" "s3_raw_policy" {
  name        = "s3_raw_policy"
  description = "Policy for accessing raw S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [                  
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = [
        aws_s3_bucket.raw.arn,    
        "${aws_s3_bucket.raw.arn}/*"
      ]
    }]
  })
  tags = local.common_tags
} 
resource "aws_iam_policy" "s3_dump_policy" {
  name        = "s3_dump_policy"
  description = "Policy for accessing dump S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [                  
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ]
      Resource = [
        aws_s3_bucket.dump_bucket.arn,    
        "${aws_s3_bucket.dump_bucket.arn}/*"
      ]
    }]
  })
  tags = local.common_tags
}
# ############################################
#   IAM ROLE POLICIES                          #
# ############################################
resource "aws_iam_role_policy_attachment" "s3_raw_role_policy" {
  role       = aws_iam_role.s3_raw_role.name        
  policy_arn = aws_iam_policy.s3_raw_policy.arn
  
}

resource "aws_iam_role_policy_attachment" "s3_dump_role_policy" {
  role       = aws_iam_role.s3_dump_role.name        
  policy_arn = aws_iam_policy.s3_dump_policy.arn
}