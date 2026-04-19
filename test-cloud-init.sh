#!/bin/bash
set -euo pipefail

# Test cloud-init with QEMU
# Creates a cloud-init ISO with generated SSH keys and boots the raw image

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
IMAGE_PATH="$PROJECT_ROOT/result/nixos.img"
TEST_DIR="$PROJECT_ROOT/test-cloud-init"
ISO_PATH="$TEST_DIR/cloud-init.iso"
PRIVATE_KEY="$TEST_DIR/test-key"
PUBLIC_KEY="$PRIVATE_KEY.pub"

echo "=== Testing Cloud-Init with QEMU ==="
echo ""

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "❌ Raw image not found at: $IMAGE_PATH"
    echo "Build it first: nix build .#raw-image"
    exit 1
fi

echo "✓ Raw image found: $IMAGE_PATH"
echo ""

# Create test directory
mkdir -p "$TEST_DIR"

# Generate SSH key pair for testing
echo "Generating SSH key pair for testing..."
if [ -f "$PRIVATE_KEY" ]; then
    echo "  Using existing test key"
else
    ssh-keygen -t ed25519 -f "$PRIVATE_KEY" -N "" -q
    echo "  ✓ Generated new test key pair"
fi

PUBLIC_KEY_CONTENT=$(cat "$PUBLIC_KEY")
echo "  Public key fingerprint: $(ssh-keygen -l -f "$PUBLIC_KEY" | cut -d' ' -f2)"
echo ""

# Create cloud-init user-data
# This simulates what DigitalOcean would provide
echo "Creating cloud-init configuration..."
cat > "$TEST_DIR/user-data" << EOF
#cloud-config
users:
  - name: root
    ssh-authorized-keys:
      - $PUBLIC_KEY_CONTENT
chpasswd:
  list: |
    root:test123
  expire: false
EOF

# Create cloud-init meta-data
cat > "$TEST_DIR/meta-data" << 'EOF'
instance-id: i-test-001
local-hostname: nixos-test
EOF

echo "✓ Created cloud-init configuration:"
echo "  - user-data: SSH key for root user (generated test key)"
echo "  - meta-data: instance metadata"
echo ""

# Create ISO with cloud-init data
echo "Creating cloud-init ISO..."
if command -v genisoimage >/dev/null 2>&1; then
    genisoimage -output "$ISO_PATH" -volid cidata -joliet -rock "$TEST_DIR/user-data" "$TEST_DIR/meta-data" 2>/dev/null
elif command -v mkisofs >/dev/null 2>&1; then
    mkisofs -output "$ISO_PATH" -volid cidata -joliet -rock "$TEST_DIR/user-data" "$TEST_DIR/meta-data" 2>/dev/null
else
    echo "❌ Need genisoimage or mkisofs to create cloud-init ISO"
    echo "Install with: nix-shell -p cdrtools"
    exit 1
fi

echo "✓ Created cloud-init ISO: $ISO_PATH"
echo ""

# Start QEMU with cloud-init ISO
echo "Starting QEMU with cloud-init..."
echo "The VM will boot with cloud-init data from the ISO."
echo "Once booted, you should be able to SSH with the generated test key."
echo ""
echo "To SSH in another terminal:"
echo "  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \\"
echo "      -i $PRIVATE_KEY -p 2222 root@localhost"
echo ""
echo "Password for root (if SSH key doesn't work): test123"
echo ""
echo "Test key location:"
echo "  Private: $PRIVATE_KEY"
echo "  Public:  $PUBLIC_KEY"
echo ""
echo "Press Ctrl+C to stop QEMU when done."
echo ""

qemu-system-x86_64 \
  -m 2048 \
  -drive "file=$IMAGE_PATH,format=raw" \
  -cdrom "$ISO_PATH" \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic \
  -serial mon:stdio

echo ""
echo "=== Test complete ==="
echo ""
echo "Note: Test files are preserved in $TEST_DIR/"
echo "      Run this script again to reuse the same key pair."