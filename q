[1mdiff --git a/setup_server.sh b/setup_server.sh[m
[1mindex 4d83a84..a369ab9 100755[m
[1m--- a/setup_server.sh[m
[1m+++ b/setup_server.sh[m
[36m@@ -1,34 +1,34 @@[m
 #!/bin/bash[m
 [m
[31m-# Скрипт для старого ПК (сервера)[m
[31m-# Створює SSH ключ, налаштовує права доступу та підготовлює сервер для підключення[m
[32m+[m[32m# SSH Server Setup Script[m
[32m+[m[32m# Sets up SSH server with key authentication[m
 [m
 set -e[m
 [m
[31m-# Перевірка запуску від root[m
[32m+[m[32m# Check if running as root[m
 if [ "$EUID" -ne 0 ]; then[m
[31m-    echo "=== Перезапуск з правами root ==="[m
[31m-    echo "Потрібні права root для налаштування SSH сервера"[m
[32m+[m[32m    echo "=== Restarting with root privileges ==="[m
[32m+[m[32m    echo "Root privileges required for SSH server setup"[m
     exec sudo "$0" "$@"[m
 fi[m
 [m
[31m-# Отримання оригінального користувача[m
[32m+[m[32m# Get original user[m
 ORIGINAL_USER="${SUDO_USER:-$USER}"[m
 ORIGINAL_HOME=$(eval echo "~$ORIGINAL_USER")[m
 [m
[31m-echo "=== Налаштування SSH сервера ==="[m
[31m-echo "Дата: $(date)"[m
[31m-echo "Користувач: $ORIGINAL_USER"[m
[31m-echo "Хост: $(hostname)"[m
[32m+[m[32mecho "=== SSH Server Setup ==="[m
[32m+[m[32mecho "Date: $(date)"[m
[32m+[m[32mecho "User: $ORIGINAL_USER"[m
[32m+[m[32mecho "Host: $(hostname)"[m
 echo[m
 [m
[31m-# Кольори для виводу[m
[32m+[m[32m# Colors for output[m
 RED='\033[0;31m'[m
 GREEN='\033[0;32m'[m
 YELLOW='\033[1;33m'[m
 NC='\033[0m' # No Color[m
 [m
[31m-# Функція для виводу повідомлень[m
[32m+[m[32m# Logging functions[m
 log_info() {[m
     echo -e "${GREEN}[INFO]${NC} $1"[m
 }[m
[36m@@ -41,7 +41,7 @@[m [mlog_error() {[m
     echo -e "${RED}[ERROR]${NC} $1"[m
 }[m
 [m
[31m-# Функція для визначення дистрибутива[m
[32m+[m[32m# Detect Linux distribution[m
 detect_distro() {[m
     if [ -f /etc/arch-release ]; then[m
         echo "arch"[m
[36m@@ -54,230 +54,226 @@[m [mdetect_distro() {[m
     fi[m
 }[m
 [m
[31m-# Функція для встановлення SSH сервера[m
[32m+[m[32m# Install SSH server[m
 install_ssh_server() {[m
[31m-    local distro=$(detect_distro)[m
[32m+[m[32m    distro=$(detect_distro)[m
     [m
     case $distro in[m
         "arch")[m
[31m-            log_info "Виявлено Arch Linux"[m
[31m-            sudo pacman -Syu --noconfirm[m
[31m-            sudo pacman -S --noconfirm openssh[m
[32m+[m[32m            log_info "Detected Arch Linux"[m
[32m+[m[32m            pacman -Syu --noconfirm[m
[32m+[m[32m            pacman -S --noconfirm openssh[m
             ;;[m
         "debian")[m
[31m-            log_info "Виявлено Debian/Ubuntu"[m
[31m-            sudo apt update[m
[31m-            sudo apt install -y openssh-server[m
[32m+[m[32m            log_info "Detected Debian/Ubuntu"[m
[32m+[m[32m            apt update[m
[32m+[m[32m            apt install -y openssh-server[m
             ;;[m
         "redhat")[m
[31m-            log_info "Виявлено RedHat/CentOS/Fedora"[m
[31m-            sudo yum install -y openssh-server || sudo dnf install -y openssh-server[m
[32m+[m[32m            log_info "Detected RedHat/CentOS/Fedora"[m
[32m+[m[32m            yum install -y openssh-server || dnf install -y openssh-server[m
             ;;[m
         *)[m
[31m-            log_error "Невідомий дистрибутив. Спробуйте встановити openssh-server вручну"[m
[32m+[m[32m            log_error "Unknown distribution. Please install openssh-server manually"[m
             exit 1[m
             ;;[m
     esac[m
 }[m
 [m
[31m-# Функція для запуску SSH сервера[m
[32m+[m[32m# Start SSH server[m
 start_ssh_server() {[m
[31m-    local distro=$(detect_distro)[m
[32m+[m[32m    distro=$(detect_distro)[m
     [m
     case $distro in[m
         "arch")[m
[31m-            sudo systemctl enable sshd[m
[31m-            sudo systemctl start sshd[m
[32m+[m[32m            systemctl enable sshd[m
[32m+[m[32m            systemctl start sshd[m
             ;;[m
         "debian")[m
[31m-            sudo systemctl enable ssh[m
[31m-            sudo systemctl start ssh[m
[32m+[m[32m            systemctl enable ssh[m
[32m+[m[32m            systemctl start ssh[m
             ;;[m
         "redhat")[m
[31m-            sudo systemctl enable sshd[m
[31m-            sudo systemctl start sshd[m
[32m+[m[32m            systemctl enable sshd[m
[32m+[m[32m            systemctl start sshd[m
             ;;[m
         *)[m
[31m-            log_error "Невідомий дистрибутив для запуску SSH"[m
[32m+[m[32m            log_error "Unknown distribution for starting SSH"[m
             exit 1[m
             ;;[m
     esac[m
 }[m
 [m
[31m-# Функція для перевірки статусу SSH[m
[32m+[m[32m# Check SSH status[m
 check_ssh_status() {[m
[31m-    local distro=$(detect_distro)[m
[31m-    local service_name="ssh"[m
[32m+[m[32m    distro=$(detect_distro)[m
[32m+[m[32m    service_name="ssh"[m
     [m
     if [ "$distro" = "arch" ] || [ "$distro" = "redhat" ]; then[m
         service_name="sshd"[m
     fi[m
     [m
[31m-    if sudo systemctl is-active --quiet $service_name; then[m
[31m-        log_info "SSH сервер успішно запущений"[m
[32m+[m[32m    if systemctl is-active --quiet $service_name; then[m
[32m+[m[32m        log_info "SSH server is running"[m
         return 0[m
     else[m
[31m-        log_error "Помилка запуску SSH сервера"[m
[32m+[m[32m        log_error "SSH server failed to start"[m
         return 1[m
     fi[m
 }[m
 [m
[31m-# Перевірка та встановлення SSH сервера[m
[31m-log_info "Перевірка SSH сервера..."[m
[32m+[m[32m# Check and install SSH server[m
[32m+[m[32mlog_info "Checking SSH server..."[m
 if ! command -v sshd &> /dev/null; then[m
[31m-    log_warn "SSH сервер не встановлений. Встановлюю..."[m
[32m+[m[32m    log_warn "SSH server not installed. Installing..."[m
     install_ssh_server[m
 else[m
[31m-    log_info "SSH сервер вже встановлений"[m
[32m+[m[32m    log_info "SSH server already installed"[m
 fi[m
 [m
[31m-# Запуск SSH сервера[m
[31m-log_info "Запуск SSH сервера..."[m
[32m+[m[32m# Start SSH server[m
[32m+[m[32mlog_info "Starting SSH server..."[m
 start_ssh_server[m
 [m
[31m-# Створення директорії .ssh якщо не існує[m
[32m+[m[32m# Create .ssh directory if not exists[m
 SSH_DIR="$ORIGINAL_HOME/.ssh"[m
 if [ ! -d "$SSH_DIR" ]; then[m
[31m-    log_info "Створення директорії .ssh..."[m
[32m+[m[32m    log_info "Creating .ssh directory..."[m
     sudo -u "$ORIGINAL_USER" mkdir -p "$SSH_DIR"[m
     chmod 700 "$SSH_DIR"[m
 else[m
[31m-    log_info "Директорія .ssh вже існує"[m
[32m+[m[32m    log_info ".ssh directory already exists"[m
 fi[m
 [m
[31m-# Створення файлу authorized_keys якщо не існує[m
[32m+[m[32m# Create authorized_keys file if not exists[m
 AUTH_KEYS="$SSH_DIR/authorized_keys"[m
 if [ ! -f "$AUTH_KEYS" ]; then[m
[31m-    log_info "Створення файлу authorized_keys..."[m
[32m+[m[32m    log_info "Creating authorized_keys file..."[m
     sudo -u "$ORIGINAL_USER" touch "$AUTH_KEYS"[m
     chmod 600 "$AUTH_KEYS"[m
 else[m
[31m-    log_info "Файл authorized_keys вже існує"[m
[32m+[m[32m    log_info "authorized_keys file already exists"[m
 fi[m
 [m
[31m-# Генерація SSH ключа для сервера (опціонально)[m
[32m+[m[32m# Generate SSH key for server (optional)[m
 SERVER_KEY="$SSH_DIR/id_rsa"[m
 if [ ! -f "$SERVER_KEY" ]; then[m
[31m-    log_info "Генерація SSH ключа для сервера..."[m
[32m+[m[32m    log_info "Generating SSH key for server..."[m
     sudo -u "$ORIGINAL_USER" ssh-keygen -t rsa -b 4096 -f "$SERVER_KEY" -N "" -C "$ORIGINAL_USER@$(hostname)-server"[m
     chmod 600 "$SERVER_KEY"[m
     chmod 644 "$SERVER_KEY.pub"[m
 else[m
[31m-    log_info "SSH ключ сервера вже існує"[m
[32m+[m[32m    log_info "Server SSH key already exists"[m
 fi[m
 [m
[31m-# Налаштування SSH конфігурації[m
[32m+[m[32m# Configure SSH[m
 SSH_CONFIG="/etc/ssh/sshd_config"[m
[31m-log_info "Налаштування SSH конфігурації..."[m
[32m+[m[32mlog_info "Configuring SSH..."[m
 [m
[31m-# Backup оригінального конфігу[m
[32m+[m[32m# Backup original config[m
 if [ ! -f "$SSH_CONFIG.backup" ]; then[m
[31m-    sudo cp "$SSH_CONFIG" "$SSH_CONFIG.backup"[m
[31m-    log_info "Створено backup SSH конфігурації"[m
[32m+[m[32m    cp "$SSH_CONFIG" "$SSH_CONFIG.backup"[m
[32m+[m[32m    log_info "Created SSH config backup"[m
 fi[m
 [m
[31m-# Налаштування безпечних параметрів SSH[m
[31m-log_info "Оновлення SSH конфігурації для безпеки..."[m
[31m-sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$SSH_CONFIG"[m
[31m-sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSH_CONFIG"[m
[31m-sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' "$SSH_CONFIG"[m
[31m-sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSH_CONFIG"[m
[32m+[m[32m# Set secure SSH parameters[m
[32m+[m[32mlog_info "Updating SSH config for security..."[m
[32m+[m[32msed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$SSH_CONFIG"[m
[32m+[m[32msed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSH_CONFIG"[m
[32m+[m[32msed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' "$SSH_CONFIG"[m
[32m+[m[32msed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSH_CONFIG"[m
 [m
[31m-# Додавання користувача до групи ssh (якщо існує)[m
[32m+[m[32m# Add user to ssh group (if exists)[m
 if getent group ssh > /dev/null 2>&1; then[m
[31m-    sudo usermod -a -G ssh "$ORIGINAL_USER"[m
[31m-    log_info "Користувач доданий до групи ssh"[m
[32m+[m[32m    usermod -a -G ssh "$ORIGINAL_USER"[m
[32m+[m[32m    log_info "User added to ssh group"[m
 fi[m
 [m
[31m-# Отримання IP адреси[m
[31m-log_info "Отримання IP адреси сервера..."[m
[32m+[m[32m# Get server IP address[m
[32m+[m[32mlog_info "Getting server IP address..."[m
 IP_ADDRESS=$(hostname -I | awk '{print $1}' 2>/dev/null)[m
 [m
[31m-# Якщо hostname -I не спрацювала, спробуємо інші методи[m
 if [ -z "$IP_ADDRESS" ]; then[m
     IP_ADDRESS=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1)[m
 fi[m
 [m
[31m-# Якщо і це не спрацювало, спробуємо ip addr[m
 if [ -z "$IP_ADDRESS" ]; then[m
     IP_ADDRESS=$(ip addr show | grep -E "inet.*scope global" | awk '{print $2}' | cut -d/ -f1 | head -1)[m
 fi[m
 [m
[31m-# Якщо все ще немає IP, спробуємо ifconfig[m
 if [ -z "$IP_ADDRESS" ]; then[m
     IP_ADDRESS=$(ifconfig 2>/dev/null | grep -E "inet.*broadcast" | awk '{print $2}' | head -1)[m
 fi[m
 [m
[31m-# Якщо IP досі не знайдено[m
 if [ -z "$IP_ADDRESS" ]; then[m
[31m-    log_warn "Не вдалося автоматично визначити IP адресу"[m
[31m-    echo "Виконайте команду 'ip addr show' або 'ifconfig' для отримання IP адреси"[m
[32m+[m[32m    log_warn "Could not determine IP address automatically"[m
[32m+[m[32m    echo "Run 'ip addr show' or 'ifconfig' to get IP address"[m
     IP_ADDRESS="[IP_NOT_FOUND]"[m
 else[m
[31m-    log_info "IP адреса сервера: $IP_ADDRESS"[m
[32m+[m[32m    log_info "Server IP address: $IP_ADDRESS"[m
 fi[m
 [m
[31m-# Перезапуск SSH сервера[m
[31m-log_info "Перезапуск SSH сервера..."[m
[31m-local distro=$(detect_distro)[m
[32m+[m[32m# Restart SSH server[m
[32m+[m[32mlog_info "Restarting SSH server..."[m
[32m+[m[32mdistro=$(detect_distro)[m
 if [ "$distro" = "arch" ] || [ "$distro" = "redhat" ]; then[m
[31m-    sudo systemctl restart sshd[m
[32m+[m[32m    systemctl restart sshd[m
 else[m
[31m-    sudo systemctl restart ssh[m
[32m+[m[32m    systemctl restart ssh[m
 fi[m
 [m
[31m-# Перевірка статусу SSH[m
[32m+[m[32m# Check SSH status[m
 if check_ssh_status; then[m
[31m-    log_info "SSH сервер готовий до роботи"[m
[32m+[m[32m    log_info "SSH server is ready"[m
 else[m
     exit 1[m
 fi[m
 [m
[31m-# Налаштування брандмауера (якщо потрібно)[m
[31m-log_info "Перевірка брандмауера..."[m
[32m+[m[32m# Configure firewall (if needed)[m
[32m+[m[32mlog_info "Checking firewall..."[m
 if command -v ufw &> /dev/null; then[m
     # Ubuntu/Debian UFW[m
[31m-    if sudo ufw status | grep -q "Status: active"; then[m
[31m-        log_info "UFW активний. Дозволяю SSH..."[m
[31m-        sudo ufw allow ssh[m
[32m+[m[32m    if ufw status | grep -q "Status: active"; then[m
[32m+[m[32m        log_info "UFW is active. Allowing SSH..."[m
[32m+[m[32m        ufw allow ssh[m
     fi[m
 elif command -v firewall-cmd &> /dev/null; then[m
     # CentOS/RHEL/Fedora firewalld[m
[31m-    if sudo firewall-cmd --state 2>/dev/null | grep -q "running"; then[m
[31m-        log_info "Firewalld активний. Дозволяю SSH..."[m
[31m-        sudo firewall-cmd --permanent --add-service=ssh[m
[31m-        sudo firewall-cmd --reload[m
[32m+[m[32m    if firewall-cmd --state 2>/dev/null | grep -q "running"; then[m
[32m+[m[32m        log_info "Firewalld is active. Allowing SSH..."[m
[32m+[m[32m        firewall-cmd --permanent --add-service=ssh[m
[32m+[m[32m        firewall-cmd --reload[m
     fi[m
 elif command -v iptables &> /dev/null; then[m
[31m-    # Базовий iptables (часто на Arch)[m
[31m-    log_info "Перевірка iptables..."[m
[31m-    if sudo iptables -L INPUT | grep -q "REJECT\|DROP"; then[m
[31m-        log_warn "Виявлено правила iptables. Переконайтесь, що порт 22 відкритий"[m
[31m-        log_info "Команда для відкриття порту 22: sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT"[m
[32m+[m[32m    # Basic iptables (common on Arch)[m
[32m+[m[32m    log_info "Checking iptables..."[m
[32m+[m[32m    if iptables -L INPUT | grep -q "REJECT\|DROP"; then[m
[32m+[m[32m        log_warn "Found iptables rules. Make sure port 22 is open"[m
[32m+[m[32m        log_info "Command to open port 22: iptables -I INPUT -p tcp --dport 22 -j ACCEPT"[m
     fi[m
 fi[m
 [m
[31m-# Виведення інформації для підключення[m
[32m+[m[32m# Display connection information[m
 echo[m
[31m-echo "=== ІНФОРМАЦІЯ ДЛЯ ПІДКЛЮЧЕННЯ ==="[m
[31m-echo "IP адреса: $IP_ADDRESS"[m
[31m-echo "Користувач: $ORIGINAL_USER"[m
[31m-echo "SSH порт: $(sudo ss -tlnp | grep :22 | awk '{print $4}' | cut -d: -f2 | head -1)"[m
[32m+[m[32mecho "=== CONNECTION INFORMATION ==="[m
[32m+[m[32mecho "IP address: $IP_ADDRESS"[m
[32m+[m[32mecho "User: $ORIGINAL_USER"[m
[32m+[m[32mecho "SSH port: $(ss -tlnp | grep :22 | awk '{print $4}' | cut -d: -f2 | head -1)"[m
 echo[m
[31m-echo "Команда для підключення з іншого ПК:"[m
[32m+[m[32mecho "Command to connect from another PC:"[m
 echo "ssh $ORIGINAL_USER@$IP_ADDRESS"[m
 echo[m
[31m-echo "Для безпечного підключення скопіюйте публічний ключ клієнта до:"[m
[32m+[m[32mecho "For secure connection copy client public key to:"[m
 echo "$AUTH_KEYS"[m
 echo[m
[31m-log_info "Налаштування сервера завершено!"[m
[32m+[m[32mlog_info "Server setup completed!"[m
 echo[m
[31m-echo "=== ДАЛЬШІ КРОКИ ==="[m
[31m-echo "1. Перейдіть на новий ПК (клієнт)"[m
[31m-echo "2. Запустіть команду:"[m
[32m+[m[32mecho "=== NEXT STEPS ==="[m
[32m+[m[32mecho "1. Go to the new PC (client)"[m
[32m+[m[32mecho "2. Run command:"[m
 echo "   ./setup_client.sh $IP_ADDRESS $ORIGINAL_USER"[m
 echo[m
[31m-echo "Або запустіть інтерактивно:"[m
[32m+[m[32mecho "Or run interactively:"[m
 echo "   ./setup_client.sh"[m
[31m-echo "   і введіть IP: $IP_ADDRESS"[m
[31m-echo "   і введіть користувача: $ORIGINAL_USER"[m
[32m+[m[32mecho "   and enter IP: $IP_ADDRESS"[m
[32m+[m[32mecho "   and enter user: $ORIGINAL_USER"[m
