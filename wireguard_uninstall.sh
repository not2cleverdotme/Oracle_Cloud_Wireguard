#!/bin/bash

# WireGuard Oracle Cloud Uninstall Script
# This script safely removes WireGuard installation and cleans up configurations

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

# Stop WireGuard service
stop_wireguard() {
    log "Stopping WireGuard service..."
    
    if systemctl is-active --quiet wg-quick@wg0; then
        systemctl stop wg-quick@wg0
        log "WireGuard service stopped"
    else
        info "WireGuard service was not running"
    fi
    
    if systemctl is-enabled --quiet wg-quick@wg0; then
        systemctl disable wg-quick@wg0
        log "WireGuard service disabled"
    fi
}

# Remove WireGuard interface
remove_interface() {
    log "Removing WireGuard interface..."
    
    if ip link show wg0 &>/dev/null; then
        wg-quick down wg0 2>/dev/null || true
        log "WireGuard interface removed"
    else
        info "WireGuard interface was not found"
    fi
}

# Clean up firewall rules
cleanup_firewall() {
    log "Cleaning up firewall rules..."
    
    # Get WireGuard port from config if it exists
    WG_PORT=""
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        WG_PORT=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    fi
    
    # Remove iptables rules
    if [[ -n "$WG_PORT" ]]; then
        iptables -D INPUT -p udp --dport "$WG_PORT" -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null || true
        iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
        log "Iptables rules removed"
    fi
    
    # Remove firewalld rules if available
    if command -v firewall-cmd &> /dev/null && [[ -n "$WG_PORT" ]]; then
        firewall-cmd --permanent --remove-port="$WG_PORT/udp" 2>/dev/null || true
        firewall-cmd --permanent --remove-masquerade 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
        log "Firewalld rules removed"
    fi
    
    # Remove UFW rules if available
    if command -v ufw &> /dev/null && [[ -n "$WG_PORT" ]]; then
        ufw delete allow "$WG_PORT/udp" 2>/dev/null || true
        log "UFW rules removed"
    fi
}

# Remove systemd service
remove_service() {
    log "Removing systemd service..."
    
    if [[ -f /etc/systemd/system/wg-quick@wg0.service ]]; then
        rm -f /etc/systemd/system/wg-quick@wg0.service
        systemctl daemon-reload
        log "Systemd service removed"
    else
        info "Systemd service file not found"
    fi
}

# Remove configuration files
remove_configs() {
    log "Removing configuration files..."
    
    # Backup directory before removal
    BACKUP_DIR="/tmp/wireguard_backup_$(date +%Y%m%d_%H%M%S)"
    if [[ -d /etc/wireguard ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -r /etc/wireguard "$BACKUP_DIR/"
        log "Configuration backed up to: $BACKUP_DIR"
    fi
    
    # Remove WireGuard directory
    if [[ -d /etc/wireguard ]]; then
        rm -rf /etc/wireguard
        log "WireGuard configuration directory removed"
    fi
}

# Remove management scripts
remove_scripts() {
    log "Removing management scripts..."
    
    if [[ -f /usr/local/bin/wg-client ]]; then
        rm -f /usr/local/bin/wg-client
        log "Client management script removed"
    fi
    
    if [[ -f /usr/local/bin/wg-status ]]; then
        rm -f /usr/local/bin/wg-status
        log "Status script removed"
    fi
}

# Uninstall WireGuard packages
uninstall_packages() {
    log "Uninstalling WireGuard packages..."
    
    # Detect package manager
    if command -v yum &> /dev/null; then
        yum remove -y wireguard-tools 2>/dev/null || true
        log "WireGuard packages removed (yum)"
    elif command -v apt &> /dev/null; then
        apt remove -y wireguard 2>/dev/null || true
        log "WireGuard packages removed (apt)"
    else
        warn "Could not determine package manager"
    fi
}

# Restore IP forwarding settings
restore_ip_forwarding() {
    log "Restoring IP forwarding settings..."
    
    # Remove IP forwarding lines from sysctl.conf
    if [[ -f /etc/sysctl.conf ]]; then
        sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
        sed -i '/net.ipv4.conf.all.forwarding=1/d' /etc/sysctl.conf
        sysctl -p 2>/dev/null || true
        log "IP forwarding settings restored"
    fi
}

# Clean up network configuration
cleanup_network() {
    log "Cleaning up network configuration..."
    
    # Remove any remaining WireGuard routes
    ip route del 10.0.0.0/24 dev wg0 2>/dev/null || true
    
    # Flush WireGuard interface if it still exists
    if ip link show wg0 &>/dev/null; then
        ip link del wg0 2>/dev/null || true
    fi
}

# Show uninstall summary
show_summary() {
    log "WireGuard uninstallation completed!"
    log ""
    log "Summary of actions:"
    log "- WireGuard service stopped and disabled"
    log "- WireGuard interface removed"
    log "- Firewall rules cleaned up"
    log "- Configuration files removed"
    log "- Management scripts removed"
    log "- Packages uninstalled"
    log "- IP forwarding settings restored"
    log ""
    log "Note: Configuration backup is available in /tmp/wireguard_backup_*"
    log "To restore, copy files from backup directory to /etc/wireguard/"
}

# Main uninstall function
main() {
    log "Starting WireGuard uninstallation..."
    
    check_root
    
    # Confirmation prompt
    echo -e "${YELLOW}This will completely remove WireGuard and all its configurations.${NC}"
    echo -e "${YELLOW}Configuration files will be backed up before removal.${NC}"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Uninstallation cancelled"
        exit 0
    fi
    
    stop_wireguard
    remove_interface
    cleanup_firewall
    remove_service
    remove_configs
    remove_scripts
    uninstall_packages
    restore_ip_forwarding
    cleanup_network
    show_summary
}

# Run main function
main "$@" 