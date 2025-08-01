#!/bin/bash

# WireGuard Troubleshooting Script
# This script helps diagnose and fix common WireGuard connectivity issues

set -e

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

# Check WireGuard installation
check_wireguard_installation() {
    if [[ ! -f /etc/wireguard/wg0.conf ]]; then
        error "WireGuard is not installed"
        exit 1
    fi
    
    if ! systemctl is-active --quiet wg-quick@wg0; then
        warn "WireGuard service is not running"
        systemctl start wg-quick@wg0
        log "WireGuard service started"
    fi
}

# Test DNS resolution
test_dns() {
    log "Testing DNS resolution..."
    
    # Test multiple DNS servers
    local dns_servers=("8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1")
    
    for dns in "${dns_servers[@]}"; do
        if nslookup google.com "$dns" &>/dev/null; then
            log "✓ DNS server $dns is working"
        else
            warn "⚠ DNS server $dns is not responding"
        fi
    done
    
    # Test local DNS resolution
    if nslookup google.com &>/dev/null; then
        log "✓ Local DNS resolution is working"
    else
        error "✗ Local DNS resolution is failing"
    fi
}

# Check IP forwarding
check_ip_forwarding() {
    log "Checking IP forwarding..."
    
    if [[ $(cat /proc/sys/net/ipv4/ip_forward) == "1" ]]; then
        log "✓ IP forwarding is enabled"
    else
        error "✗ IP forwarding is disabled"
        log "Enabling IP forwarding..."
        echo 1 > /proc/sys/net/ipv4/ip_forward
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
        sysctl -p
        log "IP forwarding enabled"
    fi
}

# Check firewall rules
check_firewall() {
    log "Checking firewall rules..."
    
    # Get WireGuard port
    local wg_port=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    
    if [[ -n "$wg_port" ]]; then
        # Check if port is open
        if netstat -tuln 2>/dev/null | grep -q ":$wg_port "; then
            log "✓ WireGuard port $wg_port is listening"
        else
            error "✗ WireGuard port $wg_port is not listening"
        fi
        
        # Check iptables rules
        if iptables -L INPUT -n | grep -q "udp.*dpt:$wg_port"; then
            log "✓ Firewall rule for port $wg_port exists"
        else
            warn "⚠ Firewall rule for port $wg_port not found"
        fi
        
        # Check forwarding rules
        if iptables -L FORWARD -n | grep -q "wg0"; then
            log "✓ WireGuard forwarding rules exist"
        else
            warn "⚠ WireGuard forwarding rules missing"
        fi
    fi
}

# Check routing table
check_routing() {
    log "Checking routing table..."
    
    # Check if WireGuard interface exists
    if ip link show wg0 &>/dev/null; then
        log "✓ WireGuard interface exists"
        
        # Check routing for WireGuard subnet
        if ip route show | grep -q "10.0.0.0/24"; then
            log "✓ WireGuard subnet routing exists"
        else
            warn "⚠ WireGuard subnet routing missing"
        fi
    else
        error "✗ WireGuard interface not found"
    fi
    
    # Show current routing table
    log "Current routing table:"
    ip route show
}

# Check WireGuard peers
check_peers() {
    log "Checking WireGuard peers..."
    
    if command -v wg &>/dev/null; then
        local peer_count=$(wg show wg0 peers 2>/dev/null | wc -l)
        log "Found $peer_count connected peers"
        
        if [[ $peer_count -gt 0 ]]; then
            log "Connected peers:"
            wg show wg0 peers 2>/dev/null || echo "No peers found"
        fi
    else
        error "✗ WireGuard command not found"
    fi
}

# Test connectivity
test_connectivity() {
    log "Testing connectivity..."
    
    # Test internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log "✓ Internet connectivity is working"
    else
        error "✗ Internet connectivity is down"
    fi
    
    # Test DNS resolution
    if nslookup google.com &>/dev/null; then
        log "✓ DNS resolution is working"
    else
        error "✗ DNS resolution is failing"
    fi
    
    # Test HTTP connectivity
    if curl -s --connect-timeout 5 https://www.google.com &>/dev/null; then
        log "✓ HTTP connectivity is working"
    else
        error "✗ HTTP connectivity is failing"
    fi
}

# Fix common issues
fix_common_issues() {
    log "Attempting to fix common issues..."
    
    # Fix 1: Enable IP forwarding
    if [[ $(cat /proc/sys/net/ipv4/ip_forward) != "1" ]]; then
        log "Fixing IP forwarding..."
        echo 1 > /proc/sys/net/ipv4/ip_forward
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
        sysctl -p
    fi
    
    # Fix 2: Restart WireGuard service
    log "Restarting WireGuard service..."
    systemctl restart wg-quick@wg0
    
    # Fix 3: Add missing firewall rules
    local wg_port=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    if [[ -n "$wg_port" ]]; then
        log "Adding firewall rules for port $wg_port..."
        iptables -A INPUT -p udp --dport "$wg_port" -j ACCEPT 2>/dev/null || true
        iptables -A FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
        iptables -A FORWARD -o wg0 -j ACCEPT 2>/dev/null || true
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
    fi
    
    log "Common fixes applied"
}

# Generate client troubleshooting guide
generate_client_guide() {
    cat << 'EOF'

===========================================
   CLIENT-SIDE TROUBLESHOOTING GUIDE
===========================================

If you can't browse websites after connecting to WireGuard:

1. **Check DNS Settings**:
   - Ensure your client config has DNS servers:
     DNS = 8.8.8.8, 8.8.4.4, 1.1.1.1

2. **Test DNS Resolution**:
   - Try: nslookup google.com
   - Try: ping 8.8.8.8

3. **Check AllowedIPs**:
   - Should be: AllowedIPs = 0.0.0.0/0
   - This routes all traffic through VPN

4. **Client-Specific Fixes**:

   **Windows:**
   - Run as Administrator
   - Check "Block untunneled traffic" in advanced settings
   - Disable IPv6 in network adapter settings

   **macOS:**
   - Check "Block all connections to non-VPN traffic"
   - Try different DNS servers

   **Linux:**
   - Check routing table: ip route show
   - Verify DNS: cat /etc/resolv.conf

   **Android:**
   - Enable "Block connections without VPN"
   - Check "Use custom DNS"

   **iOS:**
   - Enable "Block all connections to non-VPN traffic"

5. **Alternative DNS Servers**:
   Try these in your client config:
   - Cloudflare: 1.1.1.1, 1.0.0.1
   - Google: 8.8.8.8, 8.8.4.4
   - OpenDNS: 208.67.222.222, 208.67.220.220

6. **Test Connection**:
   - ping 8.8.8.8
   - nslookup google.com
   - curl https://www.google.com

EOF
}

# Show server configuration
show_server_config() {
    log "Server Configuration:"
    echo ""
    
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        echo "WireGuard Config:"
        cat /etc/wireguard/wg0.conf
        echo ""
    fi
    
    echo "Network Interfaces:"
    ip addr show
    echo ""
    
    echo "Routing Table:"
    ip route show
    echo ""
    
    echo "Firewall Rules:"
    iptables -L INPUT -n
    iptables -L FORWARD -n
    iptables -t nat -L POSTROUTING -n
}

# Main function
main() {
    log "WireGuard Troubleshooting Script"
    echo ""
    
    check_root
    check_wireguard_installation
    
    echo "=== DIAGNOSTIC TESTS ==="
    test_dns
    check_ip_forwarding
    check_firewall
    check_routing
    check_peers
    test_connectivity
    
    echo ""
    echo "=== SERVER STATUS ==="
    show_server_config
    
    echo ""
    echo "=== CLIENT TROUBLESHOOTING ==="
    generate_client_guide
    
    echo ""
    log "Troubleshooting complete!"
    log "If issues persist, check the client-side troubleshooting guide above"
}

# Run main function
main "$@" 