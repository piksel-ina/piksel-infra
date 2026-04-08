#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/ensure-context.sh"

ENVIRONMENT=$1

if [ "$ENVIRONMENT" = "staging" ]; then
    ensure_context "$STAGING_CONTEXT"
    echo -e "${YELLOW}This will restart all pods. Continue? [y/N]${NC}"
else
    echo -e "${RED}Error: Invalid environment. Use 'staging'${NC}"
    exit 1
fi

read -r ans
if [ "${ans:-N}" != "y" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${BOLD}${BLUE}=== Restarting Deployments ===${NC}"

for ns in $(kubectl get deployments -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}' | sort -u); do
    echo -e "${CYAN}Namespace: ${ns}${NC}"
    kubectl rollout restart deployment -n "$ns"
    echo "Waiting for rollouts in $ns..."
    kubectl rollout status deployment -n "$ns" --timeout=10m
    echo -e "${GREEN}✓ Namespace $ns complete${NC}"
    echo ""
done

echo -e "${GREEN}✓ All deployments restarted${NC}"
