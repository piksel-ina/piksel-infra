output "repository_username" {
  description = "User name decoded from the authorization token"
  value       = data.aws_ecrpublic_authorization_token.token.user_name
  sensitive   = true
}

output "repository_password" {
  description = "Password decoded from the authorization token."
  value       = data.aws_ecrpublic_authorization_token.token.password
  sensitive   = true
}
