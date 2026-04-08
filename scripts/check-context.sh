#!/bin/bash
set -e

echo -e "${BOLD}${BLUE}=== Current Context ===${NC}"
kubectl config current-context
echo ""
echo -e "${BOLD}${BLUE}=== Cluster Info ===${NC}"
kubectl cluster-info | head -1
