# --- EFS Resources ---

# --- Security group for EFS ---
resource "aws_security_group" "efs" {
  name_prefix = "${local.cluster}-efs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.cluster_primary_security_group_id]
    description     = "NFS traffic from EKS cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.cluster}-efs-sg"
  })
}

# --- EFS File System ---
resource "aws_efs_file_system" "main" {
  creation_token = "${local.cluster}-efs"

  throughput_mode = "bursting" # or "elastic"/"provisioned"
  # provisioned_throughput_in_mibps = 100 # Uncomment and set if using "provisioned"

  tags = merge(local.tags, {
    Name = "${local.cluster}-efs"
  })
}

# --- EFS Mount Targets ---
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnets_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnets_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

# --- Public data access point ---
# read-only for most, read-write for data admins
resource "aws_efs_access_point" "public_data" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/data/public"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755" # rwxr-xr-x (read-only for group/others)
    }
  }

  tags = merge(local.tags, {
    Name        = "${local.cluster}-efs-public-data"
    Type        = "public-readonly"
    Description = "Public datasets - read-only for users"
  })
}

# --- Coastline changes project access point ---
resource "aws_efs_access_point" "coastline_changes" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 2000 # coastline-changes group
    uid = 1000 # standard user
  }

  root_directory {
    path = "/data/coastline-changes"
    creation_info {
      owner_gid   = 2000
      owner_uid   = 1000
      permissions = "775" # rwxrwxr-x (read-write for group members)
    }
  }

  tags = merge(local.tags, {
    Name        = "${local.cluster}-efs-coastline-changes"
    Type        = "project-collaborative"
    Description = "Coastline changes project workspace - collaborative access"
  })
}



# --- Outputs ---
output "efs_file_system_id" {
  description = "ID of the EFS File System"
  value       = aws_efs_file_system.main.id
}

output "efs_file_system_arn" {
  description = "ARN of the EFS File System"
  value       = aws_efs_file_system.main.arn
}

output "efs_security_group_id" {
  description = "ID of the Security Group for EFS"
  value       = aws_security_group.efs.id
}

output "efs_mount_target_ids" {
  description = "List of IDs for EFS Mount Targets"
  value       = aws_efs_mount_target.main[*].id
}

output "public_data_access_point_id" {
  description = "ID of the Public Data Access Point"
  value       = aws_efs_access_point.public_data.id
}

output "public_data_access_point_arn" {
  description = "ARN of the Public Data Access Point"
  value       = aws_efs_access_point.public_data.arn
}

output "coastline_changes_access_point_id" {
  description = "ID of the Coastline Changes Project Access Point"
  value       = aws_efs_access_point.coastline_changes.id
}

output "coastline_changes_access_point_arn" {
  description = "ARN of the Coastline Changes Project Access Point"
  value       = aws_efs_access_point.coastline_changes.arn
}
