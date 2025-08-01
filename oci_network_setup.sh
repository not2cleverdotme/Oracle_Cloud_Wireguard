#!/bin/bash

# OCI Network Setup Helper Script
# This script helps configure Oracle Cloud Security Lists for WireGuard

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

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

# Get WireGuard port
get_wireguard_port() {
    local port=""
    
    # Try multiple methods to get the port
    if [[ -f /etc/wireguard/wg0.conf ]]; then
        port=$(grep "ListenPort" /etc/wireguard/wg0.conf | cut -d'=' -f2 | tr -d ' ')
    fi
    
    if [[ -z "$port" ]] && [[ -f /etc/wireguard/INSTALLATION_SUMMARY.txt ]]; then
        port=$(grep "WireGuard Port:" /etc/wireguard/INSTALLATION_SUMMARY.txt | cut -d':' -f2 | tr -d ' ')
    fi
    
    echo "$port"
}

# Get server public IP
get_server_ip() {
    local ip=""
    
    # Try multiple methods to get the IP
    ip=$(curl -s ifconfig.me 2>/dev/null)
    
    if [[ -z "$ip" ]]; then
        ip=$(curl -s ipinfo.io/ip 2>/dev/null)
    fi
    
    if [[ -z "$ip" ]]; then
        ip=$(curl -s icanhazip.com 2>/dev/null)
    fi
    
    echo "$ip"
}

# Check if WireGuard is installed
check_wireguard_installation() {
    if [[ ! -f /etc/wireguard/wg0.conf ]]; then
        error "WireGuard is not installed or configuration not found"
        error "Please run the installation script first: ./wireguard_oracle_cloud_install.sh"
        exit 1
    fi
    
    if ! systemctl is-active --quiet wg-quick@wg0; then
        warn "WireGuard service is not running"
        warn "Start it with: systemctl start wg-quick@wg0"
    fi
}

# Generate OCI security list configuration
generate_oci_config() {
    local wg_port="$1"
    local server_ip="$2"
    
    cat << EOF

===========================================
   ORACLE CLOUD SECURITY LIST CONFIGURATION
===========================================

WireGuard Server Information:
- Server Public IP: $server_ip
- WireGuard Port: $wg_port (UDP)
- Protocol: UDP

Required OCI Security List Rules:
================================

1. Navigate to OCI Console:
   https://console.oracle.com

2. Go to: Networking → Virtual Cloud Networks

3. Click on your VCN

4. Click "Security Lists" in the left menu

5. Click on your security list

6. Add the following Ingress Rules:

┌─────────────────┬──────────┬──────────────────┬─────────────────────┬─────────────────┐
│ Source          │ Protocol │ Source Port Range│ Destination Port    │ Description     │
├─────────────────┼──────────┼──────────────────┼─────────────────────┼─────────────────┤
│ 0.0.0.0/0      │ UDP      │ All              │ $wg_port           │ WireGuard VPN   │
│ 0.0.0.0/0      │ TCP      │ All              │ 22                  │ SSH Access      │
│ 0.0.0.0/0      │ TCP      │ All              │ 80                  │ HTTP (optional) │
│ 0.0.0.0/0      │ TCP      │ All              │ 443                 │ HTTPS (optional)│
└─────────────────┴──────────┴──────────────────┴─────────────────────┴─────────────────┘

Alternative: More Secure Configuration
====================================

For better security, you can restrict access to specific IP ranges:

┌─────────────────┬──────────┬──────────────────┬─────────────────────┬─────────────────┐
│ Source          │ Protocol │ Source Port Range│ Destination Port    │ Description     │
├─────────────────┼──────────┼──────────────────┼─────────────────────┼─────────────────┤
│ YOUR_IP/32      │ UDP      │ All              │ $wg_port           │ WireGuard VPN   │
│ YOUR_IP/32      │ TCP      │ All              │ 22                  │ SSH Access      │
└─────────────────┴──────────┴──────────────────┴─────────────────────┴─────────────────┘

Replace YOUR_IP with your actual IP address.

Testing Connection:
==================

After configuring the security list, test the connection:

1. From your client device:
   ping $server_ip

2. Test WireGuard port:
   nc -zu $server_ip $wg_port

3. Check if WireGuard is listening:
   netstat -tuln | grep $wg_port

Troubleshooting:
===============

If connection fails:
1. Verify security list rules are applied
2. Check if WireGuard service is running: systemctl status wg-quick@wg0
3. Verify port is listening: netstat -tuln | grep $wg_port
4. Check firewall on the server: iptables -L INPUT -n

EOF
}

# Generate Terraform configuration
generate_terraform_config() {
    local wg_port="$1"
    
    cat << EOF

===========================================
   TERRAFORM SECURITY LIST CONFIGURATION
===========================================

If you're using Terraform to manage OCI resources, add this to your configuration:

resource "oci_core_security_list" "wireguard_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "WireGuard Security List"

  ingress_security_rules {
    protocol    = "17"  # UDP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    
    udp_options {
      min = $wg_port
      max = $wg_port
    }
  }

  ingress_security_rules {
    protocol    = "6"  # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

EOF
}

# Main function
main() {
    log "OCI Network Setup Helper"
    echo ""
    
    # Check WireGuard installation
    check_wireguard_installation
    
    # Get WireGuard port
    local wg_port=$(get_wireguard_port)
    if [[ -z "$wg_port" ]]; then
        error "Could not determine WireGuard port"
        exit 1
    fi
    
    # Get server IP
    local server_ip=$(get_server_ip)
    if [[ -z "$server_ip" ]]; then
        error "Could not determine server public IP"
        exit 1
    fi
    
    log "WireGuard Configuration Detected:"
    info "Server IP: $server_ip"
    info "WireGuard Port: $wg_port (UDP)"
    echo ""
    
    # Generate configuration
    generate_oci_config "$wg_port" "$server_ip"
    
    # Ask if user wants Terraform config
    read -p "Generate Terraform configuration? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        generate_terraform_config "$wg_port"
    fi
    
    echo ""
    log "Configuration complete!"
    log "Remember to apply the security list rules in OCI Console"
}

# Run main function
main "$@" 