provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "acm"
}

module "ec2_instances" {
  source = "../"

  region            = "us-east-1"
  ami_id            = data.aws_ami.this.id
  vpc_id            = data.aws_vpc.vpc.id
  subnet_ids        = data.aws_subnets.public.ids
  alb_name          = "my-alb"
  target_group_name = "my-target-group"
  listener_port     = 80

  instances = {
    instance1 = {
      name                         = "example-instance-1"
      instance_type                = "t3.micro"
      associate_public_ip_address  = true
      disable_api_termination      = false
      disable_api_stop             = false
      ebs_optimized                = true
      monitoring                   = false
      subnet_id                    = data.aws_subnets.public.ids[0] # Use the first public subnet ID
      user_data_raw                = ""
      security_group_ids           = [] # Provide existing security group IDs here, or leave empty to create new ones
      metadata_endpoint_enabled    = "enabled"
      metadata_options_http_tokens = "required"
      ebs_volume_root = {
        iops       = 100
        kms_key_id = null # Optional KMS key ID
        throughput = 125
        size       = 30
        type       = "gp3"
      }
      description   = "Security group for example-instance-1"
      ingress_rules = local.ingress_rules
      egress_rules  = local.egress_rules
      tags          = {}
    },
    instance2 = {
      name                         = "example-instance-2"
      instance_type                = "t3.micro"
      associate_public_ip_address  = true
      disable_api_termination      = false
      disable_api_stop             = false
      ebs_optimized                = true
      monitoring                   = false
      subnet_id                    = data.aws_subnets.public.ids[1] # Use the second public subnet ID
      user_data_raw                = ""
      security_group_ids           = [] # Provide existing security group IDs here, or leave empty to create new ones
      metadata_endpoint_enabled    = "enabled"
      metadata_options_http_tokens = "required"
      ebs_volume_root = {
        iops       = 100
        kms_key_id = null # Optional KMS key ID
        throughput = 125
        size       = 30
        type       = "gp3"
      }
      description   = "Security group for example-instance-2"
      ingress_rules = local.ingress_rules
      egress_rules  = local.egress_rules
      tags          = {}
    }
  }
}



module "alb" {
  source = "../module/alb"

  name                       = "elb-arc"
  enable                     = true
  internal                   = false
  load_balancer_type         = "application"
  instance_count             = 2
  subnets                    = data.aws_subnets.public.ids
  target_id                  = values(module.ec2_instances.instance_ids)
  vpc_id                     = data.aws_vpc.vpc.id
  allowed_ip                 = ["0.0.0.0/0"]
  allowed_ports              = [80,443]
  listener_certificate_arn   = data.aws_acm_certificate.this.arn
  enable_deletion_protection = false
  with_target_group          = true
  https_enabled              = true
  http_enabled               = true
  https_port                 = 443
  listener_type              = "forward"
  target_group_port          = 80
  namespace                  = "arc-test"
  tags                       = var.tags

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    }
  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "TLS"
      target_group_index = 0
      certificate_arn    = data.aws_acm_certificate.this.arn
    },
  ]

  target_groups = [
    {
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 300
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 10
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  extra_ssl_certs = [
    {
      https_listener_index = 0
      certificate_arn      = data.aws_acm_certificate.this.arn
    }
  ]
}