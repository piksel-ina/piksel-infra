#!/bin/bash
set -e

ensure_context() {
    local TARGET_CONTEXT=$1
    local CURRENT=$(kubectl config current-context)

    if [ "$CURRENT" != "$TARGET_CONTEXT" ]; then
        echo -e "${BOLD}${YELLOW}Switching from $CURRENT to $TARGET_CONTEXT...${NC}"
        kubectl config use-context "$TARGET_CONTEXT"
        echo ""
    fi

    echo -e "${BOLD}${GREEN}✓ Using context: $TARGET_CONTEXT${NC}"
}
