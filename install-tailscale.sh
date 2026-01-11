#!/bin/bash
# Tailscale Installation and Connection Script for Linux
# This script installs Tailscale (if not present) and connects using an auth key
# Usage: curl -LsSf https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install-tailscale.sh | sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Auth key placeholder - replace with your actual auth key
AUTH_KEY="tskey-auth-k76TUKz9VM11CNTRL-jRF4zLjZGCe2BYxp9g36Ce3z3oRw2wK5"

# Logging functions
log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Check if running as root or with sudo
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        log_error "Cannot detect Linux distribution. /etc/os-release not found."
        exit 1
    fi
    
    log_info "Detected distribution: $DISTRO $VERSION"
}

# Check if Tailscale is already installed
is_tailscale_installed() {
    # Check if tailscale command exists
    if command -v tailscale >/dev/null 2>&1; then
        return 0
    fi
    
    # Check if tailscaled service exists and is properly installed
    if systemctl list-unit-files 2>/dev/null | grep -q "^tailscaled.service"; then
        # Verify the service file actually exists
        if [ -f /etc/systemd/system/tailscaled.service ] || [ -f /usr/lib/systemd/system/tailscaled.service ] || [ -f /lib/systemd/system/tailscaled.service ]; then
            return 0
        fi
    fi
    
    return 1
}

# Install Tailscale based on distribution
install_tailscale() {
    log_info "Installing Tailscale..."
    
    case $DISTRO in
        ubuntu|debian)
            log_info "Using apt package manager"
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq
            apt-get install -y -qq curl gnupg
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        rhel|centos|fedora|rocky|almalinux)
            log_info "Using yum/dnf package manager"
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y curl
                curl -fsSL https://tailscale.com/install.sh | sh
            elif command -v yum >/dev/null 2>&1; then
                yum install -y curl
                curl -fsSL https://tailscale.com/install.sh | sh
            else
                log_error "Neither dnf nor yum found"
                exit 1
            fi
            ;;
        arch|manjaro)
            log_info "Using pacman package manager"
            pacman -Sy --noconfirm curl
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            log_info "Please install Tailscale manually from https://tailscale.com/download"
            exit 1
            ;;
    esac
    
    log_info "Tailscale installation completed"
}

# Enable and start Tailscale service
setup_service() {
    log_info "Setting up Tailscale service..."
    
    # Check if service exists
    if ! systemctl list-unit-files 2>/dev/null | grep -q "^tailscaled.service"; then
        log_error "tailscaled service not found. Tailscale may not be installed correctly."
        log_info "Attempting to reinstall Tailscale..."
        install_tailscale
        # Reload systemd after installation
        systemctl daemon-reload
        sleep 2
    fi
    
    # Enable service to start on boot
    if systemctl enable tailscaled 2>/dev/null; then
        log_info "Tailscale service enabled for auto-start on boot"
    else
        # Check if already enabled
        if systemctl is-enabled tailscaled >/dev/null 2>&1; then
            log_info "Tailscale service is already enabled"
        else
            log_warn "Failed to enable tailscaled service"
        fi
    fi
    
    # Start the service
    if systemctl start tailscaled 2>/dev/null; then
        log_info "Tailscale service started"
    else
        # Check if already running
        if systemctl is-active --quiet tailscaled 2>/dev/null; then
            log_info "Tailscale service is already running"
        else
            log_warn "Failed to start tailscaled service"
        fi
    fi
    
    # Wait for service to be ready
    log_info "Waiting for Tailscale service to be ready..."
    sleep 3
    
    # Verify service is running
    if systemctl is-active --quiet tailscaled 2>/dev/null; then
        log_info "Tailscale service is running"
    else
        log_error "Tailscale service failed to start"
        systemctl status tailscaled || true
        exit 1
    fi
}

# Connect to Tailscale with auth key
connect_tailscale() {
    log_info "Connecting to Tailscale..."
    
    if [ "$AUTH_KEY" = "YOUR_AUTH_KEY_HERE" ]; then
        log_error "Auth key not configured. Please replace YOUR_AUTH_KEY_HERE with your actual Tailscale auth key."
        exit 1
    fi
    
    # Connect using auth key
    tailscale up --authkey="$AUTH_KEY" --accept-routes --accept-dns
    
    if [ $? -eq 0 ]; then
        log_info "Successfully connected to Tailscale!"
        
        # Display Tailscale status
        log_info "Tailscale status:"
        tailscale status
    else
        log_error "Failed to connect to Tailscale"
        exit 1
    fi
}

# Main execution
main() {
    log_info "Starting Tailscale installation and connection script..."
    
    check_root
    detect_distro
    
    if is_tailscale_installed; then
        log_info "Tailscale is already installed"
    else
        install_tailscale
    fi
    
    setup_service
    connect_tailscale
    
    log_info "Script completed successfully!"
}

# Run main function
main
