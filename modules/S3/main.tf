terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
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

locals {
  suffix = random_string.suffix.result
}

# --------------------------------------------------------------------
# Raw & processed (dump) buckets
# --------------------------------------------------------------------

resource "aws_s3_bucket" "raw" {
  bucket = "offline-video-raw-${locals.suffix}"
  force_destroy = true
}

resource "aws_s3_bucket" "dump_bucket" {
  bucket = "dump-video-image-${locals.suffix}"
  force_destroy = true
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