provider "aws" {
  region = var.region
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  for_each   = var.instances
  key_name   = each.value.name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

data "aws_iam_policy_document" "ec2_ebs_kms" {
  statement {
    actions   = ["kms:*"]
    resources = ["*"]
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_kms_key" "this" {
  for_each                = var.instances
  description             = "KMS key for EC2 EBS encryption."
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.ec2_ebs_kms.json
}

resource "aws_instance" "this" {
  for_each                    = var.instances
  ami                         = var.ami_id
  associate_public_ip_address = each.value.associate_public_ip_address
  disable_api_termination     = each.value.disable_api_termination
  disable_api_stop            = each.value.disable_api_stop
  ebs_optimized               = each.value.ebs_optimized
  iam_instance_profile        = aws_iam_instance_profile.this[each.key].name
  instance_type               = each.value.instance_type
  key_name                    = aws_key_pair.generated_key[each.key].key_name
  monitoring                  = each.value.monitoring
  subnet_id                   = each.value.subnet_id
  user_data                   = each.value.user_data_raw
  vpc_security_group_ids      = [aws_security_group.sg[each.key].id]
  #availability_zone           = each.value.availability_zone

  metadata_options {
    http_endpoint = each.value.metadata_endpoint_enabled
    http_tokens   = each.value.metadata_options_http_tokens
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = each.value.ebs_volume_root.iops
    kms_key_id            = each.value.ebs_volume_root.kms_key_id
    throughput            = each.value.ebs_volume_root.throughput
    volume_size           = each.value.ebs_volume_root.size
    volume_type           = each.value.ebs_volume_root.type
  }

  lifecycle {
    ignore_changes = [
      user_data,
      associate_public_ip_address
    ]
  }

  tags = {
    Name = each.value.name
  }
}

resource "aws_iam_instance_profile" "this" {
  for_each = var.instances
  name     = "${each.value.name}-profile"
}

resource "aws_iam_role" "this" {
  for_each = var.instances
  name     = "${each.value.name}-role"
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

resource "aws_iam_role_policy" "ssm_params_and_secrets" {
  for_each = var.instances
  name     = "${each.value.name}-policy"
  role     = aws_iam_role.this[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "secretsmanager:GetSecretValue"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_security_group" "sg" {
  for_each    = var.instances
  name        = each.value.name
  vpc_id      = var.vpc_id
  description = each.value.description

  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      security_groups  = ingress.value.security_group_id != null ? [ingress.value.security_group_id] : []
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      self             = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = each.value.egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      security_groups  = egress.value.security_group_id != null ? [egress.value.security_group_id] : []
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
    }
  }

  tags = {
    Name = each.value.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

