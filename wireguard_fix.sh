#!/bin/bash

# WireGuard Fix Script
# This script fixes the specific issues found in the troubleshooting output

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

# Fix WireGuard service
fix_wireguard_service() {
    log "Fixing WireGuard service..."
    
    # Get WireGuard port
    local wg_port=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    
    if [[ -z "$wg_port" ]]; then
        error "Could not determine WireGuard port"
        return 1
    fi
    
    log "WireGuard port: $wg_port"
    
    # Stop WireGuard service
    systemctl stop wg-quick@wg0 2>/dev/null || true
    
    # Wait a moment
    sleep 2
    
    # Start WireGuard service
    systemctl start wg-quick@wg0
    
    # Check if service started successfully
    if systemctl is-active --quiet wg-quick@wg0; then
        log "✓ WireGuard service started successfully"
    else
        error "✗ WireGuard service failed to start"
        systemctl status wg-quick@wg0
        return 1
    fi
    
    # Check if port is listening
    sleep 3
    if netstat -tuln 2>/dev/null | grep -q ":$wg_port "; then
        log "✓ WireGuard port $wg_port is now listening"
    else
        warn "⚠ WireGuard port $wg_port is still not listening"
    fi
}

# Fix firewall rules
fix_firewall_rules() {
    log "Fixing firewall rules..."
    
    # Get WireGuard port
    local wg_port=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    
    if [[ -z "$wg_port" ]]; then
        error "Could not determine WireGuard port"
        return 1
    fi
    
    # Remove existing rules to avoid duplicates
    iptables -D INPUT -p udp --dport "$wg_port" -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
    iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE 2>/dev/null || true
    
    # Add correct rules
    iptables -A INPUT -p udp --dport "$wg_port" -j ACCEPT
    iptables -A FORWARD -i wg0 -j ACCEPT
    iptables -A FORWARD -o wg0 -j ACCEPT
    
    # Try both eth0 and ens3 for NAT (ens3 is common on Oracle Cloud)
    if ip link show eth0 &>/dev/null; then
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        log "✓ Added NAT rule for eth0"
    fi
    
    if ip link show ens3 &>/dev/null; then
        iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
        log "✓ Added NAT rule for ens3"
    fi
    
    log "✓ Firewall rules updated"
}

# Fix DNS resolution
fix_dns_resolution() {
    log "Fixing DNS resolution..."
    
    # Test different DNS servers
    local dns_servers=("8.8.8.8" "8.8.4.4" "1.1.1.1" "1.0.0.1" "208.67.222.222" "9.9.9.9")
    
    for dns in "${dns_servers[@]}"; do
        if nslookup google.com "$dns" &>/dev/null; then
            log "✓ DNS server $dns is working"
            # Use this working DNS server
            echo "nameserver $dns" > /etc/resolv.conf
            log "✓ Set $dns as primary DNS"
            return 0
        fi
    done
    
    warn "⚠ No external DNS servers are responding"
    warn "This might be a network connectivity issue"
}

# Fix routing issues
fix_routing() {
    log "Fixing routing issues..."
    
    # Check if there are conflicting default routes
    local default_routes=$(ip route show | grep "default" | wc -l)
    
    if [[ $default_routes -gt 1 ]]; then
        warn "⚠ Multiple default routes detected"
        log "Current routing table:"
        ip route show
        
        # Remove duplicate default routes, keep the one with metric 100
        ip route del default dev ens3 2>/dev/null || true
        ip route del default via 10.0.0.1 dev ens3 2>/dev/null || true
        
        # Add single default route
        ip route add default via 10.0.0.1 dev ens3 metric 100
        
        log "✓ Fixed routing table"
    fi
}

# Test connectivity after fixes
test_connectivity() {
    log "Testing connectivity after fixes..."
    
    # Test DNS
    if nslookup google.com &>/dev/null; then
        log "✓ DNS resolution is working"
    else
        warn "⚠ DNS resolution still failing"
    fi
    
    # Test ping
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log "✓ Internet connectivity is working"
    else
        warn "⚠ Internet connectivity still down"
    fi
    
    # Test HTTP
    if curl -s --connect-timeout 5 https://www.google.com &>/dev/null; then
        log "✓ HTTP connectivity is working"
    else
        warn "⚠ HTTP connectivity failing"
    fi
}

# Update client configurations with better DNS
update_client_configs() {
    log "Updating client configurations with better DNS..."
    
    if [[ -d /etc/wireguard/clients ]]; then
        for config in /etc/wireguard/clients/*.conf; do
            if [[ -f "$config" ]]; then
                # Backup original
                cp "$config" "$config.backup"
                
                # Update DNS line with multiple servers
                sed -i 's/DNS = .*/DNS = 8.8.8.8, 8.8.4.4, 1.1.1.1, 1.0.0.1/' "$config"
                
                log "✓ Updated DNS in $(basename "$config")"
            fi
        done
    fi
}

# Show current status
show_status() {
    log "Current Status:"
    echo ""
    
    echo "WireGuard Service:"
    systemctl status wg-quick@wg0 --no-pager -l
    echo ""
    
    echo "Listening Ports:"
    netstat -tuln | grep -E ":(22|80|443|7910) " || echo "No relevant ports found"
    echo ""
    
    echo "Firewall Rules:"
    iptables -L INPUT -n | grep -E "(22|7910)" || echo "No relevant INPUT rules"
    iptables -L FORWARD -n | grep wg0 || echo "No FORWARD rules for wg0"
    echo ""
    
    echo "Routing Table:"
    ip route show
    echo ""
    
    echo "DNS Configuration:"
    cat /etc/resolv.conf
    echo ""
}

# Main function
main() {
    log "WireGuard Fix Script"
    echo ""
    
    check_root
    
    # Apply fixes
    fix_wireguard_service
    fix_firewall_rules
    fix_dns_resolution
    fix_routing
    update_client_configs
    
    echo ""
    log "Applying fixes..."
    
    # Restart WireGuard to apply all changes
    systemctl restart wg-quick@wg0
    
    # Wait for service to stabilize
    sleep 5
    
    # Test connectivity
    test_connectivity
    
    echo ""
    show_status
    
    echo ""
    log "Fix script completed!"
    log "If issues persist, check the troubleshooting guide"
}

# Run main function
main "$@" 