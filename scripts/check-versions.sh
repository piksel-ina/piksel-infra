#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/ensure-context.sh"

ENVIRONMENT=$1

if [ "$ENVIRONMENT" = "staging" ]; then
    ensure_context "$STAGING_CONTEXT"
    AWS_PROFILE="$AWS_PROFILE_STAGING"
    CLUSTER_NAME="$CLUSTER_NAME_STAGING"
else
    echo -e "${RED}Error: Invalid environment. Use 'staging'${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}${BLUE}=== Cluster Version ===${NC}"
CLUSTER_VERSION=$(kubectl version --short 2>/dev/null | grep "Server Version" | awk '{print $3}' || kubectl version -o json 2>/dev/null | jq -r '.serverVersion.gitVersion')
echo -e "  Control plane: ${CYAN}${CLUSTER_VERSION}${NC}"

NODE_VERSIONS=$(kubectl get nodes -o jsonpath='{range .items[*]}{.status.nodeInfo.kubeletVersion}{"\n"}{end}' | sort -u)
NODE_COUNT=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.kubeletVersion}' | tr ' ' '\n' | wc -l)
UNIQUE_COUNT=$(echo "$NODE_VERSIONS" | wc -l)
echo -e "  Nodes (${NODE_COUNT} total): ${CYAN}$(echo "$NODE_VERSIONS" | tr '\n' ', ' | sed 's/,$//')${NC}"

if [ "$UNIQUE_COUNT" -gt 1 ]; then
    echo -e "  ${YELLOW}Warning: ${UNIQUE_COUNT} different node versions detected${NC}"
fi

echo ""
echo -e "${BOLD}${BLUE}=== Addon Versions (installed vs recommended) ===${NC}"
echo -e "  EKS target: ${CYAN}${EKS_VERSION}${NC}  |  Region: ${CYAN}${AWS_REGION}${NC}"
echo ""

check_addon() {
    local ADDON_NAME=$1
    local DISPLAY_NAME=$2

    INSTALLED=$(aws eks describe-addon \
        --cluster-name "$CLUSTER_NAME" \
        --addon-name "$ADDON_NAME" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'addon.addonVersion' \
        --output text 2>/dev/null || echo "n/a")

    RECOMMENDED=$(aws eks describe-addon-versions \
        --addon-name "$ADDON_NAME" \
        --kubernetes-version "$EKS_VERSION" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'addons[0].addonVersions[0].addonVersion' \
        --output text 2>/dev/null || echo "n/a")

    if [ "$INSTALLED" = "$RECOMMENDED" ]; then
        STATUS="${GREEN}OK${NC}"
    elif [ "$INSTALLED" = "n/a" ]; then
        STATUS="${YELLOW}not managed${NC}"
    else
        STATUS="${RED}UPDATE AVAILABLE${NC}"
    fi

    echo -e "  ${BOLD}${DISPLAY_NAME}${NC}"
    echo -e "    Installed:   ${CYAN}${INSTALLED}${NC}"
    echo -e "    Recommended: ${CYAN}${RECOMMENDED}${NC}"
    echo -e "    Status:      ${STATUS}"
    echo ""
}

check_addon "coredns" "CoreDNS"
check_addon "vpc-cni" "VPC CNI"
check_addon "kube-proxy" "kube-proxy"
check_addon "aws-ebs-csi-driver" "EBS CSI Driver"
check_addon "eks-pod-identity-agent" "Pod Identity Agent"
