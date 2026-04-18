#!/bin/bash
set -euo pipefail

# Upload NixOS image to DigitalOcean via rclone
# Assumes direnv is set up and nix shell has been loaded

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Rclone configuration
RCLONE_REMOTE="digitaloceanimages"  # Fixed remote name (no hyphens for env var compatibility)

echo "=== Uploading NixOS Image to DigitalOcean ==="
echo ""

# Simple validation - assumes environment variables are set
test "${DIGITALOCEAN_TOKEN:-}" || log_and_exit "DIGITALOCEAN_TOKEN not set. Ensure .env is set up (see .env.example for guidance)."

# Check if image is built
IMAGE_PATH=$(find_nixos_image digitalocean)
if [ $? -ne 0 ] || [ -z "$IMAGE_PATH" ] || [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Error: DigitalOcean NixOS image not found in $PROJECT_ROOT/result/"
    echo "Build the DigitalOcean image first:"
    echo "  nix build .#digitalocean-image"
    echo ""
    echo "Note: Only DigitalOcean images (.qcow2.gz) can be uploaded."
    echo "      Raw images (.img) are for local testing only."
    echo ""
    echo "You can also specify an image with NIXOS_IMAGE_PATH environment variable:"
    echo "  export NIXOS_IMAGE_PATH="/path/to/image.qcow2.gz""
    echo ""
    echo "Available files in result/:"
    ls -la "$PROJECT_ROOT/result/" 2>/dev/null || echo "  (directory not found)"
    exit 1
fi

IMAGE_FILENAME=$(basename "$IMAGE_PATH")
IMAGE_SIZE=$(du -h "$IMAGE_PATH" | cut -f1)

echo "✓ Image found: $IMAGE_FILENAME"
echo "  Size: $IMAGE_SIZE"
if [ -n "${NIXOS_IMAGE_PATH:-}" ]; then
    echo "  (Specified via NIXOS_IMAGE_PATH environment variable)"
fi
echo ""

# Authenticate doctl if needed
echo "Checking doctl authentication..."
if ! doctl account get > /dev/null 2>&1; then
    echo "🔐 Authenticating doctl..."
    if [ -n "${DIGITALOCEAN_TOKEN:-}" ]; then
        doctl auth init --access-token "$DIGITALOCEAN_TOKEN"
    else
        echo "⚠️  Please authenticate doctl manually:"
        echo "  doctl auth init"
        echo ""
        read -p "Press Enter after authenticating doctl..."
    fi
fi

if ! doctl account get > /dev/null 2>&1; then
    echo "❌ Failed to authenticate doctl"
    exit 1
fi

echo "✓ Authenticated as: $(doctl account get --format Email)"
echo ""

# Set default values
REGION="${REGION:-nyc3}"
IMAGE_NAME="${NIXOS_IMAGE_NAME:-nixos-base-$(date +%Y%m%d-%H%M%S)}"
IMAGE_DESCRIPTION="NixOS base image built on $(date)"

# Check if image already exists
echo "Checking for existing images..."
EXISTING_IMAGE=$(doctl compute image list --public false --format "ID,Name" | { grep "$IMAGE_NAME" || true; } | head -1 | awk '{print $1}')

if [ -n "$EXISTING_IMAGE" ]; then
    echo "✅ Image '$IMAGE_NAME' already exists (ID: $EXISTING_IMAGE)"
    echo ""

    # Update .env with the existing image name
    if [ -f ".env" ]; then
        if grep -q "^NIXOS_IMAGE_NAME=" .env; then
            # Update existing line
            sed -i "s/^NIXOS_IMAGE_NAME=.*/NIXOS_IMAGE_NAME=\"$IMAGE_NAME\"/" .env
        else
            # Add new line
            echo "NIXOS_IMAGE_NAME=\"$IMAGE_NAME\"" >> .env
        fi
        echo "✓ .env file updated with existing image name"
    else
        echo "⚠️  .env file not found. Please add:"
        echo "  NIXOS_IMAGE_NAME=\"$IMAGE_NAME\""
    fi

    echo ""
    echo "You can use this existing image for deployment."
    echo "Then run: make bootstrap"
    echo ""
    echo "If you want to rebuild and upload a new image:"
    echo "1. Delete the existing image first:"
    echo "   doctl compute image delete $EXISTING_IMAGE --force"
    echo "2. Run: nix build .#digitalocean-image && ./scripts/upload-nixos-image.sh"
    echo ""
    exit 0
fi

# Check for rclone configuration
if [ -z "${RCLONE_PATH:-}" ]; then
    echo "❌ rclone not configured in .env"
    echo ""
    echo "Configure rclone by adding to your .env file:"
    echo ""
    echo "1. Set RCLONE_PATH (remote:bucket format):"
    echo "   RCLONE_PATH=\"digitaloceanimages:digital-ocean-images\""
    echo ""
    echo "2. Configure rclone via environment variables (recommended):"
    echo "   See .env.example for examples:"
    echo "   - DigitalOcean Spaces"
    echo "   - AWS S3"
    echo "   - Backblaze B2"
    echo ""
    echo "3. Or configure via rclone config file:"
    echo "   Run: rclone config"
    echo ""
    exit 1
fi

echo "✓ rclone configuration:"
echo "  Remote: $RCLONE_REMOTE"
echo "  Path: $RCLONE_PATH"
echo ""

# Test if rclone remote is usable
echo "Checking rclone configuration..."
if ! rclone lsd "${RCLONE_REMOTE}:" > /dev/null 2>&1; then
    echo "❌ rclone remote '$RCLONE_REMOTE' is not configured or not usable"
    echo ""
    echo "Ensure .env is set up with rclone configuration (see .env.example for guidance)."
    exit 1
fi

echo "✅ Remote '$RCLONE_REMOTE' is configured and usable"
echo ""

# Upload the file
echo "📤 Uploading $IMAGE_FILENAME to $RCLONE_PATH..."
echo "This may take a few minutes depending on your connection..."
echo ""

# Upload to RCLONE_PATH - rclone will use the local filename
if rclone copy "$IMAGE_PATH" "$RCLONE_PATH" --progress; then
    echo "✅ Upload successful"
else
    echo "❌ Upload failed"
    exit 1
fi

# Get public URL
echo ""
echo "Getting public URL..."
PUBLIC_URL=""

# Get public URL for the uploaded file
# The file is at RCLONE_PATH with the local filename
FULL_REMOTE_PATH="${RCLONE_PATH}/${IMAGE_FILENAME}"
echo "Getting public URL..."
PUBLIC_URL=$(rclone link "$FULL_REMOTE_PATH")
if [ $? -eq 0 ] && [ -n "$PUBLIC_URL" ]; then
    echo "✅ Public URL: $PUBLIC_URL"
else
    echo "❌ Failed to get public URL from rclone"
    echo ""
    echo "Make sure your rclone remote is configured for public access."
    exit 1
fi

# Verify URL is accessible
echo ""
echo "🔍 Verifying URL is publicly accessible..."
if curl --head --silent --fail "$PUBLIC_URL" > /dev/null 2>&1; then
    echo "✅ URL is accessible"
else
    echo "❌ URL is not accessible: $PUBLIC_URL"
    echo ""
    echo "DigitalOcean cannot import from this URL."
    echo "Make sure your rclone remote is configured for public access."
    exit 1
fi

echo ""
echo "🖼️  Creating DigitalOcean image from URL..."
echo "  Name: $IMAGE_NAME"
echo "  Region: $REGION"
echo "  Description: $IMAGE_DESCRIPTION"
echo "  Source URL: $PUBLIC_URL"
echo ""

echo "This may take 5-10 minutes..."
if doctl compute image create \
    "$IMAGE_NAME" \
    --region "$REGION" \
    --image-description "$IMAGE_DESCRIPTION" \
    --image-url "$PUBLIC_URL"; then

    echo ""
    echo "✅ Image creation started!"
    echo ""
    echo "Note: It may take a few minutes for the image to be fully processed."
    echo "You can check status with:"
    echo "  doctl compute image list --public false | grep \"$IMAGE_NAME\""
    echo ""

    # Wait a bit and check status
    echo "Waiting 30 seconds, then checking status..."
    sleep 30

    IMAGE_STATUS=$(doctl compute image list --public false | grep "$IMAGE_NAME" | awk '{print $4}')
    if [ "$IMAGE_STATUS" = "available" ]; then
        echo "✅ Image is ready for deployment!"
    else
        echo "⚠️  Image status: $IMAGE_STATUS"
        echo "   It may still be processing. Check again in a few minutes."
    fi

    echo ""
    echo "📝 Your .env file has been automatically updated with:"
    echo "  NIXOS_IMAGE_NAME=\"$IMAGE_NAME\""
    echo ""

    # Update .env file with image name
    if [ -f "$PROJECT_ROOT/.env" ]; then
        if grep -q "^NIXOS_IMAGE_NAME=" "$PROJECT_ROOT/.env"; then
            sed -i "s|^NIXOS_IMAGE_NAME=.*|NIXOS_IMAGE_NAME=\"$IMAGE_NAME\"|" "$PROJECT_ROOT/.env"
        else
            echo "NIXOS_IMAGE_NAME=\"$IMAGE_NAME\"" >> "$PROJECT_ROOT/.env"
        fi
        echo "✅ .env file updated"
    else
        echo "⚠️  .env file not found. Please add to your .env:"
        echo "  NIXOS_IMAGE_NAME=\"$IMAGE_NAME\""
    fi

    echo ""
    echo "Now bootstrap with: make bootstrap"
    echo ""

else
    echo "❌ Failed to create DigitalOcean image"
    echo ""
    echo "Possible issues:"
    echo "1. URL is not publicly accessible"
    echo "2. Image format not supported"
    echo "3. Region not available"
    echo ""
    echo "Check the URL: curl -I \"$PUBLIC_URL\""
    exit 1
fi

echo ""
echo "✅ Upload process complete!"
echo ""
echo "To list all custom images:"
echo "  doctl compute image list --public false"
