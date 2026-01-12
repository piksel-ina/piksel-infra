output "default_vpc_id" {
  value       = aws_default_vpc.default
  description = "Default VPC ID used"
}

output "default_subnet_ids" {
  value       = local.default_subnet_ids
  description = "Subnets found in the default VPC"
}

output "key_pair_names" {
  value       = { for k in keys(var.instances) : k => local.keypair_name_by_instance[k] }
  description = "Per-instance EC2 Key Pair names"
}

output "pem_paths" {
  value       = { for k in keys(var.instances) : k => local.pem_path_by_instance[k] }
  description = "Per-instance PEM file paths written locally"
}

output "instance_ids" {
  value = { for k, v in aws_instance.this : k => v.id }
}

output "public_ips" {
  value = { for k, v in aws_instance.this : k => v.public_ip }
}
