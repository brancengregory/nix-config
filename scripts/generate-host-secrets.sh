#!/usr/bin/env bash
# scripts/generate-host-secrets.sh
# Generate secrets for a single host (useful for adding new machines)
#
# Usage: ./scripts/generate-host-secrets.sh <hostname>
# Example: ./scripts/generate-host-secrets.sh battery

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SECRETS_FILE="${REPO_ROOT}/secrets/secrets.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check arguments
if [[ $# -ne 1 ]]; then
  print_error "Usage: $0 <hostname>"
  print_info "Example: $0 battery"
  exit 1
fi

HOST=$1

# Validate hostname
if [[ ! "$HOST" =~ ^[a-z0-9-]+$ ]]; then
  print_error "Invalid hostname: $HOST"
  print_info "Hostname must be lowercase alphanumeric with hyphens"
  exit 1
fi

print_info "Generating secrets for host: $HOST"

# Check prerequisites
for cmd in sops age-keygen gpg wg ssh-keygen; do
  if ! command -v "$cmd" &> /dev/null; then
    print_error "$cmd is required but not installed"
    exit 1
  fi
done

# Check if secrets file exists
if [[ ! -f "$SECRETS_FILE" ]]; then
  print_error "Secrets file not found: $SECRETS_FILE"
  print_info "Run ./scripts/generate-all-secrets.sh first to initialize"
  exit 1
fi

# Generate WireGuard keys
print_info "Generating WireGuard keys..."
WG_PRIV=$(wg genkey)
WG_PUB=$(echo "$WG_PRIV" | wg pubkey)
WG_PSK=$(wg genpsk)

# Get next available IP
print_info "Determining IP address..."
MAX_IP=1
for key in $(sops -d --extract '["wireguard"]' "$SECRETS_FILE" 2>/dev/null | jq -r 'keys[]' 2>/dev/null); do
  IP=$(sops -d --extract '["wireguard"]["'$key'"]["ip"]' "$SECRETS_FILE" 2>/dev/null | grep -o '[0-9]*$' || echo "1")
  if [[ "$IP" -gt "$MAX_IP" ]]; then
    MAX_IP=$IP
  fi
done
NEW_IP=$((MAX_IP + 1))
IP_ADDR="10.0.0.$NEW_IP"

print_info "Assigning IP: $IP_ADDR"

# Store WireGuard secrets
sops --set "[\"wireguard\"][\"$HOST\"][\"private_key\"] \"$WG_PRIV\"" "$SECRETS_FILE"
sops --set "[\"wireguard\"][\"$HOST\"][\"public_key\"] \"$WG_PUB\"" "$SECRETS_FILE"
sops --set "[\"wireguard\"][\"$HOST\"][\"preshared_key\"] \"$WG_PSK\"" "$SECRETS_FILE"
sops --set "[\"wireguard\"][\"$HOST\"][\"ip\"] \"$IP_ADDR\"" "$SECRETS_FILE"

print_success "WireGuard keys generated (IP: $IP_ADDR)"

# Generate SSH host key
print_info "Generating SSH host key..."
TEMP_DIR=$(mktemp -d)
ssh-keygen -t ed25519 -f "$TEMP_DIR/ssh_host" -N "" -C "$HOST-host-key"

SSH_PRIV=$(cat "$TEMP_DIR/ssh_host")
SSH_PUB=$(cat "$TEMP_DIR/ssh_host.pub")

sops --set "[\"ssh\"][\"$HOST\"][\"host_key\"] \"$SSH_PRIV\"" "$SECRETS_FILE"
sops --set "[\"ssh\"][\"$HOST\"][\"host_key_pub\"] \"$SSH_PUB\"" "$SECRETS_FILE"

shred -u "$TEMP_DIR/ssh_host" "$TEMP_DIR/ssh_host.pub"
rmdir "$TEMP_DIR"

print_success "SSH host key generated"

# Generate age key
print_info "Generating age key..."
AGE_OUTPUT=$(age-keygen 2>&1)
AGE_PUB=$(echo "$AGE_OUTPUT" | grep "Public key" | cut -d: -f2 | tr -d ' ')
AGE_PRIV=$(echo "$AGE_OUTPUT" | grep -A2 "created")

sops --set "[\"age\"][\"$HOST\"][\"public\"] \"$AGE_PUB\"" "$SECRETS_FILE"
sops --set "[\"age\"][\"$HOST\"][\"private\"] \"$AGE_PRIV\"" "$SECRETS_FILE"

print_success "Age key generated: $AGE_PUB"

# Generate GPG subkeys (if master key exists)
print_info "Generating GPG subkeys..."
MASTER_FPR=$(sops -d --extract '["gpg"]["master"]["fingerprint"]' "$SECRETS_FILE" 2>/dev/null || echo "")

if [[ -n "$MASTER_FPR" ]]; then
  export GNUPGHOME=$(mktemp -d)
  chmod 700 "$GNUPGHOME"
  
  # Import master key
  sops -d --extract '["gpg"]["hosts"]["capacitor"]["secret_keys"]' "$SECRETS_FILE" 2>/dev/null | base64 -d | gpg --import 2>/dev/null || true
  
  # Add subkeys
  gpg --quick-add-key "$MASTER_FPR" ed25519 auth 1y 2>/dev/null || true
  gpg --quick-add-key "$MASTER_FPR" ed25519 sign 1y 2>/dev/null || true
  gpg --quick-add-key "$MASTER_FPR" cv25519 encr 1y 2>/dev/null || true
  
  # Export
  SECRET_KEYS=$(gpg --armor --export-secret-keys "$MASTER_FPR" 2>/dev/null | base64 -w0 || echo "")
  PUBLIC_KEYS=$(gpg --armor --export "$MASTER_FPR" 2>/dev/null | base64 -w0 || echo "")
  
  if [[ -n "$SECRET_KEYS" ]]; then
    sops --set "[\"gpg\"][\"hosts\"][\"$HOST\"][\"secret_keys\"] \"$SECRET_KEYS\"" "$SECRETS_FILE"
    sops --set "[\"gpg\"][\"hosts\"][\"$HOST\"][\"public_keys\"] \"$PUBLIC_KEYS\"" "$SECRETS_FILE"
    print_success "GPG subkeys generated"
  else
    print_warning "Could not generate GPG subkeys (master key may be missing)"
  fi
  
  rm -rf "$GNUPGHOME"
else
  print_warning "No GPG master key found, skipping GPG generation"
fi

# Generate Restic password
print_info "Generating Restic password..."
RESTIC_PASS=$(openssl rand -base64 32)
sops --set "[\"restic\"][\"$HOST\"][\"password\"] \"$RESTIC_PASS\"" "$SECRETS_FILE"
print_success "Restic password generated"

# Update .sops.yaml
print_info "Updating .sops.yaml..."
SOPS_CONFIG="${REPO_ROOT}/.sops.yaml"

# Check if host already in .sops.yaml
if ! grep -q "$AGE_PUB" "$SOPS_CONFIG" 2>/dev/null; then
  # Add to creation_rules
  sed -i "/age:/a\          - $AGE_PUB # $HOST" "$SOPS_CONFIG"
  print_success "Added $HOST to .sops.yaml"
else
  print_info "$HOST already in .sops.yaml"
fi

# Summary
print_success "Secret generation complete for $HOST!"
print_info ""
print_info "Host: $HOST"
print_info "WireGuard IP: $IP_ADDR"
print_info "Age Public Key: $AGE_PUB"
print_info ""
print_warning "Next steps:"
print_warning "  1. Review secrets: sops $SECRETS_FILE"
print_warning "  2. Commit changes: git add secrets/ .sops.yaml && git commit"
print_warning "  3. Update host configuration in hosts/$HOST/"
print_warning "  4. Deploy: nixos-install --flake .#$HOST"
