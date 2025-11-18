# ------ General Use NodeClass for Jupyter Sandboxes ------
resource "kubectl_manifest" "karpenter_node_class_jupyter" {
  depends_on = [
    helm_release.karpenter,
    time_sleep.wait_for_karpenter
  ]

  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: jupyter
      labels:
        app.kubernetes.io/managed-by: terraform
    spec:
      amiFamily: AL2023
      role: ${module.karpenter.node_iam_role_name}
      amiSelectorTerms:
        - alias: ${var.default_nodepool_ami_alias}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 40Gi
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.cluster}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.cluster}
      tags:
        Workload: "Jupyter-Sandboxes"
        User-type: "Standard-Users"
  YAML
}

# --- Standard NodePool ---
resource "kubectl_manifest" "karpenter_node_pool_jupyter_standard" {
  depends_on = [kubectl_manifest.karpenter_node_class_jupyter]

  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: jupyter-standard
      labels:
        app.kubernetes.io/managed-by: terraform
    spec:
      template:
        metadata:
          labels:
            jupyter-profile: standard
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: jupyter

          taints:
            - key: jupyter-profile
              value: standard
              effect: NoSchedule

          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]

            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]

            - key: kubernetes.io/os
              operator: In
              values: ["linux"]

            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["r7i", "r6i", "r5"]

            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["large"]

      limits:
        cpu: ${var.default_nodepool_node_limit}

      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 5m
        expireAfter: 168h

        budgets:
          - nodes: "100%"
  YAML
}

# --- Development NodeClass for Jupyter Sandboxes ------
resource "kubectl_manifest" "karpenter_node_class_develop_jupyter" {
  depends_on = [
    helm_release.karpenter,
    time_sleep.wait_for_karpenter
  ]

  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: dev-jupyter
      labels:
        app.kubernetes.io/managed-by: terraform
    spec:
      amiFamily: AL2023
      role: ${module.karpenter.node_iam_role_name}
      amiSelectorTerms:
        - alias: ${var.default_nodepool_ami_alias}
      blockDeviceMappings:
        - deviceName: /dev/xvda
          ebs:
            volumeSize: 80Gi
            volumeType: gp3
            encrypted: true
            deleteOnTermination: true
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.cluster}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.cluster}
      tags:
        Workload: "Jupyter-Sandboxes"
        User-type: "Advanced-Users"
  YAML
}

# --- Medium NodePool ---
resource "kubectl_manifest" "karpenter_node_pool_develop_jupyter_medium" {
  depends_on = [kubectl_manifest.karpenter_node_class_develop_jupyter]

  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: jupyter-medium
      labels:
        app.kubernetes.io/managed-by: terraform
    spec:
      template:
        metadata:
          labels:
            jupyter-profile: medium
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: dev-jupyter

          taints:
            - key: jupyter-profile
              value: medium
              effect: NoSchedule

          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]

            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]

            - key: kubernetes.io/os
              operator: In
              values: ["linux"]

            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["r7i", "r6i", "r5"]

            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["xlarge"]

      limits:
        cpu: ${var.default_nodepool_node_limit}

      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 5m
        expireAfter: 168h

        budgets:
          - nodes: "100%"
  YAML
}

# --- Large Instances NodePool ---
resource "kubectl_manifest" "karpenter_node_pool_jupyter_large" {
  depends_on = [kubectl_manifest.karpenter_node_class_develop_jupyter]

  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: jupyter-large
      labels:
        app.kubernetes.io/managed-by: terraform
    spec:
      template:
        metadata:
          labels:
            jupyter-profile: large
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: dev-jupyter

          taints:
            - key: jupyter-profile
              value: large
              effect: NoSchedule

          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]

            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]

            - key: kubernetes.io/os
              operator: In
              values: ["linux"]

            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["r7i", "r6i", "r5"]

            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["2xlarge"]

      limits:
        cpu: ${var.default_nodepool_node_limit}

      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 5m
        expireAfter: 168h

        budgets:
          - nodes: "100%"
  YAML
}
