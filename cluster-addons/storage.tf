# --- EBS StorageClasses ---

resource "kubectl_manifest" "gp2_storageclass" {
  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "gp2"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "false"
      }
    }
    provisioner = "kubernetes.io/aws-ebs"
    parameters = {
      fsType = "ext4"
      type   = "gp2"
    }
    allowVolumeExpansion = false
    volumeBindingMode    = "WaitForFirstConsumer"
    reclaimPolicy        = "Delete"
  })
}

resource "kubectl_manifest" "gp3_storageclass" {
  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "gp3"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner = "ebs.csi.aws.com"
    parameters = {
      type      = "gp3"
      fsType    = "ext4"
      encrypted = "true"
    }
    allowVolumeExpansion = true
    volumeBindingMode    = "WaitForFirstConsumer"
    reclaimPolicy        = "Delete"
  })
}

# --- EFS StorageClasses (depend on EFS CSI driver) ---

resource "kubectl_manifest" "efs_public_readonly_storageclass" {
  depends_on = [helm_release.aws_efs_csi_driver]

  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "efs-public-readonly"
    }
    provisioner = "efs.csi.aws.com"
    parameters = {
      provisioningMode = "efs-ap"
      fileSystemId     = var.efs_filesystem_id
      directoryPerms   = "755"
      gidRangeStart    = "1000"
      gidRangeEnd      = "2000"
      basePath         = "/data/public"
    }
    reclaimPolicy        = "Retain"
    volumeBindingMode    = "Immediate"
    allowVolumeExpansion = true
  })
}

resource "kubectl_manifest" "efs_coastline_rw_storageclass" {
  depends_on = [helm_release.aws_efs_csi_driver]

  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "efs-coastline-rw"
    }
    provisioner = "efs.csi.aws.com"
    parameters = {
      provisioningMode = "efs-ap"
      fileSystemId     = var.efs_filesystem_id
      directoryPerms   = "770"
      gidRangeStart    = "2000"
      gidRangeEnd      = "3000"
      basePath         = "/data/coastline"
      uid              = "1000"
      gid              = "2000"
    }
    reclaimPolicy        = "Retain"
    volumeBindingMode    = "Immediate"
    allowVolumeExpansion = true
  })
}

resource "kubectl_manifest" "efs_full_access_storageclass" {
  depends_on = [helm_release.aws_efs_csi_driver]

  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "efs-full-access"
    }
    provisioner = "efs.csi.aws.com"
    parameters = {
      provisioningMode = "efs-ap"
      fileSystemId     = var.efs_filesystem_id
      directoryPerms   = "770"
      gidRangeStart    = "3000"
      gidRangeEnd      = "4000"
      basePath         = "/data"
      uid              = "1000"
      gid              = "3000"
    }
    reclaimPolicy        = "Retain"
    volumeBindingMode    = "Immediate"
    allowVolumeExpansion = true
  })
}
