resource "random_id" "suffix" {
  byte_length = 4
}


resource "aws_s3_bucket" "raw" {
  bucket = "offline-video-raw-${random_id.suffix.hex}"
  force_destroy = true
}


