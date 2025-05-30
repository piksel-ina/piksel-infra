output "repository_username" {
  description = "User name decoded from the authorization token"
  value       = var.enable_token_refresh && length(data.aws_ecrpublic_authorization_token.token) > 0 ? data.aws_ecrpublic_authorization_token.token[0].user_name : null
  sensitive   = true
}

output "repository_password" {
  description = "Password decoded from the authorization token."
  value       = var.enable_token_refresh && length(data.aws_ecrpublic_authorization_token.token) > 0 ? data.aws_ecrpublic_authorization_token.token[0].password : null
  sensitive   = true
}
