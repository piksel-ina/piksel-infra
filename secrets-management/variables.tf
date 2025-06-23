variable "region" {
  description = "AWS region for secrets"
  type        = string
  default     = "ap-southeast-3"
}

variable "slack_secrets" {
  description = "Map of Slack webhook secrets to create"
  type = map(object({
    secret_string = string
    description   = string
    project       = string
    service       = string
    tenant        = string
  }))
  default = {}
}

variable "oauth_secrets" {
  description = "Map of OAuth client secrets to create"
  type = map(object({
    client_id     = string
    client_secret = string
    description   = string
    project       = string
    service       = string
    tenant        = string
  }))
  default = {}
}
