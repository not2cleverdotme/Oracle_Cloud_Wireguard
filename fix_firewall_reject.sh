#!/bin/bash

# Fix Firewall REJECT Rule Script
# This script removes the problematic REJECT rule that blocks WireGuard traffic

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

# Show current firewall rules
show_current_rules() {
    log "Current FORWARD chain rules:"
    iptables -L FORWARD -n --line-numbers
    echo ""
    
    log "Current INPUT chain rules:"
    iptables -L INPUT -n --line-numbers
    echo ""
}

# Fix the REJECT rule issue
fix_reject_rule() {
    log "Fixing firewall REJECT rule..."
    
    # Check if REJECT rule exists
    if iptables -L FORWARD -n | grep -q "REJECT.*reject-with icmp-host-prohibited"; then
        log "Found problematic REJECT rule, removing it..."
        
        # Find the line number of the REJECT rule
        local line_number=$(iptables -L FORWARD -n --line-numbers | grep "REJECT.*reject-with icmp-host-prohibited" | awk '{print $1}')
        
        if [[ -n "$line_number" ]]; then
            iptables -D FORWARD "$line_number"
            log "✓ Removed REJECT rule from line $line_number"
        else
            warn "⚠ Could not determine line number for REJECT rule"
        fi
    else
        log "✓ No problematic REJECT rule found"
    fi
    
    # Also check INPUT chain for similar issues
    if iptables -L INPUT -n | grep -q "REJECT.*reject-with icmp-host-prohibited"; then
        log "Found REJECT rule in INPUT chain, removing it..."
        
        local line_number=$(iptables -L INPUT -n --line-numbers | grep "REJECT.*reject-with icmp-host-prohibited" | awk '{print $1}')
        
        if [[ -n "$line_number" ]]; then
            iptables -D INPUT "$line_number"
            log "✓ Removed REJECT rule from INPUT chain line $line_number"
        fi
    fi
}

# Ensure proper WireGuard rules are in place
ensure_wireguard_rules() {
    log "Ensuring proper WireGuard firewall rules..."
    
    # Get WireGuard port
    local wg_port=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    
    if [[ -z "$wg_port" ]]; then
        error "Could not determine WireGuard port"
        return 1
    fi
    
    log "WireGuard port: $wg_port"
    
    # Remove any existing WireGuard rules to avoid duplicates
    iptables -D INPUT -p udp --dport "$wg_port" -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null || true
    
    # Add proper WireGuard rules
    iptables -A INPUT -p udp --dport "$wg_port" -j ACCEPT
    iptables -A FORWARD -i wg0 -j ACCEPT
    iptables -A FORWARD -o wg0 -j ACCEPT
    
    # Add NAT rules for both eth0 and ens3
    iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
    iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE 2>/dev/null || true
    
    if ip link show eth0 &>/dev/null; then
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        log "✓ Added NAT rule for eth0"
    fi
    
    if ip link show ens3 &>/dev/null; then
        iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
        log "✓ Added NAT rule for ens3"
    fi
    
    log "✓ WireGuard firewall rules updated"
}

# Test connectivity after fix
test_connectivity() {
    log "Testing connectivity after firewall fix..."
    
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

# Show final firewall rules
show_final_rules() {
    log "Final FORWARD chain rules:"
    iptables -L FORWARD -n --line-numbers
    echo ""
    
    log "Final INPUT chain rules:"
    iptables -L INPUT -n --line-numbers
    echo ""
    
    log "NAT rules:"
    iptables -t nat -L POSTROUTING -n
    echo ""
}

# Main function
main() {
    log "Firewall REJECT Rule Fix Script"
    echo ""
    
    check_root
    
    log "Current firewall state:"
    show_current_rules
    
    # Apply fixes
    fix_reject_rule
    ensure_wireguard_rules
    
    echo ""
    log "Firewall rules updated. Testing connectivity..."
    
    # Test connectivity
    test_connectivity
    
    echo ""
    log "Final firewall state:"
    show_final_rules
    
    echo ""
    log "Firewall fix completed!"
    log "If connectivity is still poor, restart WireGuard:"
    log "  systemctl restart wg-quick@wg0"
}

# Run main function
main "$@" 