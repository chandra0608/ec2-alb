variable "region" {
  description = "The AWS region to deploy resources."
  type        = string
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instances."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where resources will be deployed."
  type        = list(string)
}

variable "alb_name" {
  description = "Name of the Application Load Balancer (ALB)."
  type        = string
}

variable "target_group_name" {
  description = "Name of the target group for ALB."
  type        = string
}

variable "listener_port" {
  description = "Port for the ALB listener."
  type        = number
}

variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = null
}

variable "instances" {
  description = "Map of instances with configurations."
  type = map(object({
    name                         = string
    instance_type                = string
    associate_public_ip_address  = bool
    disable_api_termination      = bool
    disable_api_stop             = bool
    ebs_optimized                = bool
    monitoring                   = bool
    subnet_id                    = string
    user_data_raw                = string
    security_group_ids           = list(string)
    metadata_endpoint_enabled    = string
    metadata_options_http_tokens = string
    #availability_zone            = string
    ebs_volume_root = object({
      iops       = number
      kms_key_id = string
      throughput = number
      size       = number
      type       = string
    })
    description = string
    ingress_rules = list(object({
      description       = string
      from_port         = number
      to_port           = number
      protocol          = string
      cidr_blocks       = list(string)
      security_group_id = string
      ipv6_cidr_blocks  = list(string)
      self              = bool
    }))
    egress_rules = list(object({
      description       = string
      from_port         = number
      to_port           = number
      protocol          = string
      cidr_blocks       = list(string)
      security_group_id = string
      ipv6_cidr_blocks  = list(string)
    }))
    tags = map(string)
  }))
}
