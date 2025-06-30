# Unified GPG/SSH Strategy

This document outlines the comprehensive GPG/SSH configuration implemented across the entire nix-config ecosystem, providing secure, unified authentication and encryption for both Linux (powerhouse) and macOS (turbine) systems.

## Overview

The strategy implements a modern, secure approach where:

- **GPG agent serves as the central authentication hub** for both GPG operations and SSH authentication
- **Cross-platform compatibility** ensures consistent behavior on Linux and macOS  
- **Security best practices** with modern algorithms and strong defaults
- **Unified configuration** managed through home-manager for consistency

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GPG Client    │    │   SSH Client    │    │   Git (signed)  │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼──────────────┐
                    │        GPG Agent          │
                    │  ┌─────────────────────┐   │
                    │  │ GPG Authentication  │   │
                    │  │ SSH Authentication  │   │
                    │  │ Key Management      │   │
                    │  │ Smart Card Support  │   │
                    │  └─────────────────────┘   │
                    └────────────────────────────┘
```

## Key Features

### Security Configuration

- **Modern Algorithms**: AES256, SHA512, Ed25519
- **Strong Defaults**: Disable weak ciphers (3DES, SHA1)
- **Key Security**: 8-24 hour cache TTL, secure passphrase requirements
- **SSH Hardening**: Disabled password auth, modern cipher suites

### Cross-Platform Support

- **Linux**: GTK-based pinentry, systemd socket integration
- **macOS**: Native pinentry, proper socket discovery
- **Unified Environment**: Consistent GPG_TTY and SSH_AUTH_SOCK setup

### Integration Features

- **Git Signing**: Automatic commit signing with GPG
- **SSH Authentication**: GPG keys used for SSH instead of separate SSH keys
- **Smart Card Support**: Hardware token integration ready
- **Agent Management**: Automatic startup and proper TTY handling

### Tmux Configuration

The strategy includes optimized tmux configuration with:

```nix
programs.tmux = {
  enable = true;
  # GPG/SSH integration improvements
  extraConfig = ''
    # Ensure environment variables are passed to new panes
    set-option -g update-environment "DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION SSH_AUTH_SOCK WINDOWID XAUTHORITY GPG_TTY"
    
    # Hook to update GPG_TTY when switching panes
    set-hook -g pane-focus-in 'run-shell "[ -n \"$TMUX\" ] && export GPG_TTY=$(tty) && gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true"'
  '';
};
```

This ensures:
- Environment variables are properly inherited in new tmux panes
- GPG_TTY is automatically updated when switching between panes
- SSH authentication works consistently across all tmux sessions

## Configuration Files

The strategy is implemented across several configuration files:

- **`users/brancengregory/home.nix`**: Main GPG/SSH configuration
- **Environment variables**: Cross-platform GPG agent integration
- **Platform-specific**: Pinentry and socket configuration

## Initial Setup

### 1. Generate GPG Master Key

```bash
# Generate a new GPG key with strong settings
gpg --full-gen-key

# Choose:
# (1) RSA and RSA (default) or (9) ECC and ECC
# Key size: 4096 bits (RSA) or Curve 25519 (ECC)  
# Valid for: 1-2 years (recommended)
# Real name: Brancen Gregory
# Email: brancengregory@gmail.com
```

### 2. Generate SSH Authentication Subkey

```bash
# Add SSH authentication capability to your GPG key
gpg --edit-key brancengregory@gmail.com

# In GPG prompt:
gpg> addkey
# Choose (8) RSA (set your own capabilities)
# Toggle off Sign and Encrypt, toggle on Authenticate
# Or choose (10) ECC (set your own capabilities) for Ed25519

gpg> save
```

### 3. Export SSH Public Key

```bash
# Export SSH public key from GPG
gpg --export-ssh-key brancengregory@gmail.com

# Add this to GitHub, GitLab, servers, etc.
```

### 4. Configure Git Signing

```bash
# Set your GPG signing key (if not using default)
git config --global user.signingkey YOUR_GPG_KEY_ID

# Verify signing works
git commit --allow-empty -m "Test GPG signing"
git log --show-signature -1
```

## Tmux Integration

The configuration includes comprehensive tmux support to ensure GPG and SSH work seamlessly within tmux sessions.

### Tmux-Specific Features

- **Dynamic GPG_TTY**: Automatically updates when switching tmux panes
- **SSH agent socket management**: Ensures consistent SSH authentication in tmux
- **Pinentry compatibility**: Configured to work properly with tmux sessions
- **Automatic hooks**: Updates GPG agent state when switching panes

### Usage in Tmux

```bash
# Start tmux session
tmux new-session -s work

# SSH from within tmux (works seamlessly)
ssh git@github.com

# Git operations work with automatic signing
git commit -m "Update from tmux session"
git push

# If you encounter issues, refresh GPG state
refresh_gpg
```

### Troubleshooting Tmux Issues

If you encounter pinentry or authentication issues in tmux:

```bash
# Check GPG agent status
gpg-status

# Restart GPG agent if needed  
gpg-restart

# Manually refresh GPG state in current pane
gpg-refresh

# Check SSH keys are loaded
ssh-keys

# Verify SSH socket is correct
echo $SSH_AUTH_SOCK
```

## Daily Usage

### SSH Authentication

With the unified strategy, SSH authentication works seamlessly:

```bash
# SSH uses your GPG key automatically
ssh git@github.com

# SSH to personal servers
ssh user@server.com
```

### GPG Operations

Standard GPG operations work as expected:

```bash
# Encrypt files
gpg --encrypt --recipient brancengregory@gmail.com file.txt

# Sign files
gpg --sign file.txt

# Decrypt/verify
gpg --decrypt file.txt.gpg
```

### Git Integration

Git automatically signs commits with your GPG key:

```bash
# Commits are automatically signed
git commit -m "Update configuration"

# Verify signatures
git log --show-signature
```

## Key Management

### Backup Strategy

```bash
# Export your master key (keep this VERY secure)
gpg --export-secret-keys --armor brancengregory@gmail.com > private-key-backup.asc

# Export public key (safe to share)
gpg --export --armor brancengregory@gmail.com > public-key.asc

# Export revocation certificate
gpg --gen-revoke brancengregory@gmail.com > revocation-cert.asc
```

### Key Rotation

Plan to rotate keys periodically:

1. **Annual Review**: Check key expiration and usage
2. **Subkey Rotation**: Rotate subkeys more frequently than master key
3. **Revocation**: Have revocation certificates ready for emergency use

## Troubleshooting

### GPG Agent Issues

```bash
# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Check agent status
gpg-connect-agent 'keyinfo --list' /bye

# Use helpful aliases
gpg-restart  # Restart agent
gpg-status   # Check status
gpg-refresh  # Refresh in tmux pane
```

### SSH Authentication Problems

```bash
# Check SSH agent socket
echo $SSH_AUTH_SOCK

# List loaded SSH keys (should show GPG key)
ssh-add -l

# Force GPG agent refresh
gpg-connect-agent updatestartuptty /bye

# Use aliases for quick checks
ssh-keys     # List SSH keys
```

### Tmux-Specific Issues

**Problem**: Pinentry appears in wrong pane or doesn't appear at all

```bash
# Solution 1: Refresh GPG state in current pane
refresh_gpg

# Solution 2: Restart GPG agent completely  
gpg-restart

# Solution 3: Check GPG_TTY is set correctly
echo $GPG_TTY
```

**Problem**: SSH authentication fails in tmux but works outside

```bash
# Check SSH socket in tmux session
echo $SSH_AUTH_SOCK

# Verify the socket file exists
ls -la $SSH_AUTH_SOCK

# If socket is missing, restart the session or refresh
refresh_gpg
```

**Problem**: Git signing fails in tmux

```bash
# Check GPG agent can sign
echo "test" | gpg --clearsign

# Refresh GPG state if needed
refresh_gpg

# Test Git signing explicitly
git commit --allow-empty -m "Test commit" --gpg-sign
```

### Platform-Specific Issues

**Linux:**
```bash
# Check XDG runtime directory
echo $XDG_RUNTIME_DIR

# Verify socket exists
ls -la $XDG_RUNTIME_DIR/gnupg/
```

**macOS:**
```bash
# Check GPG agent socket
gpgconf --list-dirs agent-ssh-socket

# Verify agent is running
gpgconf --check-programs
```

## Security Considerations

### Best Practices

1. **Strong Passphrases**: Use long, unique passphrases for GPG keys
2. **Limited Scope**: Use separate subkeys for different purposes
3. **Regular Rotation**: Plan key rotation schedule
4. **Secure Storage**: Keep master key backup in secure location
5. **Revocation Ready**: Maintain current revocation certificates

### Trust Model

- **Web of Trust**: Participate in key signing when appropriate
- **Key Verification**: Always verify key fingerprints out-of-band
- **Certificate Authorities**: Consider using keyserver certificates for verification

## Hardware Tokens

The configuration supports hardware tokens (YubiKey, etc.):

1. **Smart Card Support**: `enableScDaemon = true` in GPG agent
2. **Key Generation**: Generate keys directly on hardware token
3. **Backup Strategy**: Ensure backup authentication methods

## Integration with Services

### GitHub/GitLab

1. Add your SSH public key to your profile
2. Commits will be automatically signed
3. SSH authentication works seamlessly

### Personal Servers

1. Add SSH public key to `~/.ssh/authorized_keys`
2. Configure host-specific settings in SSH config
3. Optionally use GPG for server encryption/signing

## Maintenance

### Regular Tasks

- **Weekly**: Check agent status and key usage
- **Monthly**: Review SSH connections and Git signatures  
- **Quarterly**: Review key expiration dates
- **Annually**: Consider key rotation and security review

### Monitoring

The configuration includes logging and monitoring capabilities:

- GPG agent logs authentication attempts
- SSH client logs connection details
- Git maintains signature verification history

## Migration Guide

### From Existing SSH Keys

1. **Backup current SSH keys**
2. **Generate GPG authentication subkey**
3. **Update authorized_keys on servers**
4. **Test SSH authentication with GPG**
5. **Remove old SSH keys once verified**

### From Existing GPG Setup

1. **Export current keys**
2. **Apply new home-manager configuration**
3. **Import keys to new agent**
4. **Verify functionality**
5. **Update any custom configurations**

## Further Reading

- [GPG Documentation](https://gnupg.org/documentation/)
- [SSH Protocol Specification](https://tools.ietf.org/html/rfc4251)
- [Git Signing Documentation](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)