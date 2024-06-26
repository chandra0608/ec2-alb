locals {
  ingress_rules = [
    {
      description       = "Allow SSH"
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
      security_group_id = null
      ipv6_cidr_blocks  = []
      self              = false
    },
    {
      description       = "Allow HTTP"
      from_port         = 80
      to_port           = 80
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
      security_group_id = null
      ipv6_cidr_blocks  = []
      self              = false
    }
  ]

  egress_rules = [
    {
      description       = "Allow all outbound traffic"
      from_port         = 0
      to_port           = 0
      protocol          = "-1"
      cidr_blocks       = ["0.0.0.0/0"]
      security_group_id = null
      ipv6_cidr_blocks  = []
    }
  ]
}
