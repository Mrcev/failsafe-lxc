#!/bin/bash
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

printf "${CYAN}=====================================================${NC}\n"
printf "${CYAN}  Failsafe: Uninstaller                              ${NC}\n"
printf "${CYAN}  Developed by: Gokberk Ceviker                      ${NC}\n"
printf "${CYAN}=====================================================${NC}\n\n"

# Root yetkisi kontrolu
if [ "$(id -u)" -ne 0 ]; then
  printf "${RED}[HATA] Bu scripti root olarak calistirmalisiniz (sudo bash ./uninstall.sh)${NC}\n"
  exit 1
fi

# 1. Servisi Durdur ve Devre Disi Birak
printf "${YELLOW}[1/4] Failsafe servisi durduruluyor...${NC}\n"
systemctl stop failsafe 2>/dev/null
systemctl disable failsafe 2>/dev/null

# 2. Dosyalari Sil
printf "${YELLOW}[2/4] Sistem dosyalari temizleniyor...${NC}\n"
rm -f /etc/systemd/system/failsafe.service
rm -f /usr/local/bin/net-failover.sh

# 3. Systemd'yi Yenile
printf "${YELLOW}[3/4] Systemd konfigurasyonu guncelleniyor...${NC}\n"
systemctl daemon-reload

# 4. Kalan Test Rotalarini Temizle (Opsiyonel ama temizlik iyidir)
printf "${YELLOW}[4/4] Test rotalari temizleniyor...${NC}\n"
# Scriptteki standart IP'leri temizleyelim
CHECK_IPS=("1.1.1.1" "8.8.4.4" "1.0.0.1" "9.9.9.9")
for IP in "${CHECK_IPS[@]}"; do
    ip route del "$IP" 2>/dev/null
done

printf "\n${GREEN}=====================================================${NC}\n"
printf "${GREEN}[BASARILI] Failsafe sistemden tamamen kaldirildi!${NC}\n"
printf "${CYAN}Gokberk Ceviker tarafindan gelistirilmistir.${NC}\n"
printf "${GREEN}=====================================================${NC}\n"
