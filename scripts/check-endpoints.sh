#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/ensure-context.sh"

ENVIRONMENT=$1
TIMEOUT=10

if [ "$ENVIRONMENT" = "staging" ]; then
    ensure_context "$STAGING_CONTEXT"
else
    echo -e "${RED}Error: Invalid environment. Use 'staging'${NC}"
    exit 1
fi

echo ""
echo -e "${BOLD}${BLUE}=== Endpoint Connectivity Tests (STAGING) ===${NC}"
echo -e "${YELLOW}Parallel mode — ${TIMEOUT}s timeout per endpoint${NC}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

probe() {
    local url="$1" idx="$2" kind="$3"
    local resp code time try_url

    for try_url in "$url" "${url/#https:/http:}"; do
        resp=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" --max-time "$TIMEOUT" "$try_url" 2>/dev/null) && break
    done

    code="${resp%%|*}"
    time="${resp##*|}"

    [[ -z "$code" || ! "$code" =~ ^[0-9]+$ ]] && { echo "FAIL||" > "$TMPDIR/$idx"; return; }

    local ok=false
    case "$kind" in
        nginx) [[ "$code" == "404" ]] || [[ "$code" -ge 200 && "$code" -lt 400 ]] && ok=true ;;
        auth)  [[ "$code" -ge 200 && "$code" -lt 300 ]] || [[ "$code" == "302" || "$code" == "401" || "$code" == "403" ]] && ok=true ;;
        *)     [[ "$code" -ge 200 && "$code" -lt 400 ]] && ok=true ;;
    esac

    if $ok; then
        echo "OK|$code|$time" > "$TMPDIR/$idx"
    else
        echo "WARN|$code|$time" > "$TMPDIR/$idx"
    fi
}

declare -a URLS NAMES KINDS SECTIONS

while IFS='|' read -r name endpoint port; do
    [[ -z "$endpoint" || "$endpoint" == "null" ]] && continue
    kind="general"
    [[ "$name" == *"nginx"* ]] && kind="nginx"
    URLS+=("https://${endpoint}")
    NAMES+=("$name")
    KINDS+=("$kind")
    SECTIONS+=("LB")
done < <(kubectl get svc -A --field-selector spec.type=LoadBalancer -o json \
    | jq -r '.items[] | select(.status.loadBalancer.ingress) | "\(.metadata.namespace)/\(.metadata.name)|\(.status.loadBalancer.ingress[0].hostname // .status.loadBalancer.ingress[0].ip)|\(.spec.ports[0].port)"')

while IFS='|' read -r name host; do
    [[ -z "$host" || "$host" == "null" ]] && continue
    kind="general"
    [[ "$host" == *"grafana"* || "$host" == *"argo"* ]] && kind="auth"
    URLS+=("https://${host}")
    NAMES+=("$name ($host)")
    KINDS+=("$kind")
    SECTIONS+=("ING")
done < <(kubectl get ingress -A -o json \
    | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)|\(.spec.rules[]?.host)"')

total=${#URLS[@]}
if [ "$total" -eq 0 ]; then
    echo -e "${YELLOW}  No endpoints found${NC}"
    exit 0
fi

echo -e "${CYAN}  Probing $total endpoints...${NC}"
echo ""

for i in "${!URLS[@]}"; do
    probe "${URLS[$i]}" "$i" "${KINDS[$i]}" &
done
wait

lb_ok=0 lb_total=0 ing_ok=0 ing_total=0

display_result() {
    local idx="$1"
    local result status code time icon detail
    result=$(cat "$TMPDIR/$idx")
    status="${result%%|*}"; detail="${result#*|}"
    code="${detail%%|*}"; time="${detail#*|}"

    case "$status" in
        OK)   icon="${GREEN}✓${NC}" ;;
        WARN) icon="${YELLOW}⚠${NC}" ;;
        *)    icon="${RED}✗${NC}" ;;
    esac

    if [[ "$status" == "FAIL" ]]; then
        echo -e "  $icon $(printf '%-55s' "${NAMES[$idx]}") ${RED}Connection failed${NC}"
    else
        echo -e "  $icon $(printf '%-55s' "${NAMES[$idx]}") HTTP $code ($(printf '%.2f' "$time")s)"
    fi
}

echo -e "${BOLD}${CYAN}LoadBalancer Services:${NC}"
for i in "${!URLS[@]}"; do
    [[ "${SECTIONS[$i]}" != "LB" ]] && continue
    lb_total=$((lb_total + 1))
    grep -q "^OK" "$TMPDIR/$i" && lb_ok=$((lb_ok + 1))
    display_result "$i"
done
[ "$lb_total" -eq 0 ] && echo -e "${YELLOW}  No LoadBalancer services with external endpoints found${NC}"

echo ""
echo -e "${BOLD}${CYAN}Ingress Endpoints:${NC}"
for i in "${!URLS[@]}"; do
    [[ "${SECTIONS[$i]}" != "ING" ]] && continue
    ing_total=$((ing_total + 1))
    grep -q "^OK" "$TMPDIR/$i" && ing_ok=$((ing_ok + 1))
    display_result "$i"
done
[ "$ing_total" -eq 0 ] && echo -e "${YELLOW}  No Ingress endpoints found${NC}"

echo ""
echo -e "${BOLD}${CYAN}=== Summary ===${NC}"
echo -e "  LoadBalancers: ${GREEN}${lb_ok}${NC}/${BLUE}${lb_total}${NC} accessible"
echo -e "  Ingress:       ${GREEN}${ing_ok}${NC}/${BLUE}${ing_total}${NC} accessible"
echo ""
echo -e "${YELLOW}HTTP errors don't always mean service failure. Verify failed endpoints in a browser.${NC}"
