resource "aws_iam_role" "stepfunctions" {
  name = "stepfunctions_exec_role"
  assume_role_policy = data.aws_iam_policy_document.stepfunctions_assume_role.json
}

data "aws_iam_policy_document" "stepfunctions_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_sfn_state_machine" "etl" {
  name     = "offline-video-analyse"
  role_arn = aws_iam_role.stepfunctions.arn
  definition = templatefile("${path.module}/state_machine.json", {
    lambda_arn = var.lambda_arn
    s3_bucket  = var.s3_bucket
  })
}

