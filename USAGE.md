# SSH Setup Scripts - Usage Guide

## Overview
This guide explains how to use the SSH setup scripts to establish secure SSH connection between two computers.

## Prerequisites
- Two Linux computers (old PC as server, new PC as client)
- Both computers on the same network
- SSH package available on both systems

## Files
- `setup_server.sh` - Run on the old PC (server)
- `setup_client.sh` - Run on the new PC (client)
- `diagnose.sh` - Troubleshooting tool

---

## Step 1: Setup Server (Old PC)

### 1.1 Copy script to old PC
Transfer `setup_server.sh` to your old PC using:
- USB drive
- Download from repository
- Network transfer

### 1.2 Make script executable
```bash
chmod +x setup_server.sh
```

### 1.3 Run server setup
```bash
./setup_server.sh
```

**What it does:**
- Automatically requests root privileges
- Installs SSH server (if not installed)
- Creates SSH directories and files
- Configures SSH for security
- Starts SSH service
- Configures firewall (if needed)
- Displays connection information

### 1.4 Note the connection details
The script will display:
```
=== CONNECTION INFORMATION ===
IP address: 10.0.2.15
User: test
SSH port: 22

=== NEXT STEPS ===
1. Go to the new PC (client)
2. Run command:
   ./setup_client.sh 10.0.2.15 test
```

**Write down the IP address and username!**

---

## Step 2: Setup Client (New PC)

### 2.1 Copy script to new PC
Transfer `setup_client.sh` to your new PC.

### 2.2 Make script executable
```bash
chmod +x setup_client.sh
```

### 2.3 Run client setup

**Option A: With parameters (recommended)**
```bash
./setup_client.sh 10.0.2.15 test
```
Replace `10.0.2.15` and `test` with your actual IP and username.

**Option B: Interactive mode**
```bash
./setup_client.sh
```
Then enter IP and username when prompted.

### 2.4 Enter password when prompted
The script will ask for the server user's password to copy the SSH key.

**What the client script does:**
- Creates SSH key pair on client
- Copies public key to server
- Creates SSH configuration
- Tests the connection

---

## Step 3: Verify Connection

After successful setup, test the connection:

### 3.1 Connect using alias
```bash
ssh old-pc
```

### 3.2 Connect directly
```bash
ssh test@10.0.2.15
```

### 3.3 Test file transfer
```bash
# Copy file to server
scp myfile.txt old-pc:~/

# Copy file from server
scp old-pc:~/remotefile.txt ./
```

---

## Troubleshooting

### Common Issues

**1. Permission denied (publickey)**
- Run `setup_client.sh` again
- Check if server is running: `systemctl status ssh`

**2. Connection refused**
- Check server IP address
- Ensure SSH service is running on server
- Check firewall settings

**3. Network unreachable**
- Verify both computers are on same network
- Check IP address with `ip addr show`

### Use diagnostic script
```bash
./diagnose.sh
```

---

## Daily Usage

### Connect to server
```bash
ssh old-pc
```

### Copy files
```bash
# To server
scp file.txt old-pc:~/
scp -r folder/ old-pc:~/

# From server
scp old-pc:~/file.txt ./
scp -r old-pc:~/folder/ ./
```

### Execute commands remotely
```bash
ssh old-pc 'ls -la'
ssh old-pc 'df -h'
ssh old-pc 'sudo systemctl status nginx'
```

### Port forwarding
```bash
# Access server's web service on local port 8080
ssh -L 8080:localhost:80 old-pc

# Allow server to access client's service on port 22
ssh -R 9090:localhost:22 old-pc
```

### Keep connection alive
```bash
# Run command in background
ssh old-pc 'nohup long-running-command &'

# Use screen/tmux for persistent sessions
ssh old-pc
screen -S mysession
# Your work here
# Ctrl+A, D to detach
```

---

## Security Notes

1. **SSH keys are more secure than passwords**
2. **Private keys stay on client, never share them**
3. **Public keys are safe to share**
4. **Regular system updates recommended**
5. **Monitor SSH logs**: `journalctl -u ssh`

---

## Advanced Configuration

### Custom SSH config
Edit `~/.ssh/config` on client:
```
Host old-pc
    HostName 10.0.2.15
    User test
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### Multiple servers
Add more hosts to SSH config:
```
Host server1
    HostName 192.168.1.10
    User admin

Host server2
    HostName 192.168.1.20
    User root
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `ssh old-pc` | Connect to server |
| `scp file.txt old-pc:~/` | Copy file to server |
| `scp old-pc:~/file.txt ./` | Copy file from server |
| `ssh old-pc 'command'` | Execute command on server |
| `ssh -L 8080:localhost:80 old-pc` | Port forwarding |
| `./diagnose.sh` | Troubleshoot connection |

---

## Support

If you encounter issues:
1. Check both computers are on same network
2. Verify SSH service is running
3. Run diagnostic script
4. Check firewall settings
5. Ensure correct IP and username
