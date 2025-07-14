#!/bin/bash

# Допоміжний скрипт для перевірки системи та налаштувань
# Використовується для діагностики проблем з SSH

echo "=== Діагностика SSH системи ==="
echo

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Визначення дистрибутива
detect_distro() {
    if [ -f /etc/arch-release ]; then
        echo "Arch Linux"
    elif [ -f /etc/debian_version ]; then
        echo "Debian/Ubuntu"
    elif [ -f /etc/redhat-release ]; then
        echo "RedHat/CentOS/Fedora"
    else
        echo "Невідомий дистрибутив"
    fi
}

# Перевірка SSH сервера
check_ssh_server() {
    log_info "Перевірка SSH сервера..."
    
    if command -v sshd &> /dev/null; then
        echo "  ✓ SSH сервер встановлений"
        
        # Перевірка статусу сервісу
        local distro=$(detect_distro)
        local service_name="ssh"
        
        if [[ "$distro" == "Arch Linux" ]] || [[ "$distro" == "RedHat"* ]]; then
            service_name="sshd"
        fi
        
        if systemctl is-active --quiet $service_name; then
            echo "  ✓ SSH сервер запущений"
        else
            echo "  ✗ SSH сервер не запущений"
            log_warn "Запустіть: sudo systemctl start $service_name"
        fi
        
        if systemctl is-enabled --quiet $service_name; then
            echo "  ✓ SSH сервер включений для автозапуску"
        else
            echo "  ✗ SSH сервер не включений для автозапуску"
            log_warn "Включіть: sudo systemctl enable $service_name"
        fi
    else
        echo "  ✗ SSH сервер не встановлений"
        log_error "Встановіть SSH сервер за допомогою скрипта setup_server.sh"
    fi
}

# Перевірка SSH клієнта
check_ssh_client() {
    log_info "Перевірка SSH клієнта..."
    
    if command -v ssh &> /dev/null; then
        echo "  ✓ SSH клієнт встановлений"
        
        # Перевірка ключів
        if [ -d "$HOME/.ssh" ]; then
            echo "  ✓ Директорія .ssh існує"
            
            local key_found=false
            for key_type in rsa ed25519 ecdsa dsa; do
                if [ -f "$HOME/.ssh/id_$key_type" ]; then
                    echo "  ✓ Знайдено ключ: id_$key_type"
                    key_found=true
                fi
            done
            
            if [ "$key_found" = false ]; then
                echo "  ✗ SSH ключі не знайдені"
                log_warn "Створіть ключі за допомогою скрипта setup_client.sh"
            fi
        else
            echo "  ✗ Директорія .ssh не існує"
        fi
    else
        echo "  ✗ SSH клієнт не встановлений"
        log_error "Встановіть SSH клієнт"
    fi
}

# Перевірка мережі
check_network() {
    log_info "Перевірка мережі..."
    
    # IP адреси
    local ip_addresses=$(hostname -I)
    echo "  IP адреси: $ip_addresses"
    
    # Перевірка порту 22
    if ss -tlnp | grep -q ":22 "; then
        echo "  ✓ Порт 22 відкритий"
    else
        echo "  ✗ Порт 22 не відкритий"
        log_warn "SSH сервер може бути не запущений"
    fi
}

# Перевірка брандмауера
check_firewall() {
    log_info "Перевірка брандмауера..."
    
    # UFW (Ubuntu/Debian)
    if command -v ufw &> /dev/null; then
        local ufw_status=$(sudo ufw status 2>/dev/null)
        if echo "$ufw_status" | grep -q "Status: active"; then
            echo "  ⚠ UFW активний"
            if echo "$ufw_status" | grep -q "22/tcp"; then
                echo "  ✓ SSH дозволений в UFW"
            else
                echo "  ✗ SSH не дозволений в UFW"
                log_warn "Виконайте: sudo ufw allow ssh"
            fi
        else
            echo "  ✓ UFW неактивний"
        fi
    fi
    
    # Firewalld (CentOS/RHEL/Fedora)
    if command -v firewall-cmd &> /dev/null; then
        if sudo firewall-cmd --state 2>/dev/null | grep -q "running"; then
            echo "  ⚠ Firewalld активний"
            if sudo firewall-cmd --list-services | grep -q "ssh"; then
                echo "  ✓ SSH дозволений в Firewalld"
            else
                echo "  ✗ SSH не дозволений в Firewalld"
                log_warn "Виконайте: sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload"
            fi
        else
            echo "  ✓ Firewalld неактивний"
        fi
    fi
    
    # iptables (часто на Arch)
    if command -v iptables &> /dev/null; then
        if sudo iptables -L INPUT 2>/dev/null | grep -q "REJECT\|DROP"; then
            echo "  ⚠ Виявлено правила iptables"
            log_warn "Переконайтесь, що порт 22 відкритий"
        else
            echo "  ✓ Базові правила iptables"
        fi
    fi
}

# Головна функція
main() {
    local distro=$(detect_distro)
    echo "Дистрибутив: $distro"
    echo "Користувач: $USER"
    echo "Хост: $(hostname)"
    echo
    
    check_ssh_server
    echo
    check_ssh_client
    echo
    check_network
    echo
    check_firewall
    echo
    
    log_info "Діагностика завершена"
}

# Запуск
main "$@"
