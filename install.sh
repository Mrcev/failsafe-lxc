#!/bin/bash
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

printf "${CYAN}=====================================================${NC}\n"
printf "${CYAN}  Failsafe: Dynamic Multi-WAN Failover Installer     ${NC}\n"
printf "${CYAN}  Developed by: Gokberk Ceviker                      ${NC}\n"
printf "${CYAN}=====================================================${NC}\n\n"

# sh veya bash fark etmeksizin calisan root kontrolu
if [ "$(id -u)" -ne 0 ]; then
  printf "${RED}[HATA] Bu kurulum scriptini root olarak calistirmalisiniz (sudo bash ./install.sh)${NC}\n"
  exit 1
fi

printf "${CYAN}[BILGI] Kurulum basliyor...${NC}\n"


printf "${CYAN}[BILGI] /usr/local/bin/net-failover.sh dosyasi olusturuluyor...${NC}\n"

cat << 'EOF' > /usr/local/bin/net-failover.sh
#!/bin/bash

# ==========================================
# DYNAMIC MULTI-WAN FAILOVER SYSTEM
# Developed by: Gokberk Ceviker
# ==========================================

# Parlak (Bold) Renk Kodlari (Loglar Icin)
C_CYAN='\033[1;36m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_NC='\033[0m'

# Test edilecek IP listesi
CHECK_IPS=("1.1.1.1" "8.8.4.4" "1.0.0.1" "9.9.9.9")

declare -a IFACES
declare -A GATEWAYS
declare -A TARGETS

printf "\n${C_CYAN}$(date): [SISTEM] Ag yapilandirmasi taranip gatewayler kesfediliyor...${C_NC}\n\n"

# /etc/network/interfaces dosyasini tara
CURRENT_IFACE=""
while read -r line; do
    if [[ $line == \#* ]]; then continue; fi
    
    if echo "$line" | grep -q "^[[:space:]]*iface"; then
        CURRENT_IFACE=$(echo "$line" | awk '{print $2}')
        if [ "$CURRENT_IFACE" == "lo" ]; then CURRENT_IFACE=""; fi
        
    elif echo "$line" | grep -q "^[[:space:]]*gateway"; then
        if [ -n "$CURRENT_IFACE" ]; then
            GW=$(echo "$line" | awk '{print $2}')
            IFACES+=("$CURRENT_IFACE")
            GATEWAYS["$CURRENT_IFACE"]="$GW"
        fi
    fi
done < /etc/network/interfaces

if [ ${#IFACES[@]} -eq 0 ]; then
    printf "\n${C_RED}$(date): [HATA] Sistemde hicbir gateway bulunamadi! Script durduruluyor.${C_NC}\n\n"
    exit 1
fi

IDX=0
for IFACE in "${IFACES[@]}"; do
    TARGET="${CHECK_IPS[$IDX]}"
    TARGETS["$IFACE"]="$TARGET"
    printf "${C_CYAN}$(date): [KESIF] Arayuz: $IFACE | Gateway: ${GATEWAYS[$IFACE]} | Test IP: $TARGET${C_NC}\n"
    IDX=$((IDX+1))
done

ACTIVE_IFACE=$(ip route show default | awk '/default/ {print $5}' | head -n 1)
if [ -z "$ACTIVE_IFACE" ]; then
    ACTIVE_IFACE="${IFACES[0]}"
fi

printf "\n${C_GREEN}$(date): [BASARILI] Failsafe servisi basladi. Baslangic aktif hat: $ACTIVE_IFACE${C_NC}\n\n"
ALL_DOWN=0

# ==========================================
# KONTROL DONGUSU
# ==========================================
while true; do
    BEST_IFACE=""
    
    for IFACE in "${IFACES[@]}"; do
        TARGET="${TARGETS[$IFACE]}"
        GW="${GATEWAYS[$IFACE]}"
        
        # Rotayi zorla ekle
        ip route replace "$TARGET" via "$GW" dev "$IFACE" onlink 2>/dev/null
        
        # İlgili arayuzden ping testini gerceklestir
        if ping -I "$IFACE" -c 1 -W 2 "$TARGET" > /dev/null 2>&1; then
            BEST_IFACE="$IFACE"
            break
        fi
    done
    
    if [ -n "$BEST_IFACE" ]; then
        ALL_DOWN=0 
        
        if [ "$ACTIVE_IFACE" != "$BEST_IFACE" ]; then
            printf "\n${C_YELLOW}$(date): [DURUM DEGISIKLIGI] Rota guncelleniyor: $ACTIVE_IFACE -> $BEST_IFACE${C_NC}\n\n"
            ip route replace default via "${GATEWAYS[$BEST_IFACE]}" dev "$BEST_IFACE"
            ACTIVE_IFACE="$BEST_IFACE"
        fi
    else
        if [ "$ALL_DOWN" -eq 0 ]; then
            printf "\n${C_RED}$(date): [KRITIK HATA] Hicbir arayuz internete cikamiyor!${C_NC}\n\n"
            ALL_DOWN=1
        fi
    fi
    
    sleep 5
done
EOF

# Calistirma izni ver
chmod +x /usr/local/bin/net-failover.sh
printf "${GREEN}[BILGI] Ana script yetkileri ayarlandi.${NC}\n"

# 2. Systemd Servisini Olustur
printf "${CYAN}[BILGI] failsafe.service dosyasi olusturuluyor...${NC}\n"

cat << 'EOF' > /etc/systemd/system/failsafe.service
[Unit]
Description=Dynamic Network Failover Watchdog
After=network.target

[Service]
ExecStart=/usr/local/bin/net-failover.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 3. Servisi Baslat ve Aktif Et
printf "${CYAN}[BILGI] Systemd servisi aktif ediliyor ve baslatiliyor...${NC}\n"
systemctl daemon-reload
systemctl enable failsafe.service > /dev/null 2>&1
systemctl restart failsafe.service

printf "\n${GREEN}=====================================================${NC}\n"
printf "${GREEN}[BASARILI] Kurulum tamamlandi!${NC}\n"
printf "${CYAN}Gokberk Ceviker tarafindan gelistirilmistir.${NC}\n"
printf "Loglari izlemek icin su komutu kullanabilirsiniz:\n"
printf "${CYAN}journalctl -u failsafe.service -f${NC}\n"
printf "${GREEN}=====================================================${NC}\n"
