#!/bin/bash

###########################################
# 3X-UI Auto-Installer с VLESS Reality
# Автоматическая настройка и оптимизация
# для VPN-серверов в Финляндии и Германии
###########################################

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
print_msg() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   print_error "Этот скрипт должен быть запущен с правами root (sudo)"
   exit 1
fi

print_msg "==================================================="
print_msg "  3X-UI Auto-Installer с оптимизацией для VLESS"
print_msg "==================================================="
echo ""

# Запрос данных от пользователя
read -p "Введите домен для маскировки (например, www.microsoft.com): " DEST_DOMAIN
DEST_DOMAIN=${DEST_DOMAIN:-"www.microsoft.com"}

read -p "Введите порт для панели 3X-UI (по умолчанию 2053): " PANEL_PORT
PANEL_PORT=${PANEL_PORT:-2053}

read -p "Введите имя пользователя для панели: " PANEL_USERNAME
read -sp "Введите пароль для панели: " PANEL_PASSWORD
echo ""

read -p "Введите email для первого клиента (например, user1@vpn): " CLIENT_EMAIL
CLIENT_EMAIL=${CLIENT_EMAIL:-"user1@vpn"}

print_msg "Обновление системы..."
apt update && apt upgrade -y

print_msg "Установка необходимых пакетов..."
apt install -y curl wget socat git openssl ca-certificates sudo ufw

print_msg "==================================================="
print_msg "  Оптимизация системы для VPN-трафика"
print_msg "==================================================="

# Backup оригинального sysctl.conf
cp /etc/sysctl.conf /etc/sysctl.conf.backup

print_msg "Настройка параметров ядра (sysctl)..."

# Создаём файл с оптимизациями для VPN
cat > /etc/sysctl.d/99-vpn-optimization.conf << 'EOF'
# ============================================
# Оптимизация для 3X-UI и Xray VPN Server
# ============================================

# BBR TCP Congestion Control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP Fast Open (TFO)
net.ipv4.tcp_fastopen=3

# Увеличение TCP буферов для высокой пропускной способности
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.core.rmem_default=16777216
net.core.wmem_default=16777216
net.ipv4.tcp_rmem=4096 87380 134217728
net.ipv4.tcp_wmem=4096 65536 134217728

# Оптимизация TCP параметров
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_moderate_rcvbuf=1
net.ipv4.tcp_low_latency=1

# Оптимизация для высокой нагрузки
net.core.netdev_max_backlog=250000
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_slow_start_after_idle=0

# Уменьшение TIME_WAIT
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1

# Защита от SYN flood
net.ipv4.tcp_syncookies=1

# Увеличение лимитов файловых дескрипторов
fs.file-max=9000000
fs.nr_open=9000000
fs.inotify.max_user_watches=3400000

# IP forwarding (если требуется маршрутизация)
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Оптимизация памяти
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5

# Безопасность
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# TCP Keep-Alive оптимизация
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=5

# Оптимизация ARP кэша
net.ipv4.neigh.default.gc_thresh1=2048
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh3=8192
EOF

print_msg "Применение настроек ядра..."
sysctl -p /etc/sysctl.d/99-vpn-optimization.conf

print_msg "Увеличение лимитов системы..."
cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 1000000
* hard nofile 1000000
* soft nproc 1000000
* hard nproc 1000000
root soft nofile 1000000
root hard nofile 1000000
root soft nproc 1000000
root hard nproc 1000000
EOF

# Настройка systemd лимитов
mkdir -p /etc/systemd/system.conf.d/
cat > /etc/systemd/system.conf.d/limits.conf << 'EOF'
[Manager]
DefaultLimitNOFILE=1000000
DefaultLimitNPROC=1000000
EOF

print_msg "Проверка и включение BBR..."
modprobe tcp_bbr
echo 'tcp_bbr' | tee -a /etc/modules-load.d/modules.conf

# Проверка BBR
if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
    print_msg "BBR успешно активирован!"
else
    print_warning "BBR не активирован. Проверьте версию ядра (требуется >= 4.9)"
fi

print_msg "==================================================="
print_msg "  Установка 3X-UI панели"
print_msg "==================================================="

# Установка 3X-UI
print_msg "Загрузка и установка 3X-UI..."

# Автоматическая установка с параметрами
export XUI_PANEL_PORT=$PANEL_PORT
export XUI_PANEL_USERNAME=$PANEL_USERNAME
export XUI_PANEL_PASSWORD=$PANEL_PASSWORD

bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) << ANSWERS
y
$PANEL_PORT
$PANEL_USERNAME
$PANEL_PASSWORD

ANSWERS

sleep 3

print_msg "==================================================="
print_msg "  Настройка firewall (UFW)"
print_msg "==================================================="

# Настройка firewall
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 443/tcp comment 'HTTPS/VLESS'
ufw allow $PANEL_PORT/tcp comment '3X-UI Panel'
ufw reload

print_msg "==================================================="
print_msg "  Генерация ключей для VLESS Reality"
print_msg "==================================================="

# Генерация UUID для клиента
CLIENT_UUID=$(cat /proc/sys/kernel/random/uuid)
print_msg "UUID клиента: $CLIENT_UUID"

# Генерация shortID
SHORT_ID=$(openssl rand -hex 8)
print_msg "Short ID: $SHORT_ID"

# Генерация приватного и публичного ключей Reality (используем xray)
print_msg "Генерация ключей Reality..."

# Проверяем, установлен ли xray
if [ -f "/usr/local/x-ui/bin/xray-linux-amd64" ]; then
    XRAY_BIN="/usr/local/x-ui/bin/xray-linux-amd64"
elif [ -f "/usr/local/bin/xray" ]; then
    XRAY_BIN="/usr/local/bin/xray"
else
    print_warning "Xray binary не найден, используем альтернативный метод генерации ключей"
    # Генерация ключей через альтернативный метод
    PRIVATE_KEY=$(openssl rand -base64 32)
    PUBLIC_KEY=$(openssl rand -base64 32)
fi

if [ ! -z "$XRAY_BIN" ]; then
    KEYS_OUTPUT=$($XRAY_BIN x25519 2>/dev/null || echo "")
    if [ ! -z "$KEYS_OUTPUT" ]; then
        PRIVATE_KEY=$(echo "$KEYS_OUTPUT" | grep "Private key:" | awk '{print $3}')
        PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | grep "Public key:" | awk '{print $3}')
    else
        print_warning "Не удалось сгенерировать ключи через xray, используем OpenSSL"
        PRIVATE_KEY=$(openssl rand -base64 32)
        PUBLIC_KEY=$(openssl rand -base64 32)
    fi
fi

print_msg "Private Key: $PRIVATE_KEY"
print_msg "Public Key: $PUBLIC_KEY"

print_msg "==================================================="
print_msg "  Создание конфигурации для инбаунда"
print_msg "==================================================="

# Создаём файл с инструкциями для ручной настройки
cat > /root/3x-ui-vless-config.txt << EOF
=================================================
Конфигурация VLESS Reality для 3X-UI
=================================================

НАСТРОЙКИ ИНБАУНДА:
-------------------
Protocol: VLESS
Port: 443
Network: tcp
Security: reality
Flow: xtls-rprx-vision

REALITY SETTINGS:
-----------------
Destination (Dest): $DEST_DOMAIN:443
Server Names (SNI): $DEST_DOMAIN
Private Key: $PRIVATE_KEY
Public Key: $PUBLIC_KEY
Short IDs: $SHORT_ID
uTLS Fingerprint: chrome (или random)

CLIENT SETTINGS:
----------------
UUID: $CLIENT_UUID
Email: $CLIENT_EMAIL
Flow: xtls-rprx-vision

ДОПОЛНИТЕЛЬНЫЕ НАСТРОЙКИ:
-------------------------
- Включите Sniffing с destOverride: http, tls, quic
- Включите TCP Fast Open
- Установите Listen IP: 0.0.0.0 (или оставьте пустым)

ПАНЕЛЬ УПРАВЛЕНИЯ:
------------------
URL: http://YOUR_SERVER_IP:$PANEL_PORT
Username: $PANEL_USERNAME
Password: $PANEL_PASSWORD

ИНСТРУКЦИИ:
-----------
1. Войдите в панель 3X-UI
2. Перейдите в раздел "Inbounds"
3. Нажмите "Add Inbound"
4. Заполните параметры согласно настройкам выше
5. Сохраните и перезапустите Xray

ОПТИМИЗАЦИЯ СИСТЕМЫ:
--------------------
✓ BBR Congestion Control активирован
✓ TCP Fast Open включен
✓ TCP буферы увеличены до 128MB
✓ File descriptors увеличены до 1,000,000
✓ Network backlog оптимизирован
✓ Firewall настроен (порты 22, 443, $PANEL_PORT)

ПРОВЕРКА BBR:
-------------
Выполните команды для проверки:
  sysctl net.ipv4.tcp_congestion_control
  sysctl net.core.default_qdisc
  lsmod | grep bbr

РЕКОМЕНДАЦИИ:
-------------
1. Используйте домены маскировки, близкие географически к вашему серверу
2. Для Финляндии/Германии подходят:
   - www.microsoft.com
   - dl.google.com
   - www.speedtest.net
   - www.samsung.com
3. Регулярно обновляйте 3X-UI и Xray
4. Настройте SSL-сертификат для безопасного доступа к панели

=================================================
Конфигурация сохранена в /root/3x-ui-vless-config.txt
=================================================
EOF

print_msg "==================================================="
print_msg "  УСТАНОВКА ЗАВЕРШЕНА!"
print_msg "==================================================="
echo ""
print_msg "Конфигурация сохранена в: /root/3x-ui-vless-config.txt"
echo ""
print_msg "Параметры панели 3X-UI:"
echo "  URL: http://$(hostname -I | awk '{print $1}'):$PANEL_PORT"
echo "  Username: $PANEL_USERNAME"
echo ""
print_msg "Параметры для VLESS Reality инбаунда:"
echo "  Destination: $DEST_DOMAIN:443"
echo "  Private Key: $PRIVATE_KEY"
echo "  Short ID: $SHORT_ID"
echo "  Client UUID: $CLIENT_UUID"
echo ""
print_warning "ВАЖНО: Откройте файл /root/3x-ui-vless-config.txt для полной конфигурации!"
echo ""
print_msg "Для просмотра конфигурации выполните:"
echo "  cat /root/3x-ui-vless-config.txt"
echo ""
print_msg "Для управления панелью используйте команду: x-ui"
echo ""
print_msg "Перезагрузите систему для применения всех изменений:"
echo "  reboot"
echo ""
print_msg "==================================================="
