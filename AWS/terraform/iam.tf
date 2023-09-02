resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.resources_name}-${var.env}-instance-profile"
  role = aws_iam_role.vpn.name
}

resource "aws_iam_role" "vpn" {
  name = "${var.resources_name}-${var.env}-vpn"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpn_allow_describe_policy" {
  name = "${var.resources_name}-${var.env}-vpn-allow-describe-policy"
  role = aws_iam_role.vpn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeRegions",
          "ec2:DescribeInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "vpn_allow_ses_policy" {
  name = "${var.resources_name}-${var.env}-vpn-allow-ses-policy"
  role = aws_iam_role.vpn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "vpn_allow_s3_policy" {
  name = "${var.resources_name}-${var.env}-vpn-allow-s3-policy"
  role = aws_iam_role.vpn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.users.bucket}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role" "vpn_flow_logs_role" {
  name = "${var.resources_name}-${var.env}-vpn-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpn_flow_logs_policy" {
  name = "${var.resources_name}-${var.env}-flow-logs-policy"
  role = aws_iam_role.vpn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vpn_ssm_managed_instance_core" {
  role       = aws_iam_role.vpn.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}