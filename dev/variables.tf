variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "dev"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "allowed_account_ids" {
  type        = list(string)
  description = "Ensure deployment to the intended AWS account"
}

variable "ssh_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH in"
  default     = ["0.0.0.0/0"]
}

variable "keypair_name_prefix" {
  type        = string
  description = "Prefix for EC2 Key Pair names. Instance name will be appended."
  default     = "dev-instance-"
}

variable "ssh_private_key_dir" {
  type        = string
  description = "Directory to write per-instance private keys"
  default     = ".secrets"
}

# --- Autostop schedule ---
variable "autostop_group_name" {
  type        = string
  description = "Tag value used to group instances for autostop (informational in this setup)"
  default     = "dev-nightly"
}

variable "autostop_schedule_expression" {
  type        = string
  description = "EventBridge schedule expression (UTC). 19:00 WIB = 12:00 UTC => cron(0 12 * * ? *)"
  default     = "cron(0 12 * * ? *)"
}

# --- Instances map ---
variable "instances" {
  description = "Map of instances to create"
  type = map(object({
    subnet_id = optional(string)

    instance_type = string

    associate_public_ip      = optional(bool, true)
    root_volume_gb           = optional(number, 20)
    extra_security_group_ids = optional(list(string), [])
    enable_autostop          = optional(bool, true)
    tags                     = optional(map(string), {})
  }))
}
