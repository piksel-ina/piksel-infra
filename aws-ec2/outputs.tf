# --- Outputs ---
output "test_ec2_public_ip" {
  description = "Public IP of the testing EC2 instance"
  value       = var.create_test_ec2 ? aws_instance.test_ec2[0].public_ip : "Not created (create_test_ec2 = false)"
}

output "test_ssh_command" {
  description = "SSH command to connect to the testing instance"
  value       = var.create_test_ec2 ? "ssh -i ${var.local_key_path}/${var.key_name}.pem -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@${aws_instance.test_ec2[0].private_ip}" : "Not created (create_test_ec2 = false)"
}

output "bastion_ssh_command" {
  description = "SSH command to connect directly to the bastion host"
  value       = var.create_test_ec2 ? "ssh -i ${var.local_key_path}/${var.key_name}.pem ubuntu@${aws_instance.bastion[0].public_ip}" : "Not created (create_test_ec2 = false)"
}

output "dev_ec2_public_ip" {
  description = "Public IP of the personal dev EC2 instance"
  value       = var.create_dev_ec2 ? aws_instance.dev_ec2[0].public_ip : "Not created (create_dev_ec2 = false)"
}

output "dev_ssh_command" {
  description = "SSH command to connect to the personal dev instance"
  value       = var.create_dev_ec2 ? "ssh -i ${var.local_key_path}/${var.key_name}.pem ubuntu@${aws_instance.dev_ec2[0].public_ip}" : "Not created (create_dev_ec2 = false)"
}

output "private_key_path" {
  description = "Path to the generated private key file"
  value       = (var.create_test_ec2 || var.create_dev_ec2) ? "${var.local_key_path}/${var.key_name}.pem" : "Not created (no instances requested)"
}

output "public_key_path" {
  description = "Path to the generated public key file"
  value       = (var.create_test_ec2 || var.create_dev_ec2) ? "${var.local_key_path}/${var.key_name}.pub" : "Not created (no instances requested)"
}

output "test_target_ec2_ip" {
  description = "Private IP of the Dev VPC test target EC2 instance"
  value       = var.create_test_target_ec2 ? aws_instance.dev_test_target_ec2[0].private_ip : "Not created"
}
