#!/bin/bash

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="/work/reports"
APP_DIR="/work/app"
IMAGE_NAME="zafiyetli-app:v1"

mkdir -p "$REPORT_DIR"

echo -e "${YELLOW}[1/4] Docker Imajı Derleniyor: ${IMAGE_NAME}...${NC}"
docker build -t "$IMAGE_NAME" "$APP_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}[HATA] Docker derleme basarisiz oldu!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}[2/4] Yanlis Yapilandirma (Misconfig) Taramasi Yapiliyor...${NC}"
trivy config "$APP_DIR" | tee "$REPORT_DIR/misconfig_${TIMESTAMP}.txt"

echo -e "\n${YELLOW}[3/4] Gizli Anahtar (Secret) Taramasi Yapiliyor...${NC}"
trivy fs --scanners secret "$APP_DIR" | tee "$REPORT_DIR/secret_${TIMESTAMP}.txt"

echo -e "\n${YELLOW}[4/4] Konteyner Imaj Zafiyet Taramasi (Quality Gate) Calistiriliyor...${NC}"
# JSON raporu da saklayalım
trivy image -f json -o "$REPORT_DIR/image_${TIMESTAMP}.json" "$IMAGE_NAME"

# Pipeline kırma testi: CRITICAL veya HIGH varsa exit-code 1 doner
trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 "$IMAGE_NAME"
EXIT_CODE=$?

echo -e "\n--------------------------------------------------"
if [ $EXIT_CODE -ne 0 ]; then
    echo -e "${RED}[GÜVENLİK BARİYERİNE TAKILDI] Projede kritik/yüksek seviyeli açıklar tespit edildi!${NC}"
    echo -e "${RED}Pipeline durduruldu. Canlıya çıkış engellendi (Exit Code: $EXIT_CODE).${NC}"
    exit 1
else
    echo -e "${GREEN}[BAŞARILI] Güvenlik taraması temiz geçti. Canlıya çıkış onaylandı!${NC}"
    exit 0
fi
