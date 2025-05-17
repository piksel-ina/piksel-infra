variable "vpc_id" {
  description = "ID of the VPC to deploy the EC2 instances"
  default     = "vpc-0e6ae39878ebb0013"
}

variable "subnet_id" {
  description = "ID of the public subnet to deploy the EC2 instances"
  default     = "subnet-003afdf05b81e4f28"
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  default     = "ec2-keypair"
}

variable "test_instance_type" {
  description = "EC2 instance type for testing instance"
  default     = "t3.micro"
}

variable "dev_instance_type" {
  description = "EC2 instance type for personal dev instance"
  default     = "t3.large"
}

variable "dev_volume_size" {
  description = "Size of the root volume for personal dev EC2 in GB"
  type        = number
  default     = 20
}

variable "local_key_path" {
  description = "Local path to save the generated SSH key files"
  default     = "./keys"
}

variable "create_test_ec2" {
  description = "Boolean to control whether to create the testing EC2 instance"
  type        = bool
  default     = true
}

variable "create_dev_ec2" {
  description = "Boolean to control whether to create the personal dev EC2 instance"
  type        = bool
  default     = true
}
