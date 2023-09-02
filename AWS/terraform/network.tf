resource "aws_network_interface" "vpn_eni" {
  description     = "OpenVPN ENI for FlowLogs"
  subnet_id       = "subnet-00ad69d85de74aa9d" #data.aws_subnets.public.id
  security_groups = [aws_security_group.vpn_security_group.id]
  tags = {
    Name        = "${var.resources_name}-${var.env}-vpn"
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}

resource "aws_eip" "vpn_eip" {
  tags = {
    Name        = "${var.resources_name}-${var.env}-vpn"
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
  instance = aws_instance.vpn_ec2.id
}

resource "aws_cloudwatch_log_group" "vpn_log_group" {
  depends_on = [aws_iam_role.vpn_flow_logs_role]
  name       = "${var.resources_name}-${var.env}-vpn"
}

resource "aws_flow_log" "vpn_flow_logs" {
  iam_role_arn    = aws_iam_role.vpn_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpn_log_group.arn
  traffic_type    = "ALL"
  eni_id          = aws_network_interface.vpn_eni.id
  tags = {
    Name        = "${var.resources_name}-${var.env}-vpn"
    Project     = "${var.project}"
    ProjectId   = "${var.project_id}"
    Environment = "${var.env}"
  }
}
