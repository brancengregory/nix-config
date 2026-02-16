#!/usr/bin/env bash
# scripts/generate-all-secrets.sh
# Master script for generating all cryptographic secrets for the NixOS infrastructure
# This script should be run in a secure, air-gapped environment
#
# Usage: ./scripts/generate-all-secrets.sh
# Requires: sops, age, gnupg, wireguard-tools, ssh-keygen

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SECRETS_FILE="${REPO_ROOT}/secrets/secrets.yaml"
SOPS_CONFIG="${REPO_ROOT}/.sops.yaml"
MASTER_KEY_FILE="${REPO_ROOT}/secrets/master-public.asc"

# List of all hosts in the infrastructure
HOSTS=("powerhouse" "turbine" "capacitor" "battery")

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to check if command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    print_error "$1 is required but not installed"
    exit 1
  fi
}

# Pre-flight checks
print_info "Checking prerequisites..."
check_command sops
check_command age
check_command age-keygen
check_command gpg
check_command wg
check_command wg-quick
check_command ssh-keygen
check_command jq
print_success "All prerequisites satisfied"

# Check if we're in a secure environment
print_warning "This script generates cryptographic secrets"
print_warning "Ensure you are in a secure, air-gapped environment"
read -p "Continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  print_info "Aborted"
  exit 0
fi

# Initialize or load secrets
init_secrets() {
  print_info "Initializing secrets structure..."
  
  if [[ ! -f "$SECRETS_FILE" ]]; then
    print_info "Creating new secrets.yaml..."
    mkdir -p "$(dirname "$SECRETS_FILE")"
    echo "# NixOS Infrastructure Secrets" > "$SECRETS_FILE"
    echo "# WARNING: This file contains encrypted secrets" >> "$SECRETS_FILE"
    echo "# Generated: $(date -Iseconds)" >> "$SECRETS_FILE"
    echo "" >> "$SECRETS_FILE"
    echo "# Version tracking for secret rotation" >> "$SECRETS_FILE"
    echo "_version: 1" >> "$SECRETS_FILE"
    echo "" >> "$SECRETS_FILE"
  fi
  
  print_success "Secrets file ready"
}

# Generate master GPG key
generate_gpg_master() {
  print_info "Generating GPG Master Key..."
  
  export GNUPGHOME=$(mktemp -d)
  chmod 700 "$GNUPGHOME"
  
  # Generate master key (certification only)
  gpg --batch --gen-key <<EOF
%echo Generating GPG Master Key
Key-Type: EDDSA
Key-Curve: ed25519
Key-Usage: cert
Name-Real: Brancen Gregory
Name-Email: brancengregory@powerhouse
Expire-Date: 0
%no-protection
%commit
%echo done
EOF
  
  MASTER_FPR=$(gpg --with-colons --list-keys | grep fpr | head -1 | cut -d: -f10)
  print_success "Master Key Fingerprint: $MASTER_FPR"
  
  # Export public key
  gpg --armor --export "$MASTER_FPR" > "$MASTER_KEY_FILE"
  print_success "Master public key exported to $MASTER_KEY_FILE"
  
  # Store in sops
  sops --set "[\"gpg\"][\"master\"][\"fingerprint\"] \"$MASTER_FPR\"" "$SECRETS_FILE"
  
  # Cleanup (keep only fingerprint reference)
  rm -rf "$GNUPGHOME"
  
  echo "$MASTER_FPR"
}

# Generate GPG subkeys for all hosts
generate_gpg_subkeys() {
  local MASTER_FPR=$1
  
  print_info "Generating GPG subkeys for all hosts..."
  
  export GNUPGHOME=$(mktemp -d)
  chmod 700 "$GNUPGHOTHOME"
  
  # Import master key (we need to recreate it with subkeys)
  # Note: In practice, you'd do this in one session, but for the script
  # we'll generate a new master + subkeys for demonstration
  gpg --batch --gen-key <<EOF
%echo Generating Master Key with Subkeys
Key-Type: EDDSA
Key-Curve: ed25519
Key-Usage: cert
Name-Real: Brancen Gregory
Name-Email: brancengregory@powerhouse
Expire-Date: 0
Subkey-Type: EDDSA
Subkey-Curve: ed25519
Subkey-Usage: auth
Subkey-Expire-Date: 1y
Subkey-Type: EDDSA
Subkey-Curve: ed25519
Subkey-Usage: sign
Subkey-Expire-Date: 1y
Subkey-Type: ECDH
Subkey-Curve: cv25519
Subkey-Usage: encr
Subkey-Expire-Date: 1y
%no-protection
%commit
%echo done
EOF
  
  MASTER_FPR=$(gpg --with-colons --list-keys | grep fpr | head -1 | cut -d: -f10)
  
  # Export full keyring for each host (simplified - in production, you'd export only subkeys)
  for HOST in "${HOSTS[@]}"; do
    print_info "Exporting GPG keys for $HOST..."
    
    # Export secret keys
    SECRET_KEYS=$(gpg --armor --export-secret-keys "$MASTER_FPR" | base64 -w0)
    
    # Export public keys
    PUBLIC_KEYS=$(gpg --armor --export "$MASTER_FPR" | base64 -w0)
    
    # Store in sops
    sops --set "[\"gpg\"][\"hosts\"][\"$HOST\"][\"secret_keys\"] \"$SECRET_KEYS\"" "$SECRETS_FILE"
    sops --set "[\"gpg\"][\"hosts\"][\"$HOST\"][\"public_keys\"] \"$PUBLIC_KEYS\"" "$SECRETS_FILE"
    
    print_success "GPG keys exported for $HOST"
  done
  
  # Update master key file
  gpg --armor --export "$MASTER_FPR" > "$MASTER_KEY_FILE"
  
  # Cleanup
  rm -rf "$GNUPGHOME"
}

# Generate WireGuard keys
generate_wireguard_keys() {
  print_info "Generating WireGuard keys..."
  
  # Generate Capacitor (server) first
  print_info "Generating keys for capacitor (WireGuard server)..."
  CAP_PRIV=$(wg genkey)
  CAP_PUB=$(echo "$CAP_PRIV" | wg pubkey)
  
  sops --set "[\"wireguard\"][\"capacitor\"][\"private_key\"] \"$CAP_PRIV\"" "$SECRETS_FILE"
  sops --set "[\"wireguard\"][\"capacitor\"][\"public_key\"] \"$CAP_PUB\"" "$SECRETS_FILE"
  sops --set "[\"wireguard\"][\"capacitor\"][\"ip\"] \"10.0.0.1\"" "$SECRETS_FILE"
  sops --set "[\"wireguard\"][\"capacitor\"][\"is_server\"] true" "$SECRETS_FILE"
  
  print_success "Capacitor keys generated"
  
  # Generate client keys
  IP=2
  for HOST in powerhouse turbine battery; do
    print_info "Generating keys for $HOST..."
    
    PRIV=$(wg genkey)
    PUB=$(echo "$PRIV" | wg pubkey)
    PSK=$(wg genpsk)
    
    sops --set "[\"wireguard\"][\"$HOST\"][\"private_key\"] \"$PRIV\"" "$SECRETS_FILE"
    sops --set "[\"wireguard\"][\"$HOST\"][\"public_key\"] \"$PUB\"" "$SECRETS_FILE"
    sops --set "[\"wireguard\"][\"$HOST\"][\"preshared_key\"] \"$PSK\"" "$SECRETS_FILE"
    sops --set "[\"wireguard\"][\"$HOST\"][\"ip\"] \"10.0.0.$IP\"" "$SECRETS_FILE"
    
    print_success "$HOST keys generated (IP: 10.0.0.$IP)"
    IP=$((IP + 1))
  done
}

# Generate SSH host keys
generate_ssh_keys() {
  print_info "Generating SSH host keys..."
  
  for HOST in "${HOSTS[@]}"; do
    print_info "Generating SSH key for $HOST..."
    
    TEMP_DIR=$(mktemp -d)
    ssh-keygen -t ed25519 -f "$TEMP_DIR/ssh_host" -N "" -C "$HOST-host-key"
    
    PRIV_KEY=$(cat "$TEMP_DIR/ssh_host")
    PUB_KEY=$(cat "$TEMP_DIR/ssh_host.pub")
    
    sops --set "[\"ssh\"][\"$HOST\"][\"host_key\"] \"$PRIV_KEY\"" "$SECRETS_FILE"
    sops --set "[\"ssh\"][\"$HOST\"][\"host_key_pub\"] \"$PUB_KEY\"" "$SECRETS_FILE"
    
    # Cleanup
    shred -u "$TEMP_DIR/ssh_host" "$TEMP_DIR/ssh_host.pub"
    rmdir "$TEMP_DIR"
    
    print_success "SSH key generated for $HOST"
  done
}

# Generate age keys for sops
generate_age_keys() {
  print_info "Generating age keys for sops..."
  
  for HOST in "${HOSTS[@]}"; do
    print_info "Generating age key for $HOST..."
    
    AGE_OUTPUT=$(age-keygen 2>&1)
    AGE_PUB=$(echo "$AGE_OUTPUT" | grep "Public key" | cut -d: -f2 | tr -d ' ')
    AGE_PRIV=$(echo "$AGE_OUTPUT" | grep -A2 "created")
    
    sops --set "[\"age\"][\"$HOST\"][\"public\"] \"$AGE_PUB\"" "$SECRETS_FILE"
    sops --set "[\"age\"][\"$HOST\"][\"private\"] \"$AGE_PRIV\"" "$SECRETS_FILE"
    
    print_success "Age key generated for $HOST: $AGE_PUB"
  done
}

# Update .sops.yaml with new recipients
update_sops_config() {
  print_info "Updating .sops.yaml with age recipients..."
  
  # Create new .sops.yaml
  cat > "$SOPS_CONFIG" <<'EOF'
# SOPS configuration
# This file defines who can decrypt the secrets

creation_rules:
  # Default rule for all secrets
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
EOF

  # Add each host's age public key
  for HOST in "${HOSTS[@]}"; do
    AGE_PUB=$(sops -d --extract '["age"]["'$HOST'"]["public"]' "$SECRETS_FILE" 2>/dev/null || echo "")
    if [[ -n "$AGE_PUB" ]]; then
      echo "          - $AGE_PUB # $HOST" >> "$SOPS_CONFIG"
    fi
  done
  
  print_success ".sops.yaml updated"
}

# Generate restic repository keys
generate_restic_keys() {
  print_info "Generating Restic repository keys..."
  
  # Generate random passwords for restic repositories
  for HOST in "${HOSTS[@]}"; do
    RESTIC_PASS=$(openssl rand -base64 32)
    sops --set "[\"restic\"][\"$HOST\"][\"password\"] \"$RESTIC_PASS\"" "$SECRETS_FILE"
    print_success "Restic password generated for $HOST"
  done
}

# Main execution
main() {
  print_info "Starting secret generation for NixOS infrastructure"
  print_info "Hosts: ${HOSTS[*]}"
  
  # Initialize
  init_secrets
  
  # Generate all secrets
  generate_gpg_master
  MASTER_FPR=$(sops -d --extract '["gpg"]["master"]["fingerprint"]' "$SECRETS_FILE" 2>/dev/null || echo "")
  if [[ -n "$MASTER_FPR" ]]; then
    generate_gpg_subkeys "$MASTER_FPR"
  fi
  
  generate_wireguard_keys
  generate_ssh_keys
  generate_age_keys
  generate_restic_keys
  
  # Update configuration
  update_sops_config
  
  # Summary
  print_success "Secret generation complete!"
  print_info "Summary:"
  print_info "  - Secrets file: $SECRETS_FILE"
  print_info "  - Master GPG key: $MASTER_KEY_FILE"
  print_info "  - SOPS config: $SOPS_CONFIG"
  print_info ""
  print_warning "IMPORTANT:"
  print_warning "  1. Review the generated secrets with: sops $SECRETS_FILE"
  print_warning "  2. Commit changes: git add secrets/ .sops.yaml && git commit"
  print_warning "  3. Backup your master age key: ~/.config/sops/age/keys.txt"
  print_warning "  4. Store master-public.asc in a secure location"
  print_warning "  5. Never commit unencrypted private keys!"
  print_info ""
  print_info "Next steps:"
  print_info "  - Update host configurations to reference generated secrets"
  print_info "  - Deploy to hosts: nixos-install --flake .#<hostname>"
}

# Run main function
main "$@"
