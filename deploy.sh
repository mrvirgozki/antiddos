#!/bin/bash

set -e

# ==============================================================================
# VIRGOZKI CLOUD RUN DEPLOYER
# WS + HTTPUPGRADE + XHTTP + gRPC
# MANUAL REGION SELECTION
# ==============================================================================

BOLD='\033[1m'
RESET='\033[0m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'

# ==============================================================================
# REGIONS
# ==============================================================================

ALL_REGIONS=(
  "01:asia-east1:Taiwan"
  "02:asia-east2:Hong Kong"
  "03:asia-northeast1:Japan (Tokyo)"
  "04:asia-northeast2:Japan (Osaka)"
  "05:asia-northeast3:South Korea (Seoul)"
  "06:asia-south1:India (Mumbai)"
  "07:asia-south2:India (Delhi)"
  "08:asia-southeast1:Singapore"
  "09:asia-southeast2:Indonesia (Jakarta)"
  "10:australia-southeast1:Australia (Sydney)"
  "11:australia-southeast2:Australia (Melbourne)"
  "12:europe-central2:Poland (Warsaw)"
  "13:europe-north1:Finland"
  "14:europe-southwest1:Spain (Madrid)"
  "15:europe-west1:Belgium"
  "16:europe-west2:United Kingdom (London)"
  "17:europe-west3:Germany (Frankfurt)"
  "18:europe-west4:Netherlands"
  "19:europe-west6:Switzerland (Zurich)"
  "20:europe-west8:Italy (Milan)"
  "21:europe-west9:France (Paris)"
  "22:northamerica-northeast1:Canada (Montreal)"
  "23:northamerica-northeast2:Canada (Toronto)"
  "24:southamerica-east1:Brazil (Sao Paulo)"
  "25:southamerica-west1:Chile (Santiago)"
  "26:us-central1:USA (Iowa)"
  "27:us-east1:USA (South Carolina)"
  "28:us-east4:USA (North Virginia)"
  "29:us-east5:USA (Columbus)"
  "30:us-south1:USA (Texas)"
  "31:us-west1:USA (Oregon)"
  "32:us-west2:USA (Los Angeles)"
  "33:us-west3:USA (Salt Lake City)"
  "34:us-west4:USA (Las Vegas)"
)

# ==============================================================================
# LOADING
# ==============================================================================

loading() {
    local t="$1"

    echo -ne "  ${CYAN}${t}...${RESET}"

    sleep 0.5

    echo -e "\r  ${GREEN}DONE: ${t}${RESET}"
}

# ==============================================================================
# HEADER
# ==============================================================================

clear

echo ""
echo -e "  ${BOLD}${WHITE}VIRGOZKI CLOUD RUN DEPLOYER${RESET}"
echo -e "  ${MAGENTA}WS + HTTPUPGRADE + XHTTP + gRPC${RESET}"
echo ""

# ==============================================================================
# CHECK GCLOUD
# ==============================================================================

if ! command -v gcloud >/dev/null 2>&1; then
    echo -e "  ${RED}ERROR: gcloud command not found.${RESET}"
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
    echo -e "  ${RED}ERROR: No active GCP project detected.${RESET}"
    echo -e "  ${YELLOW}Run: gcloud init${RESET}"
    exit 1
fi

echo -e "  ${CYAN}PROJECT:${RESET} ${GREEN}${PROJECT_ID}${RESET}"
echo ""

# ==============================================================================
# REGION
# ==============================================================================

REGION="asia-southeast1"

echo -e "  ${CYAN}📍 DEFAULT REGION:${RESET} ${GREEN}${REGION}${RESET}"
echo ""

echo -e "  ${CYAN}📋 PUMILI NG REGION (0 = DEFAULT):${RESET}"
echo ""
echo -e "  ${YELLOW}0) ${GREEN}${REGION}${RESET} ${CYAN}(Default)${RESET}"
echo ""

for i in "${!ALL_REGIONS[@]}"; do
    IFS=':' read -r num reg_name country <<< "${ALL_REGIONS[$i]}"

    printf "  ${YELLOW}%s) ${GREEN}%-25s${RESET} ${CYAN}(%s)${RESET}\n" \
        "$num" "$reg_name" "$country"
done

echo ""

read -r -p "$(echo -e "  ${CYAN}ILAGAY ANG NUMBER: ${RESET}")" REG_CHOICE

if [[ "$REG_CHOICE" =~ ^[0-9]+$ ]]; then

    if [ "$REG_CHOICE" != "0" ]; then

        FOUND=0

        for item in "${ALL_REGIONS[@]}"; do

            IFS=':' read -r num reg_name country <<< "$item"

            if [ "$num" = "$REG_CHOICE" ]; then
                REGION="$reg_name"
                FOUND=1
                break
            fi

        done

        if [ "$FOUND" -eq 0 ]; then
            echo -e "  ${YELLOW}⚠️ INVALID NUMBER — USING DEFAULT${RESET}"
            REGION="asia-southeast1"
        fi

    fi
fi

gcloud config set run/region "$REGION" --quiet >/dev/null 2>&1 || true
gcloud config set compute/region "$REGION" --quiet >/dev/null 2>&1 || true

echo ""
echo -e "  ${CYAN}✅ FINAL REGION:${RESET} ${GREEN}${REGION}${RESET}"
echo ""

# ==============================================================================
# SERVICE NAME
# ==============================================================================

read -r -p "$(echo -e "  ${CYAN}SERVICE NAME [mrvirgo]: ${RESET}")" INPUT_NAME

INPUT_NAME=$(echo "$INPUT_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cd 'a-z0-9-')

SERVICE_NAME="${INPUT_NAME:-mrvirgo}"

echo ""
echo -e "  ${CYAN}SERVICE:${RESET} ${GREEN}${SERVICE_NAME}${RESET}"
echo ""

# ==============================================================================
# MODE
# ==============================================================================

echo -e "  ${CYAN}SELECT MODE:${RESET}"
echo ""
echo -e "  ${YELLOW}1) AUTO     — 1 vCPU / 2Gi RAM${RESET}"
echo -e "  ${YELLOW}2) HIGH     — 2 vCPU / 4Gi RAM${RESET}"
echo -e "  ${YELLOW}3) STABLE   — 4 vCPU / 8Gi RAM${RESET}"
echo -e "  ${YELLOW}4) CUSTOM   — sariling settings${RESET}"
echo ""

read -r -p "$(echo -e "  ${CYAN}CHOICE: ${RESET}")" MODE_CHOICE

case "$MODE_CHOICE" in

    1)
        CPU="1"
        RAM="2Gi"
        MODE="AUTO"
        MAX_INSTANCES="2"
        ;;

    2)
        CPU="2"
        RAM="4Gi"
        MODE="HIGH"
        MAX_INSTANCES="2"
        ;;

    3)
        CPU="4"
        RAM="8Gi"
        MODE="STABLE"
        MAX_INSTANCES="1"
        ;;

    4)
        echo ""

        read -r -p "$(echo -e "  ${CYAN}CPU (1/2/4): ${RESET}")" CPU
        read -r -p "$(echo -e "  ${CYAN}RAM (2Gi/4Gi/8Gi): ${RESET}")" RAM
        read -r -p "$(echo -e "  ${CYAN}MAX INSTANCES (1-3): ${RESET}")" MAX_INSTANCES

        MODE="CUSTOM"
        ;;

    *)
        CPU="1"
        RAM="2Gi"
        MODE="AUTO"
        MAX_INSTANCES="2"
        ;;
esac

echo ""
echo -e "  ${CYAN}MODE:${RESET} ${GREEN}${MODE}${RESET}"
echo -e "  ${CYAN}CPU:${RESET} ${GREEN}${CPU}${RESET}"
echo -e "  ${CYAN}RAM:${RESET} ${GREEN}${RAM}${RESET}"
echo -e "  ${CYAN}MAX INSTANCES:${RESET} ${GREEN}${MAX_INSTANCES}${RESET}"
echo ""

# ==============================================================================
# CHECK FILES
# ==============================================================================

loading "CHECKING REQUIRED FILES"

REQUIRED_FILES=(
    "config.json"
    "nginx.conf"
    "Dockerfile"
    "entrypoint.sh"
    "index.html"
)

for f in "${REQUIRED_FILES[@]}"; do

    if [ ! -f "$f" ]; then
        echo ""
        echo -e "  ${RED}❌ ERROR: Missing file -> $f${RESET}"
        exit 1
    fi

done

echo ""

# ==============================================================================
# CHECK JSON
# ==============================================================================

loading "CHECKING CONFIG.JSON"

if command -v python3 >/dev/null 2>&1; then

    if ! python3 -m json.tool config.json >/dev/null 2>&1; then
        echo ""
        echo -e "  ${RED}❌ ERROR: config.json contains invalid JSON.${RESET}"
        exit 1
    fi

else

    echo -e "  ${YELLOW}⚠️ python3 not found — skipping JSON syntax check.${RESET}"

fi

echo ""

# ==============================================================================
# BUILD
# ==============================================================================

loading "BUILDING CONTAINER IMAGE"

IMAGE="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

if ! gcloud builds submit \
    --tag "$IMAGE" \
    --project="$PROJECT_ID" \
    --quiet > build.log 2>&1; then

    echo ""
    echo -e "  ${RED}❌ BUILD FAILED${RESET}"
    echo ""
    tail -n 30 build.log

    rm -f build.log

    exit 1
fi

echo ""

# ==============================================================================
# DEPLOY
# ==============================================================================

loading "DEPLOYING TO CLOUD RUN"

if ! gcloud run deploy "$SERVICE_NAME" \
    --image "$IMAGE" \
    --platform managed \
    --region "$REGION" \
    --cpu "$CPU" \
    --memory "$RAM" \
    --port 8080 \
    --concurrency 800 \
    --timeout 3600 \
    --min-instances 0 \
    --max-instances "$MAX_INSTANCES" \
    --allow-unauthenticated \
    --project="$PROJECT_ID" \
    --quiet > deploy.log 2>&1; then

    echo ""
    echo -e "  ${RED}❌ DEPLOYMENT FAILED${RESET}"
    echo ""
    tail -n 30 deploy.log

    rm -f build.log deploy.log

    exit 1
fi

echo ""

# ==============================================================================
# GET SERVICE URL
# ==============================================================================

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
    --region "$REGION" \
    --project="$PROJECT_ID" \
    --format='value(status.url)' 2>/dev/null)

if [ -z "$SERVICE_URL" ]; then

    echo -e "  ${RED}❌ Unable to get Cloud Run service URL.${RESET}"

    rm -f build.log deploy.log

    exit 1
fi

CLEAN_HOST="${SERVICE_URL#https://}"

# ==============================================================================
# CREDENTIALS
# ==============================================================================

VMESS_UUID="b831381d-6324-4d53-ad4f-8cda48b30811"

SS_B64=$(printf '%s' 'aes-256-gcm:virgozki' | base64 | tr -d '\n')

# ==============================================================================
# VLESS
# ==============================================================================

VLESS_WS="vless://${VMESS_UUID}@${CLEAN_HOST}:443?encryption=none&type=ws&path=/vless-virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#VLESS-WS"

VLESS_HU="vless://${VMESS_UUID}@${CLEAN_HOST}:443?encryption=none&type=httpupgrade&path=/vless-virgozki-hu&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#VLESS-HU"

VLESS_XHTTP="vless://${VMESS_UUID}@${CLEAN_HOST}:443?encryption=none&type=xhttp&path=/vless-virgozki-xhttp&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}&mode=packet-upstream#VLESS-XHTTP"

VLESS_GRPC="vless://${VMESS_UUID}@${CLEAN_HOST}:443?encryption=none&type=grpc&serviceName=vless-grpc-virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#VLESS-gRPC"

# ==============================================================================
# VMESS
# ==============================================================================

VMESS_WS_JSON='{"v":"2","ps":"VMESS-WS-virgozki","add":"'"${CLEAN_HOST}"'","port":"443","id":"'"${VMESS_UUID}"'","aid":"0","scy":"auto","net":"ws","type":"none","host":"'"${CLEAN_HOST}"'","path":"/vmess-virgozki","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"http/1.1"}'

VMESS_HU_JSON='{"v":"2","ps":"VMESS-HU-virgozki","add":"'"${CLEAN_HOST}"'","port":"443","id":"'"${VMESS_UUID}"'","aid":"0","scy":"auto","net":"httpupgrade","type":"none","host":"'"${CLEAN_HOST}"'","path":"/vmess-virgozki-hu","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"http/1.1"}'

VMESS_XHTTP_JSON='{"v":"2","ps":"VMESS-XHTTP-virgozki","add":"'"${CLEAN_HOST}"'","port":"443","id":"'"${VMESS_UUID}"'","aid":"0","scy":"auto","net":"xhttp","type":"none","host":"'"${CLEAN_HOST}"'","path":"/vmess-virgozki-xhttp","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"http/1.1","xhttpMode":"packet-upstream"}'

VMESS_GRPC_JSON='{"v":"2","ps":"VMESS-gRPC-virgozki","add":"'"${CLEAN_HOST}"'","port":"443","id":"'"${VMESS_UUID}"'","aid":"0","scy":"auto","net":"grpc","type":"none","host":"'"${CLEAN_HOST}"'","serviceName":"vmess-grpc-virgozki","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"h2"}'

VMESS_WS_B64=$(printf '%s' "$VMESS_WS_JSON" | base64 | tr -d '\n')
VMESS_HU_B64=$(printf '%s' "$VMESS_HU_JSON" | base64 | tr -d '\n')
VMESS_XHTTP_B64=$(printf '%s' "$VMESS_XHTTP_JSON" | base64 | tr -d '\n')
VMESS_GRPC_B64=$(printf '%s' "$VMESS_GRPC_JSON" | base64 | tr -d '\n')

# ==============================================================================
# TROJAN
# ==============================================================================

TROJAN_WS="trojan://virgozki@${CLEAN_HOST}:443?type=ws&path=/virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#TROJAN-WS"

TROJAN_HU="trojan://virgozki@${CLEAN_HOST}:443?type=httpupgrade&path=/virgozki-hu&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#TROJAN-HU"

TROJAN_XHTTP="trojan://virgozki@${CLEAN_HOST}:443?type=xhttp&path=/virgozki-xhttp&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}&mode=packet-upstream#TROJAN-XHTTP"

TROJAN_GRPC="trojan://virgozki@${CLEAN_HOST}:443?type=grpc&serviceName=trojan-grpc-virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#TROJAN-gRPC"

# ==============================================================================
# SHADOWSOCKS
# ==============================================================================

SS_WS="ss://${SS_B64}@${CLEAN_HOST}:443?type=ws&path=/ss-virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#SHADOWSOCKS-WS"

SS_HU="ss://${SS_B64}@${CLEAN_HOST}:443?type=httpupgrade&path=/ss-virgozki-hu&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#SHADOWSOCKS-HU"

SS_XHTTP="ss://${SS_B64}@${CLEAN_HOST}:443?type=xhttp&path=/ss-virgozki-xhttp&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}&mode=packet-upstream#SHADOWSOCKS-XHTTP"

SS_GRPC="ss://${SS_B64}@${CLEAN_HOST}:443?type=grpc&serviceName=ss-grpc-virgozki&host=${CLEAN_HOST}&security=tls&sni=${CLEAN_HOST}#SHADOWSOCKS-gRPC"

# ==============================================================================
# RESULT
# ==============================================================================

echo ""
echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${GREEN}✅ DEPLOYED SUCCESSFULLY${RESET}"
echo -e "  ${CYAN}REGION:${RESET} ${GREEN}${REGION}${RESET}"
echo -e "  ${CYAN}SERVICE:${RESET} ${GREEN}${SERVICE_NAME}${RESET}"
echo -e "  ${CYAN}MODE:${RESET} ${GREEN}${MODE} (${CPU} vCPU / ${RAM})${RESET}"
echo -e "  ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

echo -e "  ${CYAN}DASHBOARD:${RESET} ${GREEN}${SERVICE_URL}${RESET}"
echo -e "  ${CYAN}HOST:${RESET}      ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}PORT:${RESET}      ${GREEN}443${RESET}"
echo ""

echo -e "  ${YELLOW}ALL PROTOCOLS${RESET}"
echo ""

echo -e "  ${GREEN}✓ VLESS${RESET}"
echo -e "    WS:     /vless-virgozki"
echo -e "    HU:     /vless-virgozki-hu"
echo -e "    XHTTP:  /vless-virgozki-xhttp"
echo -e "    gRPC:   vless-grpc-virgozki"
echo ""

echo -e "  ${GREEN}✓ VMESS${RESET}"
echo -e "    WS:     /vmess-virgozki"
echo -e "    HU:     /vmess-virgozki-hu"
echo -e "    XHTTP:  /vmess-virgozki-xhttp"
echo -e "    gRPC:   vmess-grpc-virgozki"
echo ""

echo -e "  ${GREEN}✓ TROJAN${RESET}"
echo -e "    WS:     /virgozki"
echo -e "    HU:     /virgozki-hu"
echo -e "    XHTTP:  /virgozki-xhttp"
echo -e "    gRPC:   trojan-grpc-virgozki"
echo ""

echo -e "  ${GREEN}✓ SHADOWSOCKS${RESET}"
echo -e "    WS:     /ss-virgozki"
echo -e "    HU:     /ss-virgozki-hu"
echo -e "    XHTTP:  /ss-virgozki-xhttp"
echo -e "    gRPC:   ss-grpc-virgozki"
echo ""

echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${YELLOW}READY-TO-USE LINKS${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

echo -e "  ${CYAN}VLESS WS:${RESET}     ${GREEN}${VLESS_WS}${RESET}"
echo -e "  ${CYAN}VLESS HU:${RESET}     ${GREEN}${VLESS_HU}${RESET}"
echo -e "  ${CYAN}VLESS XHTTP:${RESET}  ${GREEN}${VLESS_XHTTP}${RESET}"
echo -e "  ${CYAN}VLESS gRPC:${RESET}   ${GREEN}${VLESS_GRPC}${RESET}"
echo ""

echo -e "  ${CYAN}VMESS WS:${RESET}     ${GREEN}vmess://${VMESS_WS_B64}${RESET}"
echo -e "  ${CYAN}VMESS HU:${RESET}     ${GREEN}vmess://${VMESS_HU_B64}${RESET}"
echo -e "  ${CYAN}VMESS XHTTP:${RESET}  ${GREEN}vmess://${VMESS_XHTTP_B64}${RESET}"
echo -e "  ${CYAN}VMESS gRPC:${RESET}   ${GREEN}vmess://${VMESS_GRPC_B64}${RESET}"
echo ""

echo -e "  ${CYAN}TROJAN WS:${RESET}    ${GREEN}${TROJAN_WS}${RESET}"
echo -e "  ${CYAN}TROJAN HU:${RESET}    ${GREEN}${TROJAN_HU}${RESET}"
echo -e "  ${CYAN}TROJAN XHTTP:${RESET} ${GREEN}${TROJAN_XHTTP}${RESET}"
echo -e "  ${CYAN}TROJAN gRPC:${RESET}  ${GREEN}${TROJAN_GRPC}${RESET}"
echo ""

echo -e "  ${CYAN}SS WS:${RESET}         ${GREEN}${SS_WS}${RESET}"
echo -e "  ${CYAN}SS HU:${RESET}         ${GREEN}${SS_HU}${RESET}"
echo -e "  ${CYAN}SS XHTTP:${RESET}      ${GREEN}${SS_XHTTP}${RESET}"
echo -e "  ${CYAN}SS gRPC:${RESET}       ${GREEN}${SS_GRPC}${RESET}"
echo ""

# ==============================================================================
# CLEANUP
# ==============================================================================

rm -f build.log deploy.log

echo -e "  ${GREEN}✅ SCRIPT FINISHED${RESET}"
echo ""
