#!/bin/bash
set -euo pipefail

# Test doctl availability and configuration
# Assumes direnv has already loaded .env

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "=== Testing doctl Configuration ==="
echo ""

# Test 1: Check if doctl is installed
echo "Test 1: Checking doctl installation..."
command -v doctl >/dev/null 2>&1 || log_and_exit "doctl is not installed. Ensure you're in the nix development shell."
echo "✓ doctl is installed: $(doctl version)"
echo ""

# Test 2: Check authentication
echo "Test 2: Checking doctl authentication..."
if ! doctl account get > /dev/null 2>&1; then
    echo "⚠️  doctl is not authenticated"
    echo ""
    echo "To authenticate:"
    echo "  1. Get your DigitalOcean API token from:"
    echo "     https://cloud.digitalocean.com/account/api/tokens"
    echo "  2. Run: doctl auth init"
    echo "  3. Enter your API token when prompted"
    echo ""
    echo "You can also set the token via environment variable:"
    echo "  export DIGITALOCEAN_TOKEN=\"your_token_here\""
    echo "  doctl auth init --access-token \"\$DIGITALOCEAN_TOKEN\""
else
    echo "✓ doctl is authenticated"
    echo "  Account: $(doctl account get --format Email)"
fi
echo ""

# Test 3: Check image upload capability
echo "Test 3: Testing image upload prerequisites..."
echo "To upload a NixOS image to DigitalOcean, you need:"
echo "  1. A built NixOS image: nix build .#digitalocean-image"
echo "  2. Sufficient permissions (Write access)"
echo "  3. Available image slots (DigitalOcean limits)"
echo ""
echo "Example upload command:"
echo "  doctl compute image create \\"
echo "    \"nixos-base-\$(date +%Y%m%d)\" \\"
echo "    --region nyc3 \\"
echo "    --image-url file://path/to/nixos.img.tar.gz"
echo ""

# Test 4: List existing images (if authenticated)
if doctl account get > /dev/null 2>&1; then
    echo "Test 4: Listing existing DigitalOcean images..."
    echo "Existing custom images:"
    if ! doctl compute image list --public false --format "Name,Type,Distribution,Slug,MinDiskSize" 2>/dev/null | grep -v "Public" | head -10; then
        echo "  (No custom images found or unable to list)"
    fi
fi

echo ""
echo "=== doctl Test Complete ==="
echo ""
echo "Next steps for NixOS image building:"
echo "  1. Build image: nix build .#digitalocean-image"
echo "  2. Upload image: ./scripts/upload-nixos-image.sh"
echo "  3. Or use doctl command above for manual upload"