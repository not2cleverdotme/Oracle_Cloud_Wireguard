# WireGuard Oracle Cloud Automated Installation

This repository contains a comprehensive script for automated WireGuard VPN installation on Oracle Cloud Infrastructure (OCI). The script handles the complete setup process including package installation, configuration, firewall setup, and service management.

## Features

- **Multi-OS Support**: Compatible with Oracle Linux, Ubuntu, CentOS, and RHEL
- **Automated Setup**: Complete installation with minimal user intervention
- **Security Focused**: Proper key generation, permissions, and firewall configuration
- **Client Management**: Built-in tools for adding/removing clients
- **Monitoring**: Status checking and logging capabilities
- **Oracle Cloud Optimized**: Specifically designed for OCI environments

## Prerequisites

- Oracle Cloud Infrastructure instance
- Root/sudo access
- Internet connectivity for package downloads
- Supported OS: Oracle Linux, Ubuntu, CentOS, RHEL

## Quick Start

1. **Download the script**:
   ```bash
   wget https://raw.githubusercontent.com/not2cleverdotme/wireguard_oracle_cloud_install.sh
   ```

2. **Make it executable**:
   ```bash
   chmod +x wireguard_oracle_cloud_install.sh
   ```

3. **Run the installation**:
   ```bash
   sudo ./wireguard_oracle_cloud_install.sh
   ```

## What the Script Does

### 1. System Detection
- Detects the operating system (Oracle Linux, Ubuntu, etc.)
- Identifies the appropriate package manager (yum/apt)
- Validates system requirements

### 2. Package Installation
- Updates system packages
- Installs WireGuard and dependencies
- Configures repositories as needed

### 3. WireGuard Setup
- Generates cryptographic keys
- Creates server configuration
- Sets up networking and routing
- Configures IP forwarding

### 4. Firewall Configuration
- Opens WireGuard port (UDP)
- Configures NAT and forwarding rules
- Supports firewalld, ufw, and iptables

### 5. Service Management
- Creates systemd service
- Enables auto-start
- Starts WireGuard service

### 6. Management Tools
- Client management script (`wg-client`)
- Status monitoring script (`wg-status`)
- Configuration templates

## Post-Installation

After successful installation, you'll have access to these management tools:

### Check Status
```bash
wg-status
```

### Add a Client
```bash
wg-client add client_name [ip]
```
Example:
```bash
wg-client add myphone 5
```

### Remove a Client
```bash
wg-client remove client_name
```

### List Clients
```bash
wg-client list
```

### Service Management
```bash
# Start WireGuard
systemctl start wg-quick@wg0

# Stop WireGuard
systemctl stop wg-quick@wg0

# Restart WireGuard
systemctl restart wg-quick@wg0

# Check service status
systemctl status wg-quick@wg0
```

## Client Configuration

### Adding Clients
1. Run the client management script:
   ```bash
   wg-client add client_name
   ```

2. Copy the generated configuration file:
   ```bash
   cp /etc/wireguard/clients/client_name.conf /path/to/client/device
   ```

3. Import the configuration in your WireGuard client application

### Client Configuration Files
Client configurations are stored in `/etc/wireguard/clients/` and include:
- Private key for the client
- Server public key
- Server endpoint (IP and port)
- Allowed IPs and routing

## Security Features

- **Cryptographic Keys**: Automatically generated private/public key pairs
- **Secure Permissions**: Configuration files have restricted access (600)
- **Firewall Rules**: Proper UDP port opening and NAT configuration
- **IP Forwarding**: Secure routing between VPN and internet
- **Client Isolation**: Each client gets a unique IP address

## Network Configuration

The script configures:
- **Server IP**: Automatically detected public IP
- **WireGuard Port**: Random port between 1024-65535
- **Subnet**: 10.0.0.0/24 for VPN clients
- **DNS**: Google DNS (8.8.8.8, 8.8.4.4)

## Troubleshooting

### Common Issues

1. **Script fails with permission error**
   ```bash
   sudo ./wireguard_oracle_cloud_install.sh
   ```

2. **WireGuard service not starting**
   ```bash
   systemctl status wg-quick@wg0
   journalctl -u wg-quick@wg0
   ```

3. **Firewall blocking connections**
   ```bash
   # Check firewall status
   firewall-cmd --list-all  # For firewalld
   ufw status               # For UFW
   iptables -L              # For iptables
   ```

4. **Client cannot connect**
   - Verify server public IP is correct
   - Check WireGuard port is open
   - Ensure client configuration is properly imported

### Logs and Debugging

- **Service logs**: `journalctl -u wg-quick@wg0`
- **WireGuard status**: `wg show wg0`
- **Interface status**: `ip link show wg0`
- **Routing table**: `ip route show`

## File Locations

- **Server Config**: `/etc/wireguard/wg0.conf`
- **Client Configs**: `/etc/wireguard/clients/`
- **Keys**: `/etc/wireguard/privatekey`, `/etc/wireguard/publickey`
- **Management Scripts**: `/usr/local/bin/wg-client`, `/usr/local/bin/wg-status`
- **Installation Summary**: `/etc/wireguard/INSTALLATION_SUMMARY.txt`

## Oracle Cloud Specific Notes

### Security Lists
Ensure your OCI security list allows UDP traffic on the WireGuard port:
1. Go to OCI Console → Networking → Virtual Cloud Networks
2. Select your VCN → Security Lists
3. Add ingress rule: UDP, port range (your WireGuard port), source 0.0.0.0/0

### Instance Configuration
- Recommended: VM.Standard2.1 or higher
- Network: At least 1 Mbps bandwidth
- Storage: 10GB minimum (script uses minimal space)

### Backup
Important files to backup:
```bash
/etc/wireguard/
/usr/local/bin/wg-client
/usr/local/bin/wg-status
```

## Advanced Configuration

### Custom Subnet
To use a different subnet, modify the script before running:
```bash
# Edit the script and change SUBNET variable
SUBNET="192.168.1"  # Instead of "10.0.0"
```

### Custom DNS
Modify client template in `/etc/wireguard/client_template.conf`:
```
DNS = 1.1.1.1, 1.0.0.1  # Cloudflare DNS
```

### Persistent Firewall Rules
For systems using iptables directly:
```bash
# Save current rules
iptables-save > /etc/iptables/rules.v4

# Restore on boot (add to startup scripts)
iptables-restore < /etc/iptables/rules.v4
```

## Contributing

To contribute to this project:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on Oracle Cloud
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
