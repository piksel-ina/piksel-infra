#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/ensure-context.sh"

ensure_context "$STAGING_CONTEXT"

AWS_PROFILE="$AWS_PROFILE_STAGING"
CLUSTER_NAME="$CLUSTER_NAME_STAGING"

echo ""
echo -e "${BOLD}${BLUE}=== EKS AMI Check — Alias vs AWS Recommended ===${NC}"
echo -e "  EKS Version: ${CYAN}${EKS_VERSION}${NC}  |  Region: ${CYAN}${AWS_REGION}${NC}"
echo ""

get_ssm_ami() {
    local TYPE=$1
    local PARAM="/aws/service/eks/optimized-ami/${EKS_VERSION}/amazon-linux-2023/${ARCHITECTURE}/${TYPE}/recommended"

    aws ssm get-parameter \
        --name "$PARAM" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query "Parameter.Value" \
        --output text 2>/dev/null | jq -r '{id: .image_id, version: .release_version}'
}

check_nodeclass() {
    local CLASS_NAME=$1
    local AMI_TYPE=$2

    echo -e "${BOLD}--- EC2NodeClass: ${CLASS_NAME} ---${NC}"

    ALIAS=$(kubectl get ec2nodeclass "$CLASS_NAME" -o jsonpath='{.spec.amiSelectorTerms[0].alias}' 2>/dev/null)
    if [ -z "$ALIAS" ]; then
        echo -e "  ${YELLOW}Not using alias selector (uses name selector — manual AMI)${NC}"
        AMI_NAME=$(kubectl get ec2nodeclass "$CLASS_NAME" -o jsonpath='{.spec.amiSelectorTerms[0].name}' 2>/dev/null)
        RESOLVED_ID=$(kubectl get ec2nodeclass "$CLASS_NAME" -o json 2>/dev/null | jq -r '.status.amis[0].id // "unknown"')
        echo -e "  AMI name: ${CYAN}${AMI_NAME}${NC}"
        echo -e "  Resolved: ${CYAN}${RESOLVED_ID}${NC}"
        echo ""
        return
    fi

    RESOLVED_ID=$(kubectl get ec2nodeclass "$CLASS_NAME" -o json 2>/dev/null | jq -r '.status.amis[] | select(.requirements == [] or (.requirements | length == 0)) | .id // empty' 2>/dev/null)
    if [ -z "$RESOLVED_ID" ]; then
        RESOLVED_ID=$(kubectl get ec2nodeclass "$CLASS_NAME" -o json 2>/dev/null | jq -r '[.status.amis[] | select(.requirements // [] | all(.key != "karpenter.k8s.aws/instance-gpu-count"))] | .[0].id // "unknown"' 2>/dev/null)
    fi

    echo -e "  Configured alias: ${CYAN}${ALIAS}${NC}"
    echo -e "  Resolves to:      ${CYAN}${RESOLVED_ID}${NC}"

    LATEST=$(get_ssm_ami "$AMI_TYPE")
    LATEST_ID=$(echo "$LATEST" | jq -r '.id')
    LATEST_VER=$(echo "$LATEST" | jq -r '.version')

    echo -e "  AWS recommended:  ${GREEN}${LATEST_ID}${NC} (${LATEST_VER})"

    if [ "$RESOLVED_ID" = "$LATEST_ID" ]; then
        echo -e "  Status:           ${GREEN}OK — alias is up to date${NC}"
    else
        echo -e "  Status:           ${RED}OUTDATED — update alias in staging/main.tf${NC}"
        echo -e "                   ${YELLOW}default_nodepool_ami_alias = \"al2023@latest\"${NC}"
        echo -e "                   Then run: make plan-staging && make apply-staging"
    fi
    echo ""
}

check_nodeclass "default" "standard"
check_nodeclass "gpu" "nvidia"

echo -e "${BOLD}--- Running Nodes ---${NC}"

INSTANCE_IDS=$(kubectl get nodes -o jsonpath='{range .items[*]}{.spec.providerID}{"\n"}{end}' | sed 's|aws:///[^/]*/||')

if [ -z "$INSTANCE_IDS" ]; then
    echo -e "  ${YELLOW}No nodes found${NC}"
    exit 0
fi

TOTAL=$(echo "$INSTANCE_IDS" | wc -l | tr -d ' ')

AMI_MAP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_IDS \
    --region "$AWS_REGION" \
    --profile "$AWS_PROFILE" \
    --query 'Reservations[].Instances[].[InstanceId,ImageId,State.Name]' \
    --output text 2>/dev/null)

STANDARD_AMI=$(kubectl get ec2nodeclass default -o json 2>/dev/null | jq -r '.status.amis[0].id // "unknown"')

STALE=0
OK=0
while read -r IID AMI STATE; do
    if [ "$AMI" = "$STANDARD_AMI" ]; then
        OK=$((OK + 1))
    else
        if [ $STALE -eq 0 ]; then
            echo -e "  ${RED}STALE${NC} (first ${STALE_COUNT:-0} shown):"
        fi
        NODE_NAME=$(kubectl get node -o json | jq -r --arg iid "$IID" '.items[] | select(.spec.providerID | endswith($iid)) | .metadata.name')
        echo -e "    ${NODE_NAME}  (${AMI})"
        STALE=$((STALE + 1))
    fi
done <<< "$AMI_MAP"

if [ $STALE -eq 0 ]; then
    echo -e "  ${GREEN}All ${TOTAL} node(s) match the current NodeClass alias${NC}"
else
    echo -e "  ${RED}${STALE}/${TOTAL} node(s) are older than current alias${NC}"
    echo -e "  ${YELLOW}Karpenter will replace them as nodes drain or expire${NC}"
fi
echo ""
