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

1. **Download the scripts**:
   ```bash
   wget https://raw.githubusercontent.com/not2cleverdotme/wireguard_oracle_cloud_install.sh
   wget https://raw.githubusercontent.com/not2cleverdotme/wireguard_uninstall.sh
   wget https://raw.githubusercontent.com/not2cleverdotme/test_wireguard.sh
   wget https://raw.githubusercontent.com/not2cleverdotme/oci_network_setup.sh
   wget https://raw.githubusercontent.com/not2cleverdotme/wireguard_troubleshoot.sh
   wget https://raw.githubusercontent.com/not2cleverdotme/wireguard_fix.sh
   ```

2. **Make them executable**:
   ```bash
   chmod +x wireguard_*.sh oci_network_setup.sh
   ```

3. **Run the installation**:
   ```bash
   sudo ./wireguard_oracle_cloud_install.sh
   ```

## Scripts Overview

### **Main Installation Script** (`wireguard_oracle_cloud_install.sh`)
Complete automated WireGuard installation with:

#### 1. System Detection
- Detects the operating system (Oracle Linux, Ubuntu, etc.)
- Identifies the appropriate package manager (yum/apt)
- Validates system requirements

#### 2. Package Installation
- Updates system packages
- Installs WireGuard and dependencies
- Configures repositories as needed

#### 3. WireGuard Setup
- Generates cryptographic keys
- Creates server configuration
- Sets up networking and routing
- Configures IP forwarding

#### 4. Firewall Configuration
- Opens WireGuard port (UDP)
- Configures NAT and forwarding rules
- Supports firewalld, ufw, and iptables

#### 5. Service Management
- Creates systemd service
- Enables auto-start
- Starts WireGuard service

#### 6. Management Tools
- Client management script (`wg-client`)
- Status monitoring script (`wg-status`)
- Configuration templates

### **Uninstall Script** (`wireguard_uninstall.sh`)
Safely removes WireGuard installation:
- Stops and removes WireGuard service
- Cleans up firewall rules
- Removes configuration files (with backup)
- Restores system settings
- Confirmation prompts for safety

### **Test Script** (`test_wireguard.sh`)
Validates installation and connectivity:
- Tests service status, interface, configuration
- Checks firewall rules and IP forwarding
- Verifies management scripts
- Shows system information and connectivity
- Provides detailed test results

### **OCI Network Setup Helper** (`oci_network_setup.sh`)
Configures Oracle Cloud Security Lists:
- Detects WireGuard port and server IP
- Generates OCI security list configuration
- Provides Terraform configuration
- Shows step-by-step setup instructions
- Includes testing and troubleshooting tips

### **Troubleshooting Script** (`wireguard_troubleshoot.sh`)
Comprehensive diagnostic tool:
- Tests DNS resolution with multiple servers
- Checks IP forwarding and firewall rules
- Validates routing and peer connections
- Tests connectivity (ping, DNS, HTTP)
- Provides client-side troubleshooting guide
- Shows detailed server configuration

### **Fix Script** (`wireguard_fix.sh`)
Automated fix for common issues:
- Restarts WireGuard service
- Adds missing firewall rules
- Fixes DNS resolution issues
- Cleans up routing conflicts
- Updates client configurations
- Tests connectivity after fixes

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

## Additional Scripts Usage

### **Test Installation**
```bash
# Run comprehensive tests
sudo ./test_wireguard.sh
```

### **Configure OCI Security Lists**
```bash
# Get OCI configuration instructions
sudo ./oci_network_setup.sh
```

### **Troubleshoot Issues**
```bash
# Run diagnostics
sudo ./wireguard_troubleshoot.sh
```

### **Fix Common Problems**
```bash
# Apply automated fixes
sudo ./wireguard_fix.sh
```

### **Uninstall WireGuard**
```bash
# Safely remove installation
sudo ./wireguard_uninstall.sh
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

2. **PPA Error on Ubuntu** (Cannot add PPA: 'ppa:~wireguard/ubuntu/wireguard')
   
   This error occurs when the WireGuard PPA is not available for your Ubuntu version. The script now handles this automatically by:
   - First trying the universe repository (most reliable)
   - Falling back to PPA if available
   - Using backports for Debian systems
   - Manual repository setup as last resort
   
   If you still encounter issues, you can manually install WireGuard:
   ```bash
   # For Ubuntu 20.04+
   sudo apt update
   sudo apt install wireguard
   
   # For older Ubuntu versions
   sudo apt install software-properties-common
   sudo add-apt-repository ppa:wireguard/wireguard
   sudo apt update
   sudo apt install wireguard
   ```

3. **WireGuard service not starting**
   ```bash
   systemctl status wg-quick@wg0
   journalctl -u wg-quick@wg0
   ```

4. **Firewall blocking connections**
   ```bash
   # Check firewall status
   firewall-cmd --list-all  # For firewalld
   ufw status               # For UFW
   iptables -L              # For iptables
   ```

5. **Client cannot connect**
   - Verify server public IP is correct
   - Check WireGuard port is open
   - Ensure client configuration is properly imported

### Logs and Debugging

- **Service logs**: `journalctl -u wg-quick@wg0`
- **WireGuard status**: `wg show wg0`
- **Interface status**: `ip link show wg0`
- **Routing table**: `ip route show`

### Troubleshooting Connectivity Issues

**If you can't browse websites after connecting to WireGuard:**

1. **Run the troubleshooting script**:
   ```bash
   sudo ./wireguard_troubleshoot.sh
   ```

2. **Apply automated fixes**:
   ```bash
   sudo ./wireguard_fix.sh
   ```

3. **Common fixes**:
   - **DNS Issues**: Ensure client config has multiple DNS servers
   - **IP Forwarding**: Check if enabled on server
   - **Firewall Rules**: Verify WireGuard port is open
   - **Routing**: Ensure traffic is routed through VPN

4. **Client-side checks**:
   - Test DNS: `nslookup google.com`
   - Test connectivity: `ping 8.8.8.8`
   - Check routing: `ip route show`

5. **Alternative DNS servers** to try in client config:
   ```
   DNS = 8.8.8.8, 8.8.4.4, 1.1.1.1, 1.0.0.1
   ```

6. **Quick diagnostic workflow**:
   ```bash
   # Step 1: Run diagnostics
   sudo ./wireguard_troubleshoot.sh
   
   # Step 2: Apply fixes
   sudo ./wireguard_fix.sh
   
   # Step 3: Test again
   sudo ./test_wireguard.sh
   ```

## File Locations

- **Server Config**: `/etc/wireguard/wg0.conf`
- **Client Configs**: `/etc/wireguard/clients/`
- **Keys**: `/etc/wireguard/privatekey`, `/etc/wireguard/publickey`
- **Management Scripts**: `/usr/local/bin/wg-client`, `/usr/local/bin/wg-status`
- **Installation Summary**: `/etc/wireguard/INSTALLATION_SUMMARY.txt`

## Script Files

- **Main Installation**: `wireguard_oracle_cloud_install.sh`
- **Uninstall**: `wireguard_uninstall.sh`
- **Testing**: `test_wireguard.sh`
- **OCI Setup**: `oci_network_setup.sh`
- **Troubleshooting**: `wireguard_troubleshoot.sh`
- **Fix Script**: `wireguard_fix.sh`

## Oracle Cloud Specific Notes

### Security Lists Configuration

**Required Ports to Open:**

1. **WireGuard UDP Port** (randomly assigned, e.g., 51820)
   - Protocol: UDP
   - Port: Your specific WireGuard port
   - Source: 0.0.0.0/0

2. **SSH Access** (TCP 22)
   - Protocol: TCP
   - Port: 22
   - Source: 0.0.0.0/0 (or your IP for security)

3. **Optional Web Services**
   - HTTP: TCP 80
   - HTTPS: TCP 443

**Quick Setup:**

Use the provided helper script to get your exact configuration:
```bash
./oci_network_setup.sh
```

**Manual Configuration:**

1. Find your WireGuard port:
   ```bash
   grep "ListenPort" /etc/wireguard/wg0.conf
   ```

2. Go to OCI Console → Networking → Virtual Cloud Networks
3. Select your VCN → Security Lists
4. Add ingress rules:

| Source | Protocol | Source Port Range | Destination Port | Description |
|--------|----------|-------------------|------------------|-------------|
| 0.0.0.0/0 | UDP | All | `[YOUR_WG_PORT]` | WireGuard VPN |
| 0.0.0.0/0 | TCP | All | 22 | SSH Access |

**Security Best Practices:**

For enhanced security, restrict access to your specific IP:
```
Source: YOUR_IP/32 (instead of 0.0.0.0/0)
```

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

## Support

For issues and questions:
- Check the troubleshooting section
- Review logs and status output
- Ensure Oracle Cloud security lists are properly configured
- Verify network connectivity and firewall rules
- Use the provided troubleshooting and fix scripts

## Changelog

### Version 1.1
- Added comprehensive troubleshooting script (`wireguard_troubleshoot.sh`)
- Added automated fix script for common issues (`wireguard_fix.sh`)
- Added OCI network setup helper (`oci_network_setup.sh`)
- Added uninstall script with backup functionality (`wireguard_uninstall.sh`)
- Added test script for validation (`test_wireguard.sh`)
- Improved DNS configuration with multiple servers
- Enhanced error handling and logging
- Added comprehensive documentation

### Version 1.0
- Initial release
- Multi-OS support
- Automated installation
- Client management tools
- Oracle Cloud optimization
