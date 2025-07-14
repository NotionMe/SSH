#!/bin/bash

# SSH Client Setup Script
# Creates SSH key and connects to remote server

set -e

echo "=== SSH Client Setup ==="
echo "Date: $(date)"
echo "User: $USER"
echo "Host: $(hostname 2>/dev/null || echo 'unknown')"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_input() {
    echo -e "${BLUE}[INPUT]${NC} $1"
}

# Connection parameters
REMOTE_HOST=""
REMOTE_USER=""
KEY_TYPE="ed25519"
KEY_NAME="id_${KEY_TYPE}"
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/$KEY_NAME"

# Function to get connection parameters
get_connection_params() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        log_input "Enter connection parameters:"
        
        while [ -z "$REMOTE_HOST" ]; do
            read -p "Server IP address: " REMOTE_HOST
        done
        
        while [ -z "$REMOTE_USER" ]; do
            read -p "Username on server: " REMOTE_USER
        done
    else
        REMOTE_HOST="$1"
        REMOTE_USER="$2"
    fi
}

# Function to create SSH key
create_ssh_key() {
    if [ ! -f "$KEY_PATH" ]; then
        log_info "Creating SSH key..."
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        ssh-keygen -t "$KEY_TYPE" -f "$KEY_PATH" -N "" -C "$USER@$(hostname 2>/dev/null || echo 'client')"
        chmod 600 "$KEY_PATH"
        chmod 644 "$KEY_PATH.pub"
        log_info "SSH key created: $KEY_PATH"
    else
        log_info "SSH key already exists: $KEY_PATH"
    fi
}

# Function to copy key to server
copy_key_to_server() {
    log_info "Copying public key to server..."
    
    # Remove the host from known_hosts to avoid conflicts
    ssh-keygen -R "$REMOTE_HOST" 2>/dev/null || true
    
    # Try to copy key with timeout
    if command -v ssh-copy-id &> /dev/null; then
        log_info "Using ssh-copy-id (you may need to enter password)..."
        
        # Use timeout to prevent hanging
        if timeout 60 ssh-copy-id -i "$KEY_PATH.pub" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST"; then
            log_info "✓ Public key successfully copied to server"
        else
            log_error "✗ Failed to copy key using ssh-copy-id"
            log_info "Trying manual method..."
            
            # Fallback to manual method
            if timeout 60 bash -c "cat '$KEY_PATH.pub' | ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 '$REMOTE_USER@$REMOTE_HOST' 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh'"; then
                log_info "✓ Public key successfully copied using manual method"
            else
                log_error "✗ Both methods failed to copy public key"
                log_error "Please check:"
                log_error "1. Server is running and accessible"
                log_error "2. Username and IP are correct"
                log_error "3. Password authentication is enabled on server"
                exit 1
            fi
        fi
    else
        log_info "Using manual key copy method..."
        if timeout 60 bash -c "cat '$KEY_PATH.pub' | ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 '$REMOTE_USER@$REMOTE_HOST' 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh'"; then
            log_info "✓ Public key successfully copied to server"
        else
            log_error "✗ Failed to copy public key"
            exit 1
        fi
    fi
}

# Function to create SSH config
create_ssh_config() {
    config_file="$SSH_DIR/config"
    host_alias="old-pc"
    
    log_info "Creating SSH configuration..."
    
    # Create config file if not exists
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
        chmod 600 "$config_file"
    fi
    
    # Check if configuration already exists
    if ! grep -q "Host $host_alias" "$config_file"; then
        cat >> "$config_file" << EOF

# Configuration for old PC
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
        
        log_info "Added configuration for host '$host_alias'"
        log_info "Now you can connect with: ssh $host_alias"
    else
        log_info "Configuration for host '$host_alias' already exists"
    fi
}

# Function to disable password authentication on server
disable_password_auth() {
    log_info "Disabling password authentication on server for security..."
    
    # Connect to server and disable password authentication
    ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "
        sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo systemctl restart sshd || sudo systemctl restart ssh
        echo 'Password authentication disabled successfully'
    " 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_info "✓ Password authentication disabled on server"
    else
        log_warn "Could not disable password authentication automatically"
        log_warn "Please run on server: sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
        log_warn "Then restart SSH: sudo systemctl restart sshd"
    fi
}

# Function to test connection
test_connection() {
    log_info "Testing SSH connection..."
    
    # Test with key
    if ssh -i "$KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH connection successful! Server date: \$(date)'" 2>/dev/null; then
        log_info "✓ SSH key authentication successful"
        return 0
    else
        log_error "✗ SSH key authentication failed"
        return 1
    fi
}

# Function to show useful commands
show_useful_commands() {
    echo
    echo "=== USEFUL COMMANDS ==="
    echo "Connect to server:"
    echo "  ssh old-pc                    # Using alias"
    echo "  ssh $REMOTE_USER@$REMOTE_HOST  # Direct method"
    echo
    echo "Copy files:"
    echo "  scp file.txt old-pc:~/         # To server"
    echo "  scp old-pc:~/file.txt ./       # From server"
    echo
    echo "Execute commands on server:"
    echo "  ssh old-pc 'ls -la'"
    echo "  ssh old-pc 'df -h'"
    echo
    echo "Port forwarding:"
    echo "  ssh -L 8080:localhost:80 old-pc  # Local tunnel"
    echo "  ssh -R 9090:localhost:22 old-pc  # Reverse tunnel"
    echo
}

# Main function
main() {
    # Get parameters
    get_connection_params "$1" "$2"
    
    log_info "Connecting to: $REMOTE_USER@$REMOTE_HOST"
    
    # Create SSH key
    create_ssh_key
    
    # Copy key to server
    copy_key_to_server
    
    # Create SSH config
    create_ssh_config
    
    # Test connection
    if test_connection; then
        log_info "✓ SSH key authentication successful"
        
        # Disable password authentication on server
        disable_password_auth
        
        log_info "✓ Setup completed successfully!"
        show_useful_commands
    else
        log_error "✗ Setup completed with errors"
        echo "Try connecting manually: ssh $REMOTE_USER@$REMOTE_HOST"
        exit 1
    fi
}

# Check parameters and run
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $0 [IP_ADDRESS] [USERNAME]"
    echo "Example: $0 10.0.2.15 test"
    exit 0
fi

# Run main function
main "$1" "$2"