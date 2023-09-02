data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "selected" {
  tags = {
    Name        = "${var.resources_name}-${var.env}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  tags = {
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
    Layer       = "public"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
