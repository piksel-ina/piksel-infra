#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/ensure-context.sh"

ENV=$1

if [ "$ENV" != "staging" ]; then
    echo -e "${RED}Error: Use 'staging'${NC}"
    exit 1
fi

ensure_context "$STAGING_CONTEXT"

echo ""
echo -e "${BOLD}${CYAN}=== Deprecated API Scan (Staging) ===${NC}"
echo -e "  Context: $STAGING_CONTEXT"
echo -e "  Target k8s: v${EKS_VERSION}"
echo ""

output=$(pluto detect-all-in-cluster \
    --target-versions "k8s=v${EKS_VERSION}" \
    --kube-context "$STAGING_CONTEXT" \
    --output wide \
    --no-footer 2>/dev/null) || true

if [ -z "$output" ]; then
    echo -e "  ${GREEN}✓ Pluto not installed or no output${NC}"
    echo -e "  ${YELLOW}Install: https://pluto.docs.fairwinds.com${NC}"
    exit 0
fi

if echo "$output" | grep -q "no resources found"; then
    echo -e "  ${GREEN}✓ No deprecated or removed APIs found — cluster is clean${NC}"
    echo ""
    exit 0
fi

echo "$output"
echo ""

deprecated=$(echo "$output" | tail -n +2 | grep -ci 'deprecated' || true)
removed=$(echo "$output" | tail -n +2 | grep -ci 'removed' || true)

if [ "$deprecated" -gt 0 ] || [ "$removed" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ Found: ${deprecated} deprecated, ${removed} removed APIs${NC}"
    echo -e "  ${YELLOW}Review the items above before upgrading k8s.${NC}"
else
    echo -e "  ${GREEN}✓ No deprecated or removed APIs found${NC}"
fi
