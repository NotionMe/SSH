# SSH Setup Scripts

Automated SSH server and client setup scripts for secure remote connections between two Linux computers.

## 📋 Overview

These scripts help you quickly establish secure SSH connection from a new PC to an old PC, allowing remote access and file transfers.

## 📁 Files

- `setup_server.sh` - Configure SSH server on old PC
- `setup_client.sh` - Configure SSH client on new PC  
- `diagnose.sh` - Troubleshooting tool
- `USAGE.md` - Detailed step-by-step guide

## ⚡ Quick Start

### 1. Server Setup (Old PC)
```bash
chmod +x setup_server.sh
./setup_server.sh
```
Note the displayed IP address and username!

### 2. Client Setup (New PC)
```bash
chmod +x setup_client.sh
./setup_client.sh 10.0.2.15 test
```
Replace IP and username with your values.

### 3. Connect
```bash
ssh old-pc
```

## 🔧 Features

- **Automatic installation** - Installs SSH server if needed
- **Secure authentication** - Uses Ed25519 key pairs
- **Firewall configuration** - Opens SSH port automatically
- **Connection testing** - Verifies setup works
- **Color logging** - Clear status messages
- **Cross-distro support** - Works on Ubuntu, Debian, Arch, CentOS

## 📖 Detailed Guide

For complete step-by-step instructions, see [USAGE.md](USAGE.md)

## 🛠️ Requirements

- Two Linux computers on same network
- `sudo` privileges for server setup
- SSH client tools (usually pre-installed)

## 🔒 Security Features

- Disables password authentication
- Uses modern Ed25519 encryption
- Configures secure SSH parameters
- Enables firewall rules for SSH
- Creates proper file permissions

## 📞 Common Commands

After setup:
```bash
# Connect to server
ssh old-pc

# Copy files
scp file.txt old-pc:~/
scp old-pc:~/file.txt ./

# Execute commands
ssh old-pc 'ls -la'
ssh old-pc 'df -h'
```

## 🚨 Troubleshooting

If connection fails:
1. Check both computers are on same network
2. Verify SSH service: `systemctl status ssh`
3. Run diagnostic: `./diagnose.sh`
4. Check firewall settings

## Структура проекту

```
ssh-setup/
├── setup_server.sh    # Скрипт для старого ПК (сервер)
├── setup_client.sh    # Скрипт для нового ПК (клієнт)
├── diagnose.sh        # Скрипт діагностики проблем
└── README.md         # Цей файл
```

## Підтримувані дистрибутиви

- **Arch Linux** - використовує `pacman`
- **Debian/Ubuntu** - використовує `apt`
- **RedHat/CentOS/Fedora** - використовує `yum`/`dnf`

Скрипти автоматично визначають дистрибутив та використовують відповідний пакетний менеджер.

## Опис скриптів

### 1. setup_server.sh
**Для старого ПК (сервера)**

Цей скрипт:
- Встановлює та налаштовує SSH сервер
- Створює необхідні директорії та файли
- Генерує SSH ключі для сервера
- Налаштовує безпечну конфігурацію SSH
- Виводить інформацію для підключення

### 2. setup_client.sh

**Для нового ПК (клієнта)**

Цей скрипт:
- Створює SSH ключ для клієнта
- Копіює публічний ключ на сервер
- Налаштовує SSH конфігурацію з аліасом
- Тестує підключення
- Виводить корисні команди

### 3. diagnose.sh

**Скрипт діагностики**

Цей скрипт:
- Визначає дистрибутив Linux
- Перевіряє стан SSH сервера та клієнта
- Аналізує мережеві налаштування
- Перевіряє брандмауер
- Виводить рекомендації для вирішення проблем

## Інструкція по використанню

### Крок 1: Налаштування сервера (старий ПК)

1. Скопіюйте `setup_server.sh` на старий ПК
2. Зробіть скрипт виконуваним:
   ```bash
   chmod +x setup_server.sh
   ```
3. Запустіть скрипт:
   ```bash
   ./setup_server.sh
   ```
4. Запам'ятайте IP адресу та ім'я користувача

### Крок 2: Налаштування клієнта (новий ПК)

1. Зробіть скрипт виконуваним:
   ```bash
   chmod +x setup_client.sh
   ```
2. Запустіть скрипт одним з способів:
   
   **Інтерактивний режим:**
   ```bash
   ./setup_client.sh
   ```
   
   **З параметрами:**
   ```bash
   ./setup_client.sh 192.168.1.100 username
   ```

### Крок 3: Використання

Після успішного налаштування ви можете:

```bash
# Підключитися до старого ПК
ssh old-pc

# Виконати команду на віддаленому ПК
ssh old-pc 'ls -la'

# Копіювати файли
scp file.txt old-pc:~/
scp old-pc:~/remote-file.txt ./

# Створити SSH тунель
ssh -L 8080:localhost:80 old-pc
```

### Крок 4: Діагностика проблем

Якщо щось не працює, запустіть скрипт діагностики:

```bash
./diagnose.sh
```

Скрипт перевірить:
- Стан SSH сервера та клієнта
- Мережеві налаштування
- Брандмауер
- Виведе рекомендації для вирішення проблем

## Функції безпеки

- Використання ED25519 ключів (найбезпечніший тип)
- Відключення парольної автентифікації
- Налаштування правильних прав доступу
- Автоматичне створення backup конфігурації

## Усунення проблем

### Якщо підключення не працює

1. Перевірте, чи запущений SSH сервер:

   **Arch Linux:**
   ```bash
   sudo systemctl status sshd
   ```

   **Debian/Ubuntu:**
   ```bash
   sudo systemctl status ssh
   ```

2. Перевірте брандмауер:

   **UFW (Ubuntu/Debian):**
   ```bash
   sudo ufw status
   sudo ufw allow ssh
   ```

   **Firewalld (CentOS/RHEL/Fedora):**
   ```bash
   sudo firewall-cmd --state
   sudo firewall-cmd --permanent --add-service=ssh
   sudo firewall-cmd --reload
   ```

   **iptables (Arch Linux):**
   ```bash
   sudo iptables -L INPUT
   sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
   ```

3. Перевірте SSH конфігурацію:
   ```bash
   sudo sshd -T | grep -i passwordauth
   ```

4. Перевірте логи SSH:

   **Arch Linux:**
   ```bash
   sudo journalctl -u sshd
   ```

   **Debian/Ubuntu:**
   ```bash
   sudo journalctl -u ssh
   ```

### Якщо забули IP адресу сервера:

На сервері виконайте:
```bash
hostname -I
```

### Для скидання налаштувань:

На сервері:
```bash
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart ssh
```

На клієнті:
```bash
rm -f ~/.ssh/config ~/.ssh/id_ed25519*
```

## Безпека

- Ніколи не передавайте приватний ключ іншим особам
- Регулярно оновлюйте SSH ключі
- Використовуйте сильні паролі для користувачів
- Розгляньте використання SSH з обмеженнями по IP

## Підтримка

Якщо виникли проблеми:
1. Перевірте логи
2. Переконайтеся, що обидва ПК знаходяться в одній мережі
3. Перевірте налаштування брандмауера
4. У разі потреби скиньте налаштування та повторіть процес
