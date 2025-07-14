#!/bin/bash

# SSH Server Setup Script
# Sets up SSH server with key authentication

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "=== Restarting with root privileges ==="
    echo "Root privileges required for SSH server setup"
    exec sudo "$0" "$@"
fi

# Get original user
ORIGINAL_USER="${SUDO_USER:-$USER}"
ORIGINAL_HOME=$(eval echo "~$ORIGINAL_USER")

echo "=== SSH Server Setup ==="
echo "Date: $(date)"
echo "User: $ORIGINAL_USER"
echo "Host: $(hostname)"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect Linux distribution
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

# Install SSH server
install_ssh_server() {
    distro=$(detect_distro)
    
    case $distro in
        "arch")
            log_info "Detected Arch Linux"
            pacman -Syu --noconfirm
            pacman -S --noconfirm openssh
            ;;
        "debian")
            log_info "Detected Debian/Ubuntu"
            apt update
            apt install -y openssh-server
            ;;
        "redhat")
            log_info "Detected RedHat/CentOS/Fedora"
            yum install -y openssh-server || dnf install -y openssh-server
            ;;
        *)
            log_error "Unknown distribution. Please install openssh-server manually"
            exit 1
            ;;
    esac
}

# Start SSH server
start_ssh_server() {
    distro=$(detect_distro)
    
    case $distro in
        "arch")
            systemctl enable sshd
            systemctl start sshd
            ;;
        "debian")
            systemctl enable ssh
            systemctl start ssh
            ;;
        "redhat")
            systemctl enable sshd
            systemctl start sshd
            ;;
        *)
            log_error "Unknown distribution for starting SSH"
            exit 1
            ;;
    esac
}

# Check SSH status
check_ssh_status() {
    distro=$(detect_distro)
    service_name="ssh"
    
    if [ "$distro" = "arch" ] || [ "$distro" = "redhat" ]; then
        service_name="sshd"
    fi
    
    if systemctl is-active --quiet $service_name; then
        log_info "SSH server is running"
        return 0
    else
        log_error "SSH server failed to start"
        return 1
    fi
}

# Check and install SSH server
log_info "Checking SSH server..."
if ! command -v sshd &> /dev/null; then
    log_warn "SSH server not installed. Installing..."
    install_ssh_server
else
    log_info "SSH server already installed"
fi

# Start SSH server
log_info "Starting SSH server..."
start_ssh_server

# Create .ssh directory if not exists
SSH_DIR="$ORIGINAL_HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    log_info "Creating .ssh directory..."
    sudo -u "$ORIGINAL_USER" mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
else
    log_info ".ssh directory already exists"
fi

# Create authorized_keys file if not exists
AUTH_KEYS="$SSH_DIR/authorized_keys"
if [ ! -f "$AUTH_KEYS" ]; then
    log_info "Creating authorized_keys file..."
    sudo -u "$ORIGINAL_USER" touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
else
    log_info "authorized_keys file already exists"
fi

# Generate SSH key for server (optional)
SERVER_KEY="$SSH_DIR/id_rsa"
if [ ! -f "$SERVER_KEY" ]; then
    log_info "Generating SSH key for server..."
    sudo -u "$ORIGINAL_USER" ssh-keygen -t rsa -b 4096 -f "$SERVER_KEY" -N "" -C "$ORIGINAL_USER@$(hostname)-server"
    chmod 600 "$SERVER_KEY"
    chmod 644 "$SERVER_KEY.pub"
else
    log_info "Server SSH key already exists"
fi

# Configure SSH
SSH_CONFIG="/etc/ssh/sshd_config"
log_info "Configuring SSH..."

# Backup original config
if [ ! -f "$SSH_CONFIG.backup" ]; then
    cp "$SSH_CONFIG" "$SSH_CONFIG.backup"
    log_info "Created SSH config backup"
fi

# Set secure SSH parameters
log_info "Updating SSH config for security..."
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' "$SSH_CONFIG"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' "$SSH_CONFIG"
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSH_CONFIG"
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' "$SSH_CONFIG"
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSH_CONFIG"

log_info "Temporarily enabled password authentication for key setup"

# Add user to ssh group (if exists)
if getent group ssh > /dev/null 2>&1; then
    usermod -a -G ssh "$ORIGINAL_USER"
    log_info "User added to ssh group"
fi

# Get server IP address
log_info "Getting server IP address..."
IP_ADDRESS=$(hostname -I | awk '{print $1}' 2>/dev/null)

if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1)
fi

if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(ip addr show | grep -E "inet.*scope global" | awk '{print $2}' | cut -d/ -f1 | head -1)
fi

if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(ifconfig 2>/dev/null | grep -E "inet.*broadcast" | awk '{print $2}' | head -1)
fi

if [ -z "$IP_ADDRESS" ]; then
    log_warn "Could not determine IP address automatically"
    echo "Run 'ip addr show' or 'ifconfig' to get IP address"
    IP_ADDRESS="[IP_NOT_FOUND]"
else
    log_info "Server IP address: $IP_ADDRESS"
fi

# Restart SSH server
log_info "Restarting SSH server..."
distro=$(detect_distro)
if [ "$distro" = "arch" ] || [ "$distro" = "redhat" ]; then
    systemctl restart sshd
else
    systemctl restart ssh
fi

# Check SSH status
if check_ssh_status; then
    log_info "SSH server is ready"
else
    exit 1
fi

# Configure firewall (if needed)
log_info "Checking firewall..."
if command -v ufw &> /dev/null; then
    # Ubuntu/Debian UFW
    if ufw status | grep -q "Status: active"; then
        log_info "UFW is active. Allowing SSH..."
        ufw allow ssh
    fi
elif command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL/Fedora firewalld
    if firewall-cmd --state 2>/dev/null | grep -q "running"; then
        log_info "Firewalld is active. Allowing SSH..."
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
    fi
elif command -v iptables &> /dev/null; then
    # Basic iptables (common on Arch)
    log_info "Checking iptables..."
    if iptables -L INPUT | grep -q "REJECT\|DROP"; then
        log_warn "Found iptables rules. Make sure port 22 is open"
        log_info "Command to open port 22: iptables -I INPUT -p tcp --dport 22 -j ACCEPT"
    fi
fi

# Display connection information
echo
echo "=== CONNECTION INFORMATION ==="
echo "IP address: $IP_ADDRESS"
echo "User: $ORIGINAL_USER"
echo "SSH port: $(ss -tlnp | grep :22 | awk '{print $4}' | cut -d: -f2 | head -1)"
echo
echo "Command to connect from another PC:"
echo "ssh $ORIGINAL_USER@$IP_ADDRESS"
echo
echo "For secure connection copy client public key to:"
echo "$AUTH_KEYS"
echo
log_info "Server setup completed!"
echo
echo "=== NEXT STEPS ==="
echo "1. Go to the new PC (client)"
echo "2. Run command:"
echo "   ./setup_client.sh $IP_ADDRESS $ORIGINAL_USER"
echo
echo "Or run interactively:"
echo "   ./setup_client.sh"
echo "   and enter IP: $IP_ADDRESS"
echo "   and enter user: $ORIGINAL_USER"
echo
echo "Note: Password authentication is temporarily enabled for key setup"
echo "It will be disabled automatically after client setup completes"
