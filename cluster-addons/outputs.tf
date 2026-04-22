output "cert_manager_status" {
  description = "cert-manager Helm release status"
  value = {
    name      = helm_release.cert_manager.name
    namespace = helm_release.cert_manager.namespace
    version   = helm_release.cert_manager.version
    status    = helm_release.cert_manager.status
  }
}

output "ingress_nginx_status" {
  description = "ingress-nginx Helm release status"
  value = {
    name      = helm_release.ingress_nginx.name
    namespace = helm_release.ingress_nginx.namespace
    version   = helm_release.ingress_nginx.version
    status    = helm_release.ingress_nginx.status
  }
}

output "metrics_server_status" {
  description = "metrics-server Helm release status"
  value = {
    name      = helm_release.metrics_server.name
    namespace = helm_release.metrics_server.namespace
    version   = helm_release.metrics_server.version
    status    = helm_release.metrics_server.status
  }
}

output "nvidia_device_plugin_status" {
  description = "nvidia-device-plugin Helm release status"
  value = {
    name      = helm_release.nvidia_device_plugin.name
    namespace = helm_release.nvidia_device_plugin.namespace
    version   = helm_release.nvidia_device_plugin.version
    status    = helm_release.nvidia_device_plugin.status
  }
}

output "efs_csi_driver_status" {
  description = "aws-efs-csi-driver Helm release status"
  value = {
    name      = helm_release.aws_efs_csi_driver.name
    namespace = helm_release.aws_efs_csi_driver.namespace
    version   = helm_release.aws_efs_csi_driver.version
    status    = helm_release.aws_efs_csi_driver.status
  }
}
