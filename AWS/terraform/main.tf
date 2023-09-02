locals {
  ami_ids = {
    "ap-south-1"     = "ami-01d06f5c7a92fbb1d",
    "eu-north-1"     = "ami-07b56e94f0571198c",
    "eu-west-3"      = "ami-069f70ea7ca09e346",
    "eu-west-2"      = "ami-02dccea1ab4d54d42",
    "eu-west-1"      = "ami-0d9f43af2e488ad35",
    "ap-northeast-3" = "ami-08e6a1b4b5cf18310",
    "ap-northeast-2" = "ami-0e835baafa8fa0070",
    "ap-northeast-1" = "ami-004460d8812df089a",
    "ca-central-1"   = "ami-0a6cd466cd97f9b1c",
    "sa-east-1"      = "ami-009781ec3362189d6",
    "ap-southeast-1" = "ami-0b92bd622ba82a167",
    "ap-southeast-2" = "ami-0c779f1c058d5a13a",
    "eu-central-1"   = "ami-00c4331464df0b6df",
    "us-east-1"      = "ami-094a6bc555227c6d4",
    "us-east-2"      = "ami-02640c819cdd1f00b",
    "us-west-1"      = "ami-063a4879e6e2ff31d",
    "us-west-2"      = "ami-0db242c59c596bedb"
  }
  current_region = data.aws_region.current.name
}

resource "aws_instance" "vpn_ec2" {
  depends_on           = [aws_network_interface.vpn_eni]
  ami                  = local.ami_ids[local.current_region]
  instance_type        = "t3.micro"
  availability_zone    = data.aws_availability_zones.available.names[0]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  key_name             = var.ssh_key
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.vpn_eni.id
  }
  user_data = templatefile("userData.tftpl", {
    Email        = var.email,
    Admin        = var.admin,
    Organization = var.organization,
    Company      = var.company,
    Region       = data.aws_availability_zones.available.names[0],
    VpcCIDR      = data.aws_vpc.selected.cidr_block,
    Cert         = var.certificate_duration_days
  })

  root_block_device {
    volume_type = "gp2"
    volume_size = "8"
  }

  lifecycle {
    ignore_changes = [user_data, ami]
  }

  tags = {
    Name        = "${var.resources_name}-${var.env}-vpn"
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}

resource "aws_security_group" "vpn_security_group" {
  name        = "${var.resources_name}-${var.env}-vpn"
  description = "Security group for VPN"
  vpc_id      = data.aws_vpc.selected.id

  tags = {
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}

resource "aws_security_group_rule" "allow_vpn_ingress" {
  type              = "ingress"
  from_port         = 1194
  protocol          = "udp"
  to_port           = 1194
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpn_security_group.id
}

resource "aws_security_group_rule" "allow_vpc_egress" {
  type              = "egress"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.vpn_security_group.id
}

resource "aws_security_group_rule" "allow_https_egress" {
  type              = "egress"
  from_port         = 443
  protocol          = "tcp"
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpn_security_group.id
}

resource "aws_security_group_rule" "allow_http_egress" {
  type              = "egress"
  from_port         = 80
  protocol          = "tcp"
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpn_security_group.id
}

resource "aws_security_group_rule" "allow_vpn_egress" {
  type              = "egress"
  from_port         = 1194
  protocol          = "udp"
  to_port           = 1194
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpn_security_group.id
}

resource "aws_ssm_parameter" "vpn_id" {
  name        = "${var.resources_name}-${var.env}-vpn-ec2-id"
  description = "EC2 id parameter for SSM Use within GitHub Actions"
  type        = "String"
  value       = aws_instance.vpn_ec2.id
  tags = {
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}
