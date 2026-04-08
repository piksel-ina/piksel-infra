#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/ensure-context.sh"

ENVIRONMENT=$1

if [ "$ENVIRONMENT" = "staging" ]; then
    ensure_context "$STAGING_CONTEXT"
else
    echo -e "${RED}Error: Invalid environment. Use 'staging'${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}${BLUE}=== Cluster Health ===${NC}"
echo -n "Health: "

HEALTH=$(kubectl get --raw /healthz)
if [ "$HEALTH" = "ok" ]; then
    echo -e "${GREEN}${HEALTH}${NC}"
else
    echo -e "${RED}${HEALTH}${NC}"
fi

echo ""
echo -e "${BOLD}${BLUE}=== Pod Status ===${NC}"

TOTAL=$(kubectl get pods -A --no-headers | wc -l)
RUNNING=$(kubectl get pods -A --no-headers | grep -c Running || echo 0)

echo "Total pods: $TOTAL"
echo -e "${GREEN}Running: $RUNNING${NC}"
echo ""

FAILED=$(kubectl get pods -A | grep -v Running | grep -v Completed | grep -v NAMESPACE | wc -l)

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All pods healthy${NC}"
else
    echo -e "${RED}✗ Non-running pods: $FAILED${NC}"
    echo ""
    kubectl get pods -A | grep -v Running | grep -v Completed
fi
