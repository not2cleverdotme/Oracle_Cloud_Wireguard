# WireGuard Oracle Cloud Automated Installation

**One-Click WireGuard VPN Setup for Oracle Cloud**

This repository provides a complete, automated solution for setting up a WireGuard VPN server on Oracle Cloud Infrastructure (OCI). Perfect for beginners and non-technical users - just run one script and you'll have a fully functional VPN server!

## 🚀 **Quick Start (3 Steps)**

1. **Download the installation script**
2. **Run the script** 
3. **Add your devices to the VPN**

That's it! No technical knowledge required.

## ✨ **Features**

- **🔧 One-Click Installation** - Single script does everything automatically
- **🛡️ Built-in Security** - Automatic firewall configuration and security fixes
- **📱 Easy Device Management** - Simple commands to add phones, laptops, etc.
- **🌐 Multi-Platform Support** - Works on Windows, Mac, Linux, Android, iOS
- **☁️ Oracle Cloud Optimized** - Specifically designed for OCI environments
- **🔍 Auto-Troubleshooting** - Automatically fixes common connectivity issues
- **📊 Status Monitoring** - Easy commands to check if everything is working

## 📋 **What You Need**

- **Oracle Cloud account** (free tier works great!)
- **A computer** to run the installation script
- **Basic command line knowledge** (we'll guide you through it)

**Supported Operating Systems:**
- Oracle Linux ✅
- Ubuntu ✅  
- CentOS ✅
- RHEL ✅

## 🚀 **Quick Start**

### **Step 1: Download the Installation Script**
```bash
wget https://raw.githubusercontent.com/not2cleverdotme/wireguard_oracle_cloud_install.sh
```

### **Step 2: Make it Executable**
```bash
chmod +x wireguard_oracle_cloud_install.sh
```

### **Step 3: Run the Installation**
```bash
sudo ./wireguard_oracle_cloud_install.sh
```

**That's it!** The script will automatically:
- ✅ Install WireGuard
- ✅ Configure security settings
- ✅ Set up firewall rules
- ✅ Fix common connectivity issues
- ✅ Create management tools

**Installation takes about 2-3 minutes.**

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

## 📱 **Adding Your Devices to the VPN**

After installation, you can easily add your devices (phones, laptops, etc.) to the VPN:

### **Add a Device**
```bash
wg-client add myphone
```

**Examples:**
```bash
wg-client add iphone
wg-client add laptop
wg-client add tablet
```

### **Check Your Devices**
```bash
wg-client list
```

### **Remove a Device**
```bash
wg-client remove myphone
```

### **Check if VPN is Working**
```bash
wg-status
```

## 🔧 **Managing Your VPN**

### **Check Status**
```bash
wg-status
```

### **Start/Stop VPN**
```bash
# Start VPN
systemctl start wg-quick@wg0

# Stop VPN  
systemctl stop wg-quick@wg0

# Restart VPN
systemctl restart wg-quick@wg0
```

## 🛠️ **Advanced Tools (Optional)**

These additional scripts help with troubleshooting and advanced configuration:

### **Test Your Installation**
```bash
sudo ./test_wireguard.sh
```

### **Get Oracle Cloud Setup Instructions**
```bash
sudo ./oci_network_setup.sh
```

### **Troubleshoot Issues**
```bash
sudo ./wireguard_troubleshoot.sh
```

### **Fix Common Problems**
```bash
sudo ./wireguard_fix.sh
```

### **Remove VPN (if needed)**
```bash
sudo ./wireguard_uninstall.sh
```

**💡 Tip:** You only need these if something isn't working. The main installation script handles most issues automatically!

## 📱 **Setting Up Your Devices**

### **Step 1: Add Your Device**
```bash
wg-client add myphone
```

### **Step 2: Download the Configuration**
The script will tell you where to find the configuration file. It's usually in:
```bash
/etc/wireguard/clients/myphone.conf
```

### **Step 3: Install WireGuard App**
- **iPhone/iPad**: Download "WireGuard" from App Store
- **Android**: Download "WireGuard" from Google Play
- **Windows**: Download from wireguard.com
- **Mac**: Download from wireguard.com
- **Linux**: Install via package manager

### **Step 4: Import Configuration**
- Open the WireGuard app
- Click "Import" or "+" 
- Select the configuration file you downloaded
- Click "Activate"

**That's it!** Your device is now connected to your VPN.

## 🛡️ **Security Features**

- **🔐 Automatic Encryption** - All traffic is encrypted automatically
- **🔑 Secure Key Generation** - Unique keys for each device
- **🛡️ Built-in Firewall** - Automatic security configuration
- **🌐 Safe Internet Access** - All traffic goes through secure tunnel
- **📱 Device Isolation** - Each device gets its own secure connection

## 🌐 **Network Configuration**

The script automatically configures:
- **🌍 Server Location**: Your Oracle Cloud server location
- **🔢 Port**: Random secure port (changes each installation)
- **📡 Network**: Private network for your devices
- **🔍 DNS**: Fast, secure DNS servers

## 🔧 **Troubleshooting**

### **Common Issues & Quick Fixes**

**❌ "Permission denied" error**
```bash
sudo ./wireguard_oracle_cloud_install.sh
```

**❌ "Cannot add PPA" error (Ubuntu)**
- The script handles this automatically now
- If it still fails, try: `sudo apt install wireguard`

**❌ "Service not starting"**
```bash
systemctl restart wg-quick@wg0
```

**❌ "Can't browse websites" after connecting**
```bash
sudo ./wireguard_fix.sh
```

**❌ "Client can't connect"**
- Check if Oracle Cloud security list is configured
- Run: `sudo ./oci_network_setup.sh`

### **Quick Diagnostic Commands**
```bash
# Check if VPN is working
wg-status

# Test connectivity
ping 8.8.8.8

# Check DNS
nslookup google.com
```

### Logs and Debugging

- **Service logs**: `journalctl -u wg-quick@wg0`
- **WireGuard status**: `wg show wg0`
- **Interface status**: `ip link show wg0`
- **Routing table**: `ip route show`

### **🔍 Advanced Troubleshooting**

**If you're still having issues:**

1. **Run the diagnostic script**:
   ```bash
   sudo ./wireguard_troubleshoot.sh
   ```

2. **Apply automatic fixes**:
   ```bash
   sudo ./wireguard_fix.sh
   ```

3. **Test everything**:
   ```bash
   sudo ./test_wireguard.sh
   ```

**Most common issues are automatically fixed by the installation script now!**

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

## 📝 **Changelog**

### Version 1.2
- **🛡️ Automatic Firewall Fixes** - Built-in fixes for common connectivity issues
- **🔧 Enhanced Installation** - More robust package installation for all OS versions
- **📖 User-Friendly Documentation** - Simplified for non-technical users
- **✅ Better Error Handling** - Automatic detection and fixing of common problems

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
