#!/bin/bash

# WireGuard Oracle Cloud Automated Installation Script
# This script automates the complete WireGuard VPN setup on Oracle Cloud Infrastructure
# Compatible with Oracle Linux, Ubuntu, and CentOS/RHEL systems

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Detect OS and package manager
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        error "Cannot detect OS"
        exit 1
    fi

    case $OS in
        "Oracle Linux Server"|"Red Hat Enterprise Linux"|"CentOS Linux")
            PKG_MANAGER="yum"
            OS_TYPE="rhel"
            ;;
        "Ubuntu"|"Debian GNU/Linux")
            PKG_MANAGER="apt"
            OS_TYPE="debian"
            ;;
        *)
            error "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    log "Detected OS: $OS $VER"
    log "Package manager: $PKG_MANAGER"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    case $PKG_MANAGER in
        "yum")
            yum update -y
            ;;
        "apt")
        apt update && apt upgrade -y
            ;;
    esac
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    case $PKG_MANAGER in
        "yum")
            # Enable EPEL repository for RHEL/CentOS/Oracle Linux
            if [[ $OS_TYPE == "rhel" ]]; then
                yum install -y epel-release
            fi
            
            # Install WireGuard and dependencies
            yum install -y wireguard-tools iptables-services
            ;;
        "apt")
            # Install WireGuard for Ubuntu/Debian with multiple fallback methods
            apt install -y software-properties-common curl
            
            # Method 1: Try to install from universe repository first (most reliable)
            apt update
            if apt install -y wireguard iptables; then
                log "WireGuard installed from universe repository"
            else
                # Method 2: Try PPA (may not be available on all Ubuntu versions)
                if add-apt-repository ppa:wireguard/wireguard -y 2>/dev/null; then
                    apt update
                    apt install -y wireguard iptables
                    log "WireGuard installed from PPA"
                else
                    # Method 3: Install from backports for Debian
                    if command -v lsb_release &> /dev/null; then
                        echo "deb http://deb.debian.org/debian $(lsb_release -cs)-backports main" | tee /etc/apt/sources.list.d/backports.list
                        apt update
                        apt install -y wireguard iptables
                        log "WireGuard installed from backports"
                    else
                        # Method 4: Manual installation from official repository
                        apt install -y dirmngr
                        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC
                        echo "deb http://deb.debian.org/debian $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/wireguard.list
                        apt update
                        apt install -y wireguard iptables
                        log "WireGuard installed from official repository"
                    fi
                fi
            fi
            ;;
    esac
}

# Generate WireGuard keys
generate_keys() {
    log "Generating WireGuard keys..."
    
    # Create WireGuard directory
    mkdir -p /etc/wireguard
    cd /etc/wireguard
    
    # Generate private and public keys
    wg genkey | tee privatekey | wg pubkey > publickey
    
    # Set proper permissions
    chmod 600 privatekey
    chmod 644 publickey
    
    # Read keys into variables
    PRIVATE_KEY=$(cat privatekey)
    PUBLIC_KEY=$(cat publickey)
    
    log "Keys generated successfully"
}

# Get server configuration
get_server_config() {
    log "Configuring WireGuard server..."
    
    # Get server's public IP
    SERVER_IP=$(curl -s ifconfig.me)
    if [[ -z $SERVER_IP ]]; then
        error "Could not determine server public IP"
        exit 1
    fi
    
    # Get server's private IP
    SERVER_PRIVATE_IP=$(ip route get 1 | awk '{print $7;exit}')
    
    # Generate random port for WireGuard
    WG_PORT=$((1024 + RANDOM % 64511))
    
    # Generate random subnet
    SUBNET="10.0.0"
    SERVER_IP_RANGE="$SUBNET.1/24"
    
    log "Server Public IP: $SERVER_IP"
    log "Server Private IP: $SERVER_PRIVATE_IP"
    log "WireGuard Port: $WG_PORT"
    log "Subnet: $SERVER_IP_RANGE"
}

# Create WireGuard server configuration
create_server_config() {
    log "Creating WireGuard server configuration..."
    
    cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $SERVER_IP_RANGE
ListenPort = $WG_PORT
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Enable IP forwarding
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
PostUp = echo 1 > /proc/sys/net/ipv4/conf/all/forwarding
PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward
PostDown = echo 0 > /proc/sys/net/ipv4/conf/all/forwarding
EOF

    chmod 600 /etc/wireguard/wg0.conf
    log "Server configuration created at /etc/wireguard/wg0.conf"
}

# Enable IP forwarding
enable_ip_forwarding() {
    log "Enabling IP forwarding..."
    
    # Enable IP forwarding permanently
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    echo 'net.ipv4.conf.all.forwarding=1' >> /etc/sysctl.conf
    sysctl -p
    
    log "IP forwarding enabled"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    case $PKG_MANAGER in
        "yum")
            # Configure firewalld if available
            if command -v firewall-cmd &> /dev/null; then
                firewall-cmd --permanent --add-port=$WG_PORT/udp
                firewall-cmd --permanent --add-masquerade
                firewall-cmd --reload
                log "Firewalld configured"
            else
                # Configure iptables directly
                iptables -A INPUT -p udp --dport $WG_PORT -j ACCEPT
                iptables -A FORWARD -i wg0 -j ACCEPT
                iptables -A FORWARD -o wg0 -j ACCEPT
                iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                
                # Save iptables rules
                if command -v iptables-save &> /dev/null; then
                    iptables-save > /etc/iptables/rules.v4
                fi
                log "Iptables configured"
            fi
            ;;
        "apt")
            # Configure ufw if available
            if command -v ufw &> /dev/null; then
                ufw allow $WG_PORT/udp
                ufw --force enable
                log "UFW configured"
            else
                # Configure iptables directly
                iptables -A INPUT -p udp --dport $WG_PORT -j ACCEPT
                iptables -A FORWARD -i wg0 -j ACCEPT
                iptables -A FORWARD -o wg0 -j ACCEPT
                iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
                log "Iptables configured"
            fi
            ;;
    esac
}

# Create systemd service
create_service() {
    log "Creating WireGuard systemd service..."
    
    cat > /etc/systemd/system/wg-quick@wg0.service << EOF
[Unit]
Description=WireGuard VPN - wg0 interface
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/wg-quick up wg0
ExecStop=/usr/bin/wg-quick down wg0

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    log "WireGuard service created and started"
}

# Create client configuration template
create_client_template() {
    log "Creating client configuration template..."
    
    cat > /etc/wireguard/client_template.conf << EOF
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = $SUBNET.CLIENT_IP/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $PUBLIC_KEY
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    chmod 600 /etc/wireguard/client_template.conf
    log "Client template created at /etc/wireguard/client_template.conf"
}

# Create client management script
create_client_script() {
    log "Creating client management script..."
    
    cat > /usr/local/bin/wg-client << 'EOF'
#!/bin/bash

# WireGuard Client Management Script
# Usage: wg-client add <client_name> [ip]
# Usage: wg-client remove <client_name>
# Usage: wg-client list

WG_DIR="/etc/wireguard"
CLIENTS_DIR="$WG_DIR/clients"

mkdir -p "$CLIENTS_DIR"

case "$1" in
    "add")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 add <client_name> [ip]"
            exit 1
        fi
        
        CLIENT_NAME="$2"
        CLIENT_IP="${3:-$(($(ls $CLIENTS_DIR/*.conf 2>/dev/null | wc -l) + 2))}"
        
        # Generate client keys
        wg genkey | tee "$CLIENTS_DIR/${CLIENT_NAME}_private.key" | wg pubkey > "$CLIENTS_DIR/${CLIENT_NAME}_public.key"
        
        # Create client config
        cat > "$CLIENTS_DIR/${CLIENT_NAME}.conf" << CLIENTEOF
[Interface]
PrivateKey = $(cat "$CLIENTS_DIR/${CLIENT_NAME}_private.key")
Address = 10.0.0.$CLIENT_IP/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $(cat "$WG_DIR/publickey")
Endpoint = $(curl -s ifconfig.me):$(grep ListenPort "$WG_DIR/wg0.conf" | cut -d'=' -f2 | tr -d ' ')
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CLIENTEOF
        
        # Add peer to server config
        cat >> "$WG_DIR/wg0.conf" << PEEREOF

# Client: $CLIENT_NAME
[Peer]
PublicKey = $(cat "$CLIENTS_DIR/${CLIENT_NAME}_public.key")
AllowedIPs = 10.0.0.$CLIENT_IP/32
PEEREOF
        
        # Reload WireGuard
        wg syncconf wg0 <(wg-quick strip wg0)
        
        echo "Client '$CLIENT_NAME' added with IP 10.0.0.$CLIENT_IP"
        echo "Configuration saved to: $CLIENTS_DIR/${CLIENT_NAME}.conf"
        ;;
        
    "remove")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 remove <client_name>"
            exit 1
        fi
        
        CLIENT_NAME="$2"
        
        # Remove from server config
        sed -i "/# Client: $CLIENT_NAME/,/^$/d" "$WG_DIR/wg0.conf"
        
        # Remove client files
        rm -f "$CLIENTS_DIR/${CLIENT_NAME}"*
        
        # Reload WireGuard
        wg syncconf wg0 <(wg-quick strip wg0)
        
        echo "Client '$CLIENT_NAME' removed"
        ;;
        
    "list")
        echo "Connected clients:"
        wg show wg0 peers
        echo ""
        echo "Available client configs:"
        ls -la "$CLIENTS_DIR"/*.conf 2>/dev/null || echo "No client configs found"
        ;;
        
    *)
        echo "Usage: $0 {add|remove|list}"
        echo "  add <client_name> [ip]    - Add a new client"
        echo "  remove <client_name>       - Remove a client"
        echo "  list                       - List clients"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/wg-client
    log "Client management script created at /usr/local/bin/wg-client"
}

# Create status check script
create_status_script() {
    log "Creating status check script..."
    
    cat > /usr/local/bin/wg-status << 'EOF'
#!/bin/bash

echo "=== WireGuard Status ==="
echo "Service Status:"
systemctl status wg-quick@wg0 --no-pager -l

echo ""
echo "Interface Status:"
ip link show wg0 2>/dev/null || echo "wg0 interface not found"

echo ""
echo "Connected Peers:"
wg show wg0 2>/dev/null || echo "WireGuard not running"

echo ""
echo "Firewall Rules:"
iptables -L FORWARD -n
iptables -t nat -L POSTROUTING -n

echo ""
echo "Routing Table:"
ip route show
EOF

    chmod +x /usr/local/bin/wg-status
    log "Status script created at /usr/local/bin/wg-status"
}

# Create installation summary
create_summary() {
    log "Creating installation summary..."
    
    cat > /etc/wireguard/INSTALLATION_SUMMARY.txt << EOF
WireGuard Installation Summary
=============================

Installation Date: $(date)
Server Public IP: $SERVER_IP
WireGuard Port: $WG_PORT
Subnet: $SERVER_IP_RANGE

Configuration Files:
- Server Config: /etc/wireguard/wg0.conf
- Client Template: /etc/wireguard/client_template.conf
- Client Directory: /etc/wireguard/clients/

Management Commands:
- Add Client: wg-client add <client_name> [ip]
- Remove Client: wg-client remove <client_name>
- List Clients: wg-client list
- Check Status: wg-status

Service Management:
- Start: systemctl start wg-quick@wg0
- Stop: systemctl stop wg-quick@wg0
- Restart: systemctl restart wg-quick@wg0
- Status: systemctl status wg-quick@wg0

Firewall Port: $WG_PORT/udp

To add a client:
1. Run: wg-client add <client_name>
2. Copy the generated .conf file to the client device
3. Import the configuration in WireGuard client

Server Public Key: $PUBLIC_KEY
EOF

    log "Installation summary saved to /etc/wireguard/INSTALLATION_SUMMARY.txt"
}

# Main installation function
main() {
    log "Starting WireGuard installation on Oracle Cloud..."
    
    check_root
    detect_os
    update_system
    install_packages
    generate_keys
    get_server_config
    create_server_config
    enable_ip_forwarding
    configure_firewall
    create_service
    create_client_template
    create_client_script
    create_status_script
    create_summary
    
    log "WireGuard installation completed successfully!"
    log ""
    log "Next steps:"
    log "1. Check status: wg-status"
    log "2. Add a client: wg-client add <client_name>"
    log "3. View installation summary: cat /etc/wireguard/INSTALLATION_SUMMARY.txt"
    log ""
    log "Server is ready to accept WireGuard connections on port $WG_PORT"
}

# Run main function
main "$@" 