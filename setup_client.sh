#!/bin/bash

# Скрипт для нового ПК (клієнта)
# Створює SSH ключ та підключається до віддаленого сервера

set -e

echo "=== Налаштування SSH клієнта ==="
echo "Дата: $(date)"
echo "Користувач: $USER"
echo "Хост: $(hostname)"
echo

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_input() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

# Параметри підключення
REMOTE_HOST=""
REMOTE_USER=""
KEY_TYPE="ed25519"
KEY_NAME="id_${KEY_TYPE}"
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/$KEY_NAME"

# Функція для отримання параметрів підключення
get_connection_params() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        log_input "Введіть параметри підключення до віддаленого сервера:"
        
        if [ -z "$1" ]; then
            read -p "IP адреса сервера: " REMOTE_HOST
        else
            REMOTE_HOST="$1"
        fi
        
        if [ -z "$2" ]; then
            read -p "Ім'я користувача на сервері [$USER]: " REMOTE_USER
            REMOTE_USER=${REMOTE_USER:-$USER}
        else
            REMOTE_USER="$2"
        fi
    else
        REMOTE_HOST="$1"
        REMOTE_USER="$2"
    fi
}

# Функція для створення SSH ключа
create_ssh_key() {
    if [ ! -f "$KEY_PATH" ]; then
        log_info "Створення SSH ключа ($KEY_TYPE)..."
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        
        ssh-keygen -t "$KEY_TYPE" -f "$KEY_PATH" -N "" -C "$USER@$(hostname)-client"
        chmod 600 "$KEY_PATH"
        chmod 644 "$KEY_PATH.pub"
        
        log_info "SSH ключ створено: $KEY_PATH"
    else
        log_info "SSH ключ вже існує: $KEY_PATH"
    fi
}

# Функція для копіювання ключа на сервер
copy_key_to_server() {
    log_info "Копіювання публічного ключа на сервер..."
    
    # Спроба автоматичного копіювання
    if command -v ssh-copy-id &> /dev/null; then
        log_info "Використання ssh-copy-id..."
        ssh-copy-id -i "$KEY_PATH.pub" "$REMOTE_USER@$REMOTE_HOST"
    else
        log_warn "ssh-copy-id не знайдено. Використання альтернативного методу..."
        
        # Альтернативний метод
        cat "$KEY_PATH.pub" | ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh"
    fi
    
    log_info "Публічний ключ успішно скопійовано на сервер"
}

# Функція для створення SSH конфігурації
create_ssh_config() {
    local config_file="$SSH_DIR/config"
    local host_alias="old-pc"
    
    log_info "Створення SSH конфігурації..."
    
    # Створення конфігурації якщо не існує
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
        chmod 600 "$config_file"
    fi
    
    # Перевірка чи вже є конфігурація для цього хоста
    if ! grep -q "Host $host_alias" "$config_file"; then
        cat >> "$config_file" << EOF

# Конфігурація для старого ПК
Host $host_alias
    HostName $REMOTE_HOST
    User $REMOTE_USER
    IdentityFile $KEY_PATH
    Port 22
    ServerAliveInterval 60
    ServerAliveCountMax 3
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
        
        log_info "Додано конфігурацію для хоста '$host_alias'"
        log_info "Тепер ви можете підключатися командою: ssh $host_alias"
    else
        log_info "Конфігурація для хоста '$host_alias' вже існує"
    fi
}

# Функція для тестування підключення
test_connection() {
    log_info "Тестування SSH підключення..."
    
    # Тест з використанням ключа
    if ssh -i "$KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH підключення успішне! Дата на сервері: \$(date)'" 2>/dev/null; then
        log_info "✓ Підключення через SSH ключ успішне!"
        return 0
    else
        log_error "✗ Помилка підключення через SSH ключ"
        return 1
    fi
}

# Функція для виведення корисних команд
show_useful_commands() {
    echo
    echo "=== КОРИСНІ КОМАНДИ ==="
    echo "Підключення до сервера:"
    echo "  ssh old-pc                    # Використовуючи аліас"
    echo "  ssh $REMOTE_USER@$REMOTE_HOST  # Прямий спосіб"
    echo
    echo "Копіювання файлів:"
    echo "  scp file.txt old-pc:~/         # На сервер"
    echo "  scp old-pc:~/file.txt ./       # З сервера"
    echo
    echo "Виконання команд на сервері:"
    echo "  ssh old-pc 'ls -la'"
    echo "  ssh old-pc 'df -h'"
    echo "  ssh old-pc 'htop'"
    echo
    echo "Тунелювання портів:"
    echo "  ssh -L 8080:localhost:80 old-pc  # Локальний тунель"
    echo "  ssh -R 9090:localhost:22 old-pc  # Зворотний тунель"
    echo
}

# Головна функція
main() {
    # Отримання параметрів
    get_connection_params "$1" "$2"
    
    log_info "Підключення до: $REMOTE_USER@$REMOTE_HOST"
    
    # Створення SSH ключа
    create_ssh_key
    
    # Копіювання ключа на сервер
    copy_key_to_server
    
    # Створення SSH конфігурації
    create_ssh_config
    
    # Тестування підключення
    if test_connection; then
        log_info "Налаштування клієнта успішно завершено!"
        show_useful_commands
    else
        log_error "Налаштування завершено з помилками"
        exit 1
    fi
}

# Перевірка параметрів та запуск
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Використання: $0 [IP_ADDRESS] [USERNAME]"
    echo "Приклад: $0 192.168.1.100 myuser"
    echo
    echo "Якщо параметри не вказані, скрипт запитає їх інтерактивно"
    exit 0
fi

# Запуск головної функції
main "$1" "$2"
