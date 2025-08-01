#!/bin/bash

# WireGuard Installation Test Script
# This script validates the WireGuard installation and tests connectivity

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

# Test WireGuard service
test_service() {
    log "Testing WireGuard service..."
    
    if systemctl is-active --quiet wg-quick@wg0; then
        log "✓ WireGuard service is running"
        return 0
    else
        error "✗ WireGuard service is not running"
        return 1
    fi
}

# Test WireGuard interface
test_interface() {
    log "Testing WireGuard interface..."
    
    if ip link show wg0 &>/dev/null; then
        log "✓ WireGuard interface (wg0) exists"
        
        # Check interface status
        if ip link show wg0 | grep -q "UP"; then
            log "✓ WireGuard interface is UP"
        else
            warn "⚠ WireGuard interface is DOWN"
        fi
        
        return 0
    else
        error "✗ WireGuard interface (wg0) not found"
        return 1
    fi
}

# Test WireGuard configuration
test_config() {
    log "Testing WireGuard configuration..."
    
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        log "✓ WireGuard configuration file exists"
        
        # Check if config is valid
        if wg-quick strip wg0 &>/dev/null; then
            log "✓ WireGuard configuration is valid"
        else
            warn "⚠ WireGuard configuration may have issues"
        fi
        
        return 0
    else
        error "✗ WireGuard configuration file not found"
        return 1
    fi
}

# Test WireGuard keys
test_keys() {
    log "Testing WireGuard keys..."
    
    if [[ -f /etc/wireguard/privatekey ]] && [[ -f /etc/wireguard/publickey ]]; then
        log "✓ WireGuard keys exist"
        
        # Check key permissions
        if [[ $(stat -c %a /etc/wireguard/privatekey 2>/dev/null) == "600" ]]; then
            log "✓ Private key has correct permissions (600)"
        else
            warn "⚠ Private key permissions may be incorrect"
        fi
        
        return 0
    else
        error "✗ WireGuard keys not found"
        return 1
    fi
}

# Test firewall configuration
test_firewall() {
    log "Testing firewall configuration..."
    
    # Get WireGuard port
    WG_PORT=""
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        WG_PORT=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    fi
    
    if [[ -n "$WG_PORT" ]]; then
        log "WireGuard port: $WG_PORT"
        
        # Test if port is open
        if netstat -tuln 2>/dev/null | grep -q ":$WG_PORT "; then
            log "✓ WireGuard port $WG_PORT is listening"
        else
            warn "⚠ WireGuard port $WG_PORT is not listening"
        fi
        
        # Check iptables rules
        if iptables -L INPUT -n | grep -q "udp.*dpt:$WG_PORT"; then
            log "✓ Firewall rule for port $WG_PORT exists"
        else
            warn "⚠ Firewall rule for port $WG_PORT not found"
        fi
        
        return 0
    else
        error "✗ Could not determine WireGuard port"
        return 1
    fi
}

# Test IP forwarding
test_ip_forwarding() {
    log "Testing IP forwarding..."
    
    if [[ $(cat /proc/sys/net/ipv4/ip_forward) == "1" ]]; then
        log "✓ IP forwarding is enabled"
        return 0
    else
        error "✗ IP forwarding is disabled"
        return 1
    fi
}

# Test management scripts
test_scripts() {
    log "Testing management scripts..."
    
    local scripts_found=0
    
    if [[ -f /usr/local/bin/wg-client ]]; then
        log "✓ Client management script exists"
        scripts_found=$((scripts_found + 1))
    else
        error "✗ Client management script not found"
    fi
    
    if [[ -f /usr/local/bin/wg-status ]]; then
        log "✓ Status script exists"
        scripts_found=$((scripts_found + 1))
    else
        error "✗ Status script not found"
    fi
    
    if [[ $scripts_found -eq 2 ]]; then
        return 0
    else
        return 1
    fi
}

# Test WireGuard peers
test_peers() {
    log "Testing WireGuard peers..."
    
    if command -v wg &>/dev/null; then
        local peer_count=$(wg show wg0 peers 2>/dev/null | wc -l)
        log "Found $peer_count connected peers"
        
        if [[ $peer_count -gt 0 ]]; then
            log "Connected peers:"
            wg show wg0 peers 2>/dev/null || echo "No peers found"
        fi
        
        return 0
    else
        error "✗ WireGuard command not found"
        return 1
    fi
}

# Test network connectivity
test_connectivity() {
    log "Testing network connectivity..."
    
    # Test internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log "✓ Internet connectivity is working"
    else
        warn "⚠ Internet connectivity may be down"
    fi
    
    # Test DNS resolution
    if nslookup google.com &>/dev/null; then
        log "✓ DNS resolution is working"
    else
        warn "⚠ DNS resolution may be down"
    fi
}

# Test client configuration directory
test_client_dir() {
    log "Testing client configuration directory..."
    
    if [[ -d /etc/wireguard/clients ]]; then
        log "✓ Client configuration directory exists"
        
        local client_count=$(ls /etc/wireguard/clients/*.conf 2>/dev/null | wc -l)
        log "Found $client_count client configurations"
        
        if [[ $client_count -gt 0 ]]; then
            log "Client configurations:"
            ls -la /etc/wireguard/clients/*.conf 2>/dev/null || echo "No client configs found"
        fi
        
        return 0
    else
        warn "⚠ Client configuration directory not found"
        return 1
    fi
}

# Show system information
show_system_info() {
    log "System Information:"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "WireGuard Version: $(wg version 2>/dev/null || echo 'Not available')"
    echo "Server IP: $(curl -s ifconfig.me 2>/dev/null || echo 'Not available')"
    echo ""
}

# Main test function
main() {
    log "Starting WireGuard installation tests..."
    echo ""
    
    show_system_info
    
    local tests_passed=0
    local tests_total=0
    
    # Run all tests
    test_service && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_interface && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_config && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_keys && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_firewall && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_ip_forwarding && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_scripts && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_peers && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_connectivity && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    test_client_dir && tests_passed=$((tests_passed + 1))
    tests_total=$((tests_total + 1))
    
    echo ""
    log "Test Results: $tests_passed/$tests_total tests passed"
    
    if [[ $tests_passed -eq $tests_total ]]; then
        log "✓ All tests passed! WireGuard installation is working correctly."
    else
        warn "⚠ Some tests failed. Please check the installation."
    fi
    
    echo ""
    log "Management Commands:"
    echo "  Check status: wg-status"
    echo "  Add client: wg-client add <client_name>"
    echo "  List clients: wg-client list"
    echo "  Service status: systemctl status wg-quick@wg0"
}

# Run main function
main "$@" 