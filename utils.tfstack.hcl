# --- Supporting EC2 ---

variable "dev_instance_type" {
  description = "EC2 instance type for personal dev instance"
  type        = string
  default     = "t3.large"
}

variable "dev_volume_size" {
  description = "Size of the root volume for personal dev EC2 in GB"
  type        = number
  default     = 20
}

variable "create_test_ec2" {
  description = "Boolean to control whether to create the testing EC2 instance"
  type        = bool
  default     = false
}

variable "create_dev_ec2" {
  description = "Boolean to control whether to create the personal dev EC2 instance"
  type        = bool
  default     = false
}

component "ec2" {
  source = "./aws-ec2"

  inputs = {
    vpc_id            = component.vpc.vpc_id
    subnet_id         = component.vpc.public_subnets[0]
    create_test_ec2   = var.create_test_ec2
    create_dev_ec2    = var.create_dev_ec2
    dev_instance_type = var.dev_instance_type
    dev_volume_size   = var.dev_volume_size
  }

  providers = {
    aws   = provider.aws.configurations
    local = provider.local.this
    tls   = provider.tls.this
  }
}
