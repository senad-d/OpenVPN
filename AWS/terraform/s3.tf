resource "aws_s3_bucket" "users" {
  bucket        = "${var.resources_name}-${var.env}-vpn-users"
  force_destroy = true
  tags = {
    Name        = "${var.resources_name}-${var.env}-vpn-users"
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.users.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "users" {
  depends_on = [aws_s3_bucket_ownership_controls.ownership_controls]
  bucket     = aws_s3_bucket.users.id
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.users.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "users" {
  bucket = aws_s3_bucket.users.id

  rule {
    id     = "users"
    status = "Enabled"

    noncurrent_version_expiration {
      newer_noncurrent_versions = 25
      noncurrent_days           = 14
    }

  }
}

resource "aws_s3_bucket_policy" "users_bucket_policy" {
  bucket = aws_s3_bucket.users.id
  policy = data.aws_iam_policy_document.allow_ec2.json
}

data "aws_iam_policy_document" "allow_ec2" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        aws_iam_role.vpn.arn
      ]
    }
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
    ]
    resources = [
      aws_s3_bucket.users.arn,
      "${aws_s3_bucket.users.arn}/*",
    ]
  }
}

resource "aws_ssm_parameter" "vpn_s3_id" {
  name        = "${var.resources_name}-${var.env}-vpn-users"
  description = "S3 bucket name parameter for SSM Use within GitHub Actions"
  type        = "String"
  value       = aws_s3_bucket.users.id
  tags = {
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}
