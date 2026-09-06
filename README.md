# 3X-UI Auto-Installer с VLESS Reality

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![3X-UI](https://img.shields.io/badge/3X--UI-Latest-blue.svg)](https://github.com/MHSanaei/3x-ui)

Автоматизированный скрипт для развертывания и оптимизации VPN-сервера на базе 3X-UI с протоколом VLESS Reality. Включает системные оптимизации для максимальной производительности на серверах в Финляндии, Германии и других европейских локациях.

## 🚀 Особенности

### Автоматическая установка
- ✅ Установка последней версии 3X-UI панели
- ✅ Настройка протокола VLESS с Reality
- ✅ Генерация криптографических ключей (X25519, UUID, ShortID)
- ✅ Автоматическая настройка firewall (UFW)

### Системные оптимизации
- ⚡ **TCP BBR** - алгоритм управления перегрузкой от Google для увеличения пропускной способности на 4-14%
- ⚡ **TCP Fast Open** - сокращение времени установки соединения
- ⚡ **Увеличенные TCP-буферы** - до 128 МБ для высокоскоростных соединений
- ⚡ **Оптимизация file descriptors** - увеличение до 1,000,000 для поддержки тысяч одновременных соединений
- ⚡ **Network backlog оптимизация** - для обработки высоких нагрузок
- ⚡ **Оптимизация памяти** - настройка swap и кэширования

### Безопасность
- 🔒 Защита от SYN flood атак
- 🔒 Защита от IP spoofing
- 🔒 Автоматическая настройка firewall
- 🔒 Генерация уникальных криптографических ключей

## 📋 Требования

### Операционная система
- Ubuntu 20.04 LTS или новее
- Debian 10 или новее
- Версия ядра Linux ≥ 4.9 (для поддержки BBR)

### Серверные требования
- Минимум 512 МБ RAM (рекомендуется 1 ГБ+)
- Минимум 10 ГБ свободного места на диске
- Root-доступ к серверу
- Открытые порты: 22 (SSH), 443 (VLESS), пользовательский порт панели

## 🔧 Установка

### Быстрая установка

```bash
# Скачайте скрипт
wget https://raw.githubusercontent.com/svod011929/3x-ui-auto-installer/main/3x-ui-auto-install.sh

# Сделайте его исполняемым
chmod +x 3x-ui-auto-install.sh

# Запустите с правами root
sudo bash 3x-ui-auto-install.sh
```

### Установка одной командой

```bash
bash <(wget -qO- https://raw.githubusercontent.com/svod011929/3x-ui-auto-installer/main/3x-ui-auto-install.sh)
```

## 📖 Использование

### Во время установки

Скрипт запросит следующие параметры:

1. **Домен для маскировки** (например, `www.microsoft.com`)
   - Используется в качестве SNI для Reality
   - Рекомендуемые домены для EU серверов:
     - `www.microsoft.com`
     - `dl.google.com`
     - `www.speedtest.net`
     - `www.samsung.com`

2. **Порт панели 3X-UI** (по умолчанию: 2053)
   - Любой свободный порт от 1024 до 65535

3. **Имя пользователя** для доступа к панели

4. **Пароль** для доступа к панели

5. **Email первого клиента** (например, `user1@vpn`)

### После установки

После завершения установки скрипт создаст файл `/root/3x-ui-vless-config.txt` со всеми параметрами конфигурации.

Просмотрите конфигурацию:

```bash
cat /root/3x-ui-vless-config.txt
```

### Доступ к панели

Откройте в браузере:

```
http://YOUR_SERVER_IP:PORT
```

Используйте учетные данные, указанные при установке.

### Настройка инбаунда

1. Войдите в панель 3X-UI
2. Перейдите в раздел **Inbounds**
3. Нажмите **Add Inbound**
4. Выберите протокол **VLESS**
5. Заполните параметры из файла `/root/3x-ui-vless-config.txt`:
   - Port: `443`
   - Security: `reality`
   - Dest: `ВАШ_ДОМЕН:443`
   - Private Key, Short ID: из конфигурационного файла
   - Flow: `xtls-rprx-vision`
   - uTLS: `chrome` или `random`
6. Включите **Sniffing** с destOverride: `http`, `tls`, `quic`
7. Сохраните и перезапустите Xray

## ✅ Проверка оптимизаций

### Проверка BBR

```bash
# Проверка алгоритма congestion control
sysctl net.ipv4.tcp_congestion_control
# Ожидается: net.ipv4.tcp_congestion_control = bbr

# Проверка qdisc
sysctl net.core.default_qdisc
# Ожидается: net.core.default_qdisc = fq

# Проверка модуля BBR
lsmod | grep bbr
# Должен показать: tcp_bbr
```

### Проверка лимитов

```bash
# Проверка file descriptors
ulimit -n
# Ожидается: 1000000

# Проверка процессов
ulimit -u
# Ожидается: 1000000
```

### Проверка TCP буферов

```bash
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem
```

## 📊 Применяемые оптимизации

### Ядро Linux (sysctl)

| Параметр | Значение | Описание |
|----------|----------|----------|
| `net.ipv4.tcp_congestion_control` | `bbr` | Алгоритм BBR от Google |
| `net.core.default_qdisc` | `fq` | Fair Queue для BBR |
| `net.ipv4.tcp_fastopen` | `3` | TCP Fast Open (клиент+сервер) |
| `net.core.rmem_max` | `134217728` | Максимальный буфер приема (128 МБ) |
| `net.core.wmem_max` | `134217728` | Максимальный буфер передачи (128 МБ) |
| `net.core.somaxconn` | `65535` | Максимум подключений в очереди |
| `net.ipv4.tcp_max_syn_backlog` | `8192` | Защита от SYN flood |
| `fs.file-max` | `9000000` | Максимум файловых дескрипторов |
| `vm.swappiness` | `10` | Минимизация использования swap |

### Полный список оптимизаций

Подробный список всех применяемых параметров смотрите в файле `/etc/sysctl.d/99-vpn-optimization.conf` после установки.

## 🔄 Управление 3X-UI

```bash
# Запуск панели
x-ui start

# Остановка панели
x-ui stop

# Перезапуск панели
x-ui restart

# Проверка статуса
x-ui status

# Показать меню управления
x-ui
```

## 🛠️ Устранение неполадок

### BBR не активируется

Проверьте версию ядра:

```bash
uname -r
```

BBR требует версию ≥ 4.9. Обновите ядро, если необходимо:

```bash
apt update && apt upgrade -y
```

### Порт 443 занят

Если порт 443 используется другим сервисом (например, Nginx):

1. Остановите конфликтующий сервис
2. Или используйте другой порт для VLESS (например, 8443)

```bash
# Проверка портов
netstat -tulpn | grep :443
```

### Firewall блокирует подключения

Убедитесь, что UFW настроен правильно:

```bash
# Проверка статуса
ufw status

# Если нужно, откройте порты вручную
ufw allow 443/tcp
ufw allow YOUR_PANEL_PORT/tcp
ufw reload
```

### Не работает подключение клиентов

1. Проверьте, что Xray запущен:
   ```bash
   systemctl status x-ui
   ```

2. Проверьте логи:
   ```bash
   journalctl -u x-ui -f
   ```

3. Убедитесь, что в настройках клиента используются правильные параметры из конфигурационного файла

## 🔐 Рекомендации по безопасности

1. **Измените порт SSH** с 22 на нестандартный
2. **Настройте SSH-ключи** вместо парольной аутентификации
3. **Регулярно обновляйте** систему и 3X-UI:
   ```bash
   apt update && apt upgrade -y
   x-ui update
   ```
4. **Используйте сложные пароли** для панели управления
5. **Ограничьте доступ к панели** по IP (если возможно)
6. **Настройте fail2ban** для защиты от брутфорса:
   ```bash
   apt install fail2ban
   ```

## 📚 Дополнительные материалы

- [Документация 3X-UI](https://github.com/MHSanaei/3x-ui)
- [Документация Xray](https://xtls.github.io/)
- [VLESS Protocol](https://github.com/XTLS/Xray-core/issues/3)
- [Reality Protocol](https://github.com/XTLS/REALITY)
- [TCP BBR](https://github.com/google/bbr)

## 🤝 Вклад в проект

Приветствуются pull request'ы и issue! Если у вас есть предложения по улучшению скрипта, пожалуйста:

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменения (`git commit -m 'Add some AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Откройте Pull Request

## ⚠️ Отказ от ответственности

Этот скрипт предназначен для легального использования. Убедитесь, что использование VPN не нарушает законодательство вашей страны. Автор не несет ответственности за использование скрипта в незаконных целях.

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробности в файле [LICENSE](LICENSE).

## 👤 Автор

Создано для сообщества пользователей 3X-UI и Xray.

## ⭐ Поддержка проекта

Если этот скрипт помог вам, поставьте звезду ⭐ репозиторию!

---

**Примечание**: Скрипт оптимизирован для серверов в Финляндии и Германии, но может использоваться на любых VPS/Dedicated серверах с Ubuntu/Debian.

<!-- kododrive-projects-block -->

## Проекты KodoDrive

Другие проекты автора: [профиль @svod011929](https://github.com/svod011929) · [сайт](https://kododrive.ru) · [Telegram](https://t.me/KodoDrive)

### VPN и инфраструктура

- [BuryatVPN — VPN-сервис + Telegram](https://github.com/svod011929/buryatvpn)
- [VPN Server Installer — VLESS + TLS](https://github.com/svod011929/vpn-server-installer)
- **3X-UI Auto Installer** ← ты здесь
- [AWG Bot Installer — AmneziaWG](https://github.com/svod011929/awg-bot-installer)
- [RemnaShop Installer](https://github.com/svod011929/remnashop-installer)
- [VPN Auto Installer — панели](https://github.com/svod011929/vpn-auto-installer)
- [VPNHubBot — Telegram VPN-бот](https://github.com/svod011929/VPNHubBot)

### Telegram и автоматизация

- [KDS Server Panel — SSH из Telegram](https://github.com/svod011929/KDS_Server_Panel)
- [Telegram → VK Poster](https://github.com/svod011929/telegram-to-vk-poster)
- [KDS Parser CryptoBot](https://github.com/svod011929/kds_parser_cryptobot)
- [Auction Bot](https://github.com/svod011929/auction-bot)
- [Invest Bot](https://github.com/svod011929/invest-bot)
- [Crypto Check Bot](https://github.com/svod011929/crypto-check-bot)
- [KodoRefStarsBot](https://github.com/svod011929/KodoRefStarsBot)

### Магазины и финансы

- [KodoCashFlow](https://github.com/svod011929/KodoCashFlow)
- [Telegram Crypto Shop](https://github.com/svod011929/telegram-crypto-shop)
- [TalkProfit](https://github.com/svod011929/talkprofit)

### Сайты

- [KodoDrive Portfolio](https://github.com/svod011929/kododrive-portfolio)
- [kododrive.github.io](https://github.com/svod011929/kododrive.github.io)

<!-- /kododrive-projects-block -->
