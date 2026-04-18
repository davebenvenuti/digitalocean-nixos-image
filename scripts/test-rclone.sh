#!/bin/bash
set -euo pipefail

# Test rclone configuration
# Assumes direnv has already loaded .env

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Rclone configuration
RCLONE_REMOTE="digitaloceanimages"  # Fixed remote name (no hyphens for env var compatibility)

echo "=== Testing rclone Configuration ==="
echo ""



echo "✓ rclone is installed: $(rclone version | head -1)"
echo ""

# Check for rclone configuration in .env
if [ -z "${RCLONE_PATH:-}" ]; then
    echo "⚠️  RCLONE_PATH not set in .env"
    echo "Add to .env: RCLONE_PATH=\"digitaloceanimages:digital-ocean-images\"  # remote:bucket/path"
    echo ""
fi

# List configured remotes
echo "Configured rclone remotes:"
echo "--------------------------"
rclone config show || echo "  (no remotes configured)"
echo ""

echo "Testing rclone remote: $RCLONE_REMOTE (fixed)"
echo "------------------------"

if rclone listremotes 2>/dev/null | grep -q "^${RCLONE_REMOTE}:"; then
    echo "✅ Remote '$RCLONE_REMOTE' is configured"
    echo ""
    
    # Test if remote is actually usable
    echo "Testing connection..."
    if rclone lsd "${RCLONE_REMOTE}:" > /dev/null 2>&1; then
        echo "✅ Successfully connected to $RCLONE_REMOTE!"
        echo ""
        
        # Show actual listing
        echo "Listing root directory:"
        rclone lsd "${RCLONE_REMOTE}:"
            
            # If RCLONE_PATH is set, test it
            if [ -n "${RCLONE_PATH:-}" ]; then
                echo ""
                echo "Testing path: $RCLONE_PATH"
                echo "----------------"
                
                # Extract remote and path from RCLONE_PATH
                REMOTE_PART=$(echo "$RCLONE_PATH" | cut -d':' -f1)
                PATH_PART=$(echo "$RCLONE_PATH" | cut -d':' -f2-)
                
                if [ "$REMOTE_PART" != "$RCLONE_REMOTE" ]; then
                    echo "⚠️  Warning: RCLONE_PATH remote ($REMOTE_PART) doesn't match fixed remote name ($RCLONE_REMOTE)"
                    echo "   RCLONE_PATH should start with: $RCLONE_REMOTE:"
                fi
                
                # List the path
                if rclone lsd "$RCLONE_PATH" 2>/dev/null; then
                    echo "✅ Path exists and is accessible"
                    echo ""
                    echo "Listing contents:"
                    rclone ls "$RCLONE_PATH" | head -10
                else
                    echo "⚠️  Path doesn't exist or not accessible"
                    echo "Creating it..."
                    if rclone mkdir "$RCLONE_PATH"; then
                        echo "✅ Path created successfully"
                    else
                        echo "❌ Failed to create path"
                    fi
                fi
            fi
    else
        echo "❌ Failed to connect to $RCLONE_REMOTE"
        echo ""
        echo "The remote exists in configuration but is not usable."
        echo "It may be incomplete or corrupted."
        echo "Check configuration: rclone config show $RCLONE_REMOTE"
        echo "Or reconfigure: rclone config"
    fi
else
    echo "❌ Remote '$RCLONE_REMOTE' not found in rclone configuration"
    echo ""
    echo "Configure it first: rclone config"
    echo "Or configure via environment variables in .env file (see .env.example)"
    echo ""
    echo "Available remotes:"
    rclone listremotes 2>/dev/null || echo "  (none configured)"
fi

echo ""
echo "✅ rclone configuration test complete!"
echo ""
echo "Supported backends for image upload:"
echo "- Backblaze B2 (b2)"
echo "- DigitalOcean Spaces (s3 or do)"
echo "- AWS S3 (s3)"
echo "- Google Cloud Storage (gcs)"
echo "- Azure Blob Storage (azureblob)"
echo "- Any HTTP server (http)"
echo ""
echo "You can now use './scripts/upload-nixos-image.sh' with rclone support."