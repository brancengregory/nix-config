# Capacitor NixOS Configuration

Homelab server configuration for capacitor (formerly Arch Linux server).

## Hardware

- **Motherboard:** ASRock Z690 PG Riptide
- **CPU:** 12th Gen Intel Core i5-12600K (16 threads)
- **RAM:** 64GB
- **Graphics:** Intel UHD Graphics 770 (integrated)
- **Network:** Realtek 2.5GbE
- **Storage:**
  - nvme0n1: 1TB NVMe (boot, LUKS encrypted)
  - sda: 19TB HDD (vault1, LUKS encrypted)
  - sdb: 11TB HDD (vault2, LUKS encrypted)
  - sdc: 11TB HDD (vault3, parity for SnapRAID)

## Storage Architecture

### LUKS-encrypted Vaults

- **vault1 (sda):** 19TB - critical, standard, ephemeral
- **vault2 (sdb):** 11TB - critical, standard, ephemeral
- **vault3 (sdc):** 11TB - SnapRAID parity

### MergerFS Pools

| Pool | Source Drives | Policy | Contents |
|------|--------------|---------|----------|
| `/mnt/storage/critical` | vault1 + vault2 | epmfs | Important data (protected by SnapRAID) |
| `/mnt/storage/standard` | vault1 + vault2 | epmfs | Media, general storage (protected by SnapRAID) |
| `/mnt/storage/ephemeral` | vault1 + vault2 | ff | Downloads, cache (NOT protected) |

### SnapRAID Protection

- **Parity:** vault3 (11TB)
- **Protected:** critical & standard pools only
- **Excluded:** ephemeral (downloads, cache)
- **Sync schedule:** Weekly

## Services

### Media Stack (Priority Services)

1. **Jellyfin** (port 8096) - Media server
2. **Sonarr** (port 8989) - TV show management
3. **Radarr** (port 7878) - Movie management
4. **Lidarr** (port 8686) - Music management
5. **Readarr** (port 8787) - Book management
6. **Prowlarr** (port 9696) - Indexer manager
7. **Jellyseerr** (port 5055) - Request management
8. **Ombi** (port 3579) - Alternative request management

### Download Stack

- **qBittorrent** (ports 8080, 8081) - BitTorrent client
  - Two instances: brancengregory (8080) and qbt (8081)
  - BT ports: 6881, 6882
- **SABnzbd** (port 8090) - Usenet downloader

### AI/LLM Stack

- **Ollama** (port 11434) - LLM inference server
- **Open WebUI** (port 3000) - Web interface for LLMs
- Models stored in `/mnt/storage/critical/ollama`

### Git Server

- **Forgejo** (HTTP: 3080, SSH: 22) - Self-hosted Git forge
- Data in `/mnt/storage/critical/forgejo`
- Note: System SSH on port 77, Forgejo SSH on port 22

### Storage Services

- **Minio** (ports 9000, 9001) - S3-compatible object storage
- **NFS Server** (port 2049) - Network file sharing
  - Exports: `/mnt/storage/critical`, `/mnt/storage/standard`

### Monitoring

- **Grafana** (port 3000) - Metrics visualization
- **Prometheus** (port 9090) - Metrics collection
- **Node Exporter** (port 9100) - System metrics

### Networking

- **WireGuard** (port 51820) - VPN hub (IP: 10.0.0.1)
  - Hub-and-spoke topology
  - Also provides DNS for VPN clients

## Network Ports Summary

| Port | Service | Description |
|------|---------|-------------|
| 22 | Forgejo SSH | Git over SSH |
| 77 | System SSH | Remote access |
| 80/443 | HTTP/HTTPS | Web services |
| 2049 | NFS | Network file sharing |
| 3000 | Grafana / Open WebUI | Monitoring & AI UI |
| 3080 | Forgejo HTTP | Git web interface |
| 5055 | Jellyseerr | Media requests |
| 51820 | WireGuard | VPN |
| 8080/8081 | qBittorrent | Torrent clients |
| 8090 | SABnzbd | Usenet downloader |
| 8096 | Jellyfin | Media server |
| 9000/9001 | Minio | Object storage |
| 9090 | Prometheus | Metrics |

## Configuration Files

- `config.nix` - Main system configuration
- `hardware.nix` - Hardware-specific settings
- `disks.nix` - Disk partitioning (preserves existing LUKS vaults)

## Migration Plan (Data Preservation)

### Phase 1: Preparation

1. Backup critical data from `/home` to vault storage
2. Verify SnapRAID is synced: `sudo snapraid sync`
3. Note LUKS UUIDs and btrfs subvolume structure

### Phase 2: NixOS Installation

1. Boot NixOS USB on capacitor
2. Unlock existing LUKS volumes:
   ```bash
   cryptsetup open /dev/nvme0n1p2 cryptnvme0n1p2
   cryptsetup open /dev/sda crypt_vault1
   cryptsetup open /dev/sdb crypt_vault2
   cryptsetup open /dev/sdc crypt_vault3
   ```

3. Install NixOS with data preservation:
   ```bash
   nixos-install --flake .#capacitor
   ```

4. Set root password:
   ```bash
   passwd
   ```

### Phase 3: Post-Installation

1. Reboot into new system
2. Verify all vaults are mounted:
   ```bash
   lsblk
   df -h
   ```

3. Verify mergerfs pools:
   ```bash
   mount | grep mergerfs
   ls -la /mnt/storage/
   ```

4. Verify SnapRAID:
   ```bash
   sudo snapraid status
   ```

5. Restore home directory from backup (if needed)

6. Start services:
   ```bash
   systemctl status jellyfin
   systemctl status sonarr
   # etc.
   ```

### Phase 4: Service Migration

1. **Jellyfin:** Copy config from `/var/lib/jellyfin` (or restore from backup)
2. **Sonarr/Radarr/Lidarr/Readarr:** Restore database and config
3. **qBittorrent:** Restore `.config/qBittorrent` directories
4. **SABnzbd:** Restore config from backup
5. **Forgejo:** Data already in container volume

## Secrets Management

See `SECRETS_SETUP.md` for detailed instructions on:
- SSH host keys
- Age keys for SOPS
- WireGuard keys
- Minio credentials
- GPG keys

## Important Notes

1. **SSH Configuration:**
   - System SSH on port 77 (preserved from Arch)
   - Forgejo SSH on port 22
   - Both use different host keys

2. **Data Preservation:**
   - All LUKS headers are preserved
   - All btrfs subvolumes are preserved
   - MergerFS structure unchanged
   - SnapRAID configuration maintained

3. **Service Data Locations:**
   - Media: `/mnt/storage/standard/media/`
   - Downloads: `/mnt/storage/ephemeral/downloads/`
   - Configs: `/var/lib/` (various services)
   - Critical data: `/mnt/storage/critical/`

4. **Backup Strategy:**
   - SnapRAID protects critical & standard pools
   - Manual backups for `/home` and service configs
   - Consider restic to cloud for critical data

## Troubleshooting

### LUKS devices not unlocking
```bash
cryptsetup open /dev/sda crypt_vault1
cryptsetup open /dev/sdb crypt_vault2
cryptsetup open /dev/sdc crypt_vault3
```

### MergerFS pools not mounting
```bash
sudo systemctl restart local-fs.target
mount -a
```

### SnapRAID sync issues
```bash
sudo snapraid status
sudo snapraid sync
sudo snapraid scrub
```

### Service issues
```bash
# Check service status
systemctl status <service>

# View logs
journalctl -u <service> -f

# Restart service
systemctl restart <service>
```

## Maintenance

### Weekly
- Verify SnapRAID sync: `sudo snapraid status`
- Check disk health: `smartctl -a /dev/sd{a,b,c}`
- Review Grafana dashboards

### Monthly
- Scrub SnapRAID: `sudo snapraid scrub`
- Update NixOS: `nixos-rebuild switch --upgrade`
- Clean old Nix generations: `nix-collect-garbage -d`

### Annually
- Verify backup integrity
- Review and rotate secrets
- Update hardware firmware
