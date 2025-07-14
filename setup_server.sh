#!/bin/bash

# Скрипт для старого ПК (сервера)
# Створює SSH ключ, налаштовує права доступу та підготовлює сервер для підключення

set -e

echo "=== Налаштування SSH сервера ==="
echo "Дата: $(date)"
echo "Користувач: $USER"
echo "Хост: $(hostname)"
echo

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функція для виводу повідомлень
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функція для визначення дистрибутива
detect_distro() {
    if [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# Функція для встановлення SSH сервера
install_ssh_server() {
    local distro=$(detect_distro)
    
    case $distro in
        "arch")
            log_info "Виявлено Arch Linux"
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm openssh
            ;;
        "debian")
            log_info "Виявлено Debian/Ubuntu"
            sudo apt update
            sudo apt install -y openssh-server
            ;;
        "redhat")
            log_info "Виявлено RedHat/CentOS/Fedora"
            sudo yum install -y openssh-server || sudo dnf install -y openssh-server
            ;;
        *)
            log_error "Невідомий дистрибутив. Спробуйте встановити openssh-server вручну"
            exit 1
            ;;
    esac
}

# Функція для запуску SSH сервера
start_ssh_server() {
    local distro=$(detect_distro)
    
    case $distro in
        "arch")
            sudo systemctl enable sshd
            sudo systemctl start sshd
            ;;
        "debian")
            sudo systemctl enable ssh
            sudo systemctl start ssh
            ;;
        "redhat")
            sudo systemctl enable sshd
            sudo systemctl start sshd
            ;;
        *)
            log_error "Невідомий дистрибутив для запуску SSH"
            exit 1
            ;;
    esac
}

# Функція для перевірки статусу SSH
check_ssh_status() {
    local distro=$(detect_distro)
    local service_name="ssh"
    
    if [ "$distro" = "arch" ] || [ "$distro" = "redhat" ]; then
        service_name="sshd"
    fi
    
    if sudo systemctl is-active --quiet $service_name; then
        log_info "SSH сервер успішно запущений"
        return 0
    else
        log_error "Помилка запуску SSH сервера"
        return 1
    fi
}

# Перевірка та встановлення SSH сервера
log_info "Перевірка SSH сервера..."
if ! command -v sshd &> /dev/null; then
    log_warn "SSH сервер не встановлений. Встановлюю..."
    install_ssh_server
else
    log_info "SSH сервер вже встановлений"
fi

# Запуск SSH сервера
log_info "Запуск SSH сервера..."
start_ssh_server

# Створення директорії .ssh якщо не існує
SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    log_info "Створення директорії .ssh..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
else
    log_info "Директорія .ssh вже існує"
fi

# Створення файлу authorized_keys якщо не існує
AUTH_KEYS="$SSH_DIR/authorized_keys"
if [ ! -f "$AUTH_KEYS" ]; then
    log_info "Створення файлу authorized_keys..."
    touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
else
    log_info "Файл authorized_keys вже існує"
fi

# Генерація SSH ключа для сервера (опціонально)
SERVER_KEY="$SSH_DIR/id_rsa"
if [ ! -f "$SERVER_KEY" ]; then
    log_info "Генерація SSH ключа для сервера..."
    ssh-keygen -t rsa -b 4096 -f "$SERVER_KEY" -N "" -C "$USER@$(hostname)-server"
    chmod 600 "$SERVER_KEY"
    chmod 644 "$SERVER_KEY.pub"
else
    log_info "SSH ключ сервера вже існує"
fi

# Налаштування SSH конфігурації
SSH_CONFIG="/etc/ssh/sshd_config"
log_info "Налаштування SSH конфігурації..."

# Backup оригінального конфігу
if [ ! -f "$SSH_CONFIG.backup" ]; then
    sudo cp "$SSH_CONFIG" "$SSH_CONFIG.backup"
    log_info "Створено backup SSH конфігурації"
fi

# Налаштування безпечних параметрів SSH
log_info "Оновлення SSH конфігурації для безпеки..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$SSH_CONFIG"
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSH_CONFIG"
sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' "$SSH_CONFIG"
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSH_CONFIG"

# Додавання користувача до групи ssh (якщо існує)
if getent group ssh > /dev/null 2>&1; then
    sudo usermod -a -G ssh "$USER"
    log_info "Користувач доданий до групи ssh"
fi

# Отримання IP адреси
IP_ADDRESS=$(hostname -I | awk '{print $1}')
log_info "IP адреса сервера: $IP_ADDRESS"

# Перезапуск SSH сервера
log_info "Перезапуск SSH сервера..."
local distro=$(detect_distro)
if [ "$distro" = "arch" ] || [ "$distro" = "redhat" ]; then
    sudo systemctl restart sshd
else
    sudo systemctl restart ssh
fi

# Перевірка статусу SSH
if check_ssh_status; then
    log_info "SSH сервер готовий до роботи"
else
    exit 1
fi

# Налаштування брандмауера (якщо потрібно)
log_info "Перевірка брандмауера..."
if command -v ufw &> /dev/null; then
    # Ubuntu/Debian UFW
    if sudo ufw status | grep -q "Status: active"; then
        log_info "UFW активний. Дозволяю SSH..."
        sudo ufw allow ssh
    fi
elif command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL/Fedora firewalld
    if sudo firewall-cmd --state 2>/dev/null | grep -q "running"; then
        log_info "Firewalld активний. Дозволяю SSH..."
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --reload
    fi
elif command -v iptables &> /dev/null; then
    # Базовий iptables (часто на Arch)
    log_info "Перевірка iptables..."
    if sudo iptables -L INPUT | grep -q "REJECT\|DROP"; then
        log_warn "Виявлено правила iptables. Переконайтесь, що порт 22 відкритий"
        log_info "Команда для відкриття порту 22: sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT"
    fi
fi

# Виведення інформації для підключення
echo
echo "=== ІНФОРМАЦІЯ ДЛЯ ПІДКЛЮЧЕННЯ ==="
echo "IP адреса: $IP_ADDRESS"
echo "Користувач: $USER"
echo "SSH порт: $(sudo ss -tlnp | grep :22 | awk '{print $4}' | cut -d: -f2 | head -1)"
echo
echo "Команда для підключення з іншого ПК:"
echo "ssh $USER@$IP_ADDRESS"
echo
echo "Для безпечного підключення скопіюйте публічний ключ клієнта до:"
echo "$AUTH_KEYS"
echo
log_info "Налаштування сервера завершено!"
echo "Тепер запустіть скрипт setup_client.sh на клієнтському ПК"
