#!/usr/bin/env bash
# Script to migrate secrets from chezmoi to SOPS

set -e

echo "=== Chezmoi to SOPS Migration Helper ==="
echo ""

# Check if gpg is available
if ! command -v gpg &> /dev/null; then
    echo "❌ Error: gpg is not installed"
    exit 1
fi

# Decrypt the chezmoi .Renviron file
CHEZMOI_ENV="$HOME/.local/share/chezmoi/encrypted_dot_Renviron.asc"
TEMP_FILE=$(mktemp)

echo "🔓 Decrypting chezmoi .Renviron..."
if [ -f "$CHEZMOI_ENV" ]; then
    gpg -d "$CHEZMOI_ENV" > "$TEMP_FILE" 2>/dev/null || {
        echo "❌ Failed to decrypt. Make sure your GPG key is available."
        rm -f "$TEMP_FILE"
        exit 1
    }
else
    echo "❌ Chezmoi .Renviron not found at $CHEZMOI_ENV"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Extract API keys
echo ""
echo "=== Extracted API Keys ==="
echo "Copy these values into secrets/secrets.yaml under the 'renviron' section:"
echo ""

# Read and format the decrypted content
while IFS= read -r line; do
    if [[ "$line" =~ ^[A-Z].*= ]]; then
        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)
        echo "  $key=$value"
    fi
done < "$TEMP_FILE"

# Cleanup
rm -f "$TEMP_FILE"

echo ""
echo "=== Next Steps ==="
echo "1. Review secrets/secrets.template.yaml"
echo "2. Copy it to secrets/secrets.yaml"
echo "3. Paste the API keys from above into the 'renviron' section"
echo "4. Update other secrets as needed"
echo "5. Encrypt: sops -e -i secrets/secrets.yaml"
echo "6. Build: mise build-turbine"
echo ""
echo "⚠️  IMPORTANT: Never commit unencrypted secrets!"
