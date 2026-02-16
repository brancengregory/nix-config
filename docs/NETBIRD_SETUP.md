# Netbird Implementation Guide

This guide walks you through completing the Netbird setup on capacitor.

## Overview

We've implemented:
- **Netbird Self-Hosted Server** (management, signal, relay services)
- **Podman Quadlets** for containerized PostgreSQL and Redis
- **Caddy Reverse Proxy** with wildcard SSL via Porkbun DNS
- **Netbird Client** connecting capacitor to its own mesh

## Files Created/Modified

### New Files
1. `modules/network/netbird.nix` - Netbird server and client configuration
2. `modules/network/caddy.nix` - Caddy reverse proxy with Porkbun DNS
3. `secrets/netbird-secrets-template.yaml` - Template for required secrets

### Modified Files
1. `modules/services/openwebui.nix` - Changed Open WebUI port 3000 → 8080
2. `hosts/capacitor/config.nix` - Added Netbird and Caddy configurations

## Prerequisites

### 1. DNS Configuration

Add these records at Porkbun for `brancen.world`:

```
Type  Host                  Value
A     *.brancen.world       75.7.12.211
A     brancen.world         75.7.12.211
```

### 2. Gateway Port Forwarding

Forward these ports from your ATT gateway (75.7.12.211) to capacitor's LAN IP (192.168.1.167):

#### TCP Ports (6 ports)
| Port | Service | Purpose |
|------|---------|---------|
| **80** | Caddy HTTP | ACME SSL certificate validation (HTTP-01 challenge) |
| **443** | Caddy HTTPS | All web services via reverse proxy |
| **33073** | Netbird Management | API endpoint for Netbird clients |
| **10000** | Netbird Signal | WebRTC signaling for peer connections |
| **3478** | TURN/STUN | NAT traversal for peer-to-peer connections |
| **5349** | TURNS | Secure TURN relay |

#### UDP Ports (5 ports)
| Port | Service | Purpose |
|------|---------|---------|
| **51820** | WireGuard | Existing VPN mesh (already forwarded) |
| **10000** | Netbird Signal/Relay | WebRTC signaling and relay traffic |
| **3478** | TURN/STUN | NAT traversal |
| **5349** | TURNS | Secure TURN relay |

**Note:** Ports 22, 77, 3000, 3080, 8080, 9000-9001, 9090 are **NOT** forwarded - they're internal only and accessed via Caddy on port 443.

### 3. Generate Netbird Secrets

Run these commands to generate the required secrets:

```bash
# 1. JWT Secret (32-byte hex)
openssl rand -hex 32
# Example output: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456

# 2. Admin Password Hash (bcrypt)
# Replace 'your-admin-password' with your desired password
python3 -c "
import bcrypt
password = 'your-admin-password-here'
hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(rounds=10))
print(hashed.decode('utf-8'))
"
# Example output: $2y$10$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. PostgreSQL Password
openssl rand -base64 24
# Example output: your-secure-random-password-here-12345

# 4. TURN Password
openssl rand -base64 24
# Example output: another-secure-random-password-here-67890
```

### 4. Edit Secrets File

```bash
# Edit the encrypted secrets file
sops secrets/secrets.yaml

# Add this structure (replace with your generated values):
netbird:
    jwt-secret: YOUR_JWT_SECRET_HERE
    admin-password-hash: YOUR_BCRYPT_HASH_HERE
    postgres-password: YOUR_POSTGRES_PASSWORD_HERE
    turn-password: YOUR_TURN_PASSWORD_HERE
porkbun:
    credentials: |
        PORKBUN_API_KEY=your-actual-porkbun-api-key
        PORKBUN_SECRET_KEY=your-actual-porkbun-secret-key
```

Save and exit - SOPS will automatically encrypt the values.

## Building and Deploying

### Step 1: Build the Configuration

```bash
# Build the configuration to verify it compiles
nix build .#nixosConfigurations.capacitor.config.system.build.toplevel

# Or use your mise task if configured
mise build-capacitor
```

### Step 2: Deploy to Capacitor

```bash
# Copy the configuration to capacitor and switch
nixos-rebuild switch --flake .#capacitor --target-host root@capacitor --use-substitutes

# Or if you're on capacitor locally:
sudo nixos-rebuild switch --flake .#capacitor
```

### Step 3: Verify Services

```bash
# Check that all containers are running
sudo podman ps

# Check systemd services
sudo systemctl status podman-netbird-postgres
sudo systemctl status podman-netbird-redis
sudo systemctl status podman-netbird-management
sudo systemctl status podman-netbird-signal
sudo systemctl status podman-netbird-relay
sudo systemctl status netbird
sudo systemctl status caddy

# Check Netbird status
sudo netbird status
```

### Step 4: Access Dashboard

Once everything is running:

1. Access the Netbird dashboard at: `https://netbird.brancen.world`
2. Login with:
   - Username: `admin`
   - Password: The password you hashed with bcrypt

## Service URLs After Caddy Setup

| Service | URL |
|---------|-----|
| Netbird Dashboard | `https://netbird.brancen.world` |
| Jellyfin | `https://jellyfin.brancen.world` |
| Git (Forgejo) | `https://git.brancen.world` |
| Chat (Open WebUI) | `https://chat.brancen.world` |
| Grafana | `https://grafana.brancen.world` |
| Prometheus | `https://prometheus.brancen.world` |
| Downloads (qBittorrent) | `https://downloads.brancen.world` |
| Ollama API | `https://ollama.brancen.world` |

## Troubleshooting

### Issue: Containers won't start
```bash
# Check logs
sudo journalctl -u podman-netbird-postgres -f
sudo podman logs netbird-postgres

# Check if ports are already in use
sudo ss -tlnp | grep -E '5433|6380|18765|33073|10000|3478'
```

### Issue: Caddy won't get certificate
```bash
# Check Caddy logs
sudo journalctl -u caddy -f

# Verify DNS records propagated
dig netbird.brancen.world

# Check Porkbun credentials are correct
cat /run/secrets/porkbun/credentials
```

### Issue: Netbird client won't connect
```bash
# Check netbird logs
sudo journalctl -u netbird -f

# Verify management server is accessible
curl -v https://netbird.brancen.world:33073

# Check firewall rules
sudo iptables -L -n | grep 33073
```

### Issue: Open WebUI moved to 8080
Remember: Open WebUI is now on port 8080 (not 3000). Access via:
- Internal: `http://capacitor:8080`
- External: `https://chat.brancen.world`

## Migration Strategy

### Phase 1: Parallel Operation (Current)
- WireGuard and Netbird both active
- Test Netbird connectivity
- Verify all services work via Caddy

### Phase 2: Add Spoke Nodes
On each spoke node (powerhouse, turbine, battery):

```bash
# Install netbird client
nix-env -iA nixpkgs.netbird

# Connect to capacitor's management server
sudo netbird up --management-url https://netbird.brancen.world:33073 --admin-url https://netbird.brancen.world

# Login via browser when prompted
```

Or add to their NixOS configuration:
```nix
services.netbird = {
  enable = true;
  managementUrl = "https://netbird.brancen.world:33073";
};
```

### Phase 3: Migrate WireGuard Nodes
1. Install Netbird client on spoke node
2. Join Netbird mesh
3. Test connectivity via Netbird (100.64.x.x addresses)
4. Disable WireGuard on that node
5. Repeat for all nodes

### Phase 4: Decommission WireGuard
Once all nodes migrated:

```nix
# In hosts/capacitor/config.nix, disable WireGuard:
networking.wireguard-mesh.enable = false;
```

## Security Notes

1. **Admin Password**: The admin password hash is bcrypt - store the original password securely
2. **JWT Secret**: This signs all API tokens - keep it secure and backed up
3. **PostgreSQL**: Runs on isolated port 5433, not accessible externally
4. **TURN Password**: Used for relay authentication - keep secure
5. **Porkbun Keys**: These control your DNS - store securely

## Backup Considerations

Important data to back up:
- `/var/lib/netbird/postgres/` - Database with all accounts, groups, policies
- `/var/lib/netbird/management/` - Management service data
- `/var/lib/netbird/signal/` - Signal service data
- `secrets/secrets.yaml` - All encrypted secrets (already in git)

## Next Steps

1. ✅ Configure DNS at Porkbun
2. ✅ Configure gateway port forwarding
3. ✅ Generate secrets (JWT, bcrypt hash, passwords)
4. ✅ Edit `secrets/secrets.yaml` with SOPS
5. ⏳ Build and deploy configuration
6. ⏳ Verify all services start
7. ⏳ Test Netbird dashboard access
8. ⏳ Add spoke nodes
9. ⏳ Migrate from WireGuard

## Support

- Netbird Docs: https://docs.netbird.io/
- Caddy Docs: https://caddyserver.com/docs/
- Porkbun API: https://porkbun.com/api/json/v3/documentation
