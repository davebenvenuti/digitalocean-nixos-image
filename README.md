# NixOS DigitalOcean Base Image Builder

A self-contained Nix flake for building and uploading general-purpose NixOS base images to DigitalOcean droplets. Built images can be uploaded to any configured remote using `rclone`.

## Features

- **Build NixOS images** in DigitalOcean (`do`) format
- **Build raw images** for local testing with QEMU
- **Upload to any remote** using `rclone` (DigitalOcean Spaces, S3, Google Cloud, etc.)
- **Self-contained development environment** with all required tools
- **Direnv integration** for automatic environment setup
- **Flexible configuration** via environment variables

## Quick Start

1. **Clone and enter the directory:**
   ```bash
   cd digitalocean-base-image
   ```

2. **Set up environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Enter development shell:**
   ```bash
   direnv allow
   # Automatically loads the Nix development shell
   ```

4. **Build the DigitalOcean image:**
   ```bash
   nix build .#digitalocean-image
   ```

5. **Upload using rclone:**
   ```bash
   ./scripts/upload-nixos-image.sh
   ```

## Core Workflow

### 1. Build the Image
The `digitalocean-image` task in the flake builds a NixOS image in DigitalOcean's required format:

```bash
nix build .#digitalocean-image
```

Built images are available at `result/nixos-image-digital-ocean-*.qcow2.gz`.

### 2. Configure rclone Remote
Configure your storage remote (DigitalOcean Spaces, S3, etc.):

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add rclone configuration via environment variables.
   See examples in `.env.example` for:
   - DigitalOcean Spaces
   - AWS S3
   - Backblaze B2

### 3. Upload to Remote
Upload the built image using rclone:

```bash
./scripts/upload-nixos-image.sh
```

## Configuration

### Environment Variables (.env)

Create a `.env` file based on `.env.example`:

```bash
# Required: DigitalOcean API token (for doctl operations)
DIGITALOCEAN_TOKEN="your_digitalocean_api_token_here"

# Required for rclone upload: Remote configuration
RCLONE_PATH="digitaloceanimages:digital-ocean-images"  # remote:bucket/path format
# Remote name is fixed as "digitaloceanimages" (no hyphens for env var compatibility)

# Optional: Custom image name
# NIXOS_IMAGE_NAME="nixos-base-custom"

# Optional: Image description
# IMAGE_DESCRIPTION="NixOS base image built on $(date)"

# Optional: Image tags (comma-separated)
# IMAGE_TAGS="nixos,base,digitalocean"

# Optional: DigitalOcean region for image upload
# Default: nyc3
# REGION="nyc3"

# Optional: Specific image path to use
# If not set, script will find newest DigitalOcean image in result/ directory
# NIXOS_IMAGE_PATH="/path/to/specific/image.qcow2.gz"
```

### Image Configuration

The base NixOS configuration is in `configuration.nix`. This is a general-purpose server configuration with:

- **Essential packages**: vim, htop, curl, git, jq, tmux
- **SSH**: Key-based authentication only
- **Container runtime**: Podman with podman-compose
- **Web server**: Caddy for reverse proxy (not configured by default)
- **System maintenance**: Automatic weekly garbage collection
- **Security hardening**: Firewall with SSH only, sudo without password for wheel group

## Usage Examples

### Build Only (No Upload)
```bash
# Build DigitalOcean image
nix build .#digitalocean-image

# Build raw image for testing
nix build .#raw-image
```

### Test Image Locally with QEMU
```bash
# Build raw image
nix build .#raw-image

# Test with QEMU
qemu-system-x86_64 -m 2048 -drive file=result/nixos.img,format=raw
```

### Upload to DigitalOcean Spaces (via rclone)
```bash
# Configure rclone via environment variables in .env
# See .env.example for DigitalOcean Spaces configuration

# Build and upload
nix build .#digitalocean-image
./scripts/upload-nixos-image.sh
```

### Upload to AWS S3 (via rclone)
```bash
# Configure rclone for AWS S3
rclone config
# Set RCLONE_PATH in .env (remote name is fixed as "digitaloceanimages")

# Build and upload
nix build .#digitalocean-image
./scripts/upload-nixos-image.sh
```

## Scripts

- `scripts/upload-nixos-image.sh` - Main upload script (supports rclone to any remote)
  - Automatically finds the newest DigitalOcean image (`*.qcow2.gz`) in `result/` directory
  - Can be overridden with `NIXOS_IMAGE_PATH` environment variable
  - Only uploads DigitalOcean images, not raw images (use raw images for local testing only)
  - **Note**: Assumes direnv has loaded `.env` and nix shell provides required tools
- `scripts/test-doctl.sh` - Test doctl configuration
- `scripts/test-rclone.sh` - Test rclone configuration
- `scripts/lib.sh` - Shared script functions

## For LLM/Agent Development

See `AGENTS.md` for instructions specific to AI-assisted development in this repository.

## Supported rclone Remotes

The upload script works with any rclone-compatible remote:

- **DigitalOcean Spaces** (recommended for DigitalOcean integration)
- **AWS S3** and compatible services
- **Google Cloud Storage**
- **Azure Blob Storage**
- **Backblaze B2**
- **SFTP/SSH**
- **Local filesystem**

## Development Environment

The flake provides a development shell with all required tools:

- **Image building**: `nixos-generators`, `qemu`, `parted`
- **Cloud tools**: `doctl`, `rclone`
- **Utilities**: `gzip`, `zstd`, `openssh`

Enter the shell with:
```bash
nix develop
# or automatically via direnv
```

## Image Creation Process

1. **Configuration**: `configuration.nix` defines the NixOS system
2. **Building**: `nixos-generators` creates the image in DigitalOcean format
3. **Compression**: Image is compressed for upload
4. **Upload**: `rclone` transfers the image to configured remote
5. **Import**: `doctl` imports the image to DigitalOcean (if using DigitalOcean Spaces)

## Customization

### Modify Base Configuration
Edit `configuration.nix` to add packages, services, or system settings:

```nix
# Add custom packages
environment.systemPackages = with pkgs; [
  # ... existing packages
  docker
  nodejs
  python3
];

# Enable additional services
services.nginx.enable = true;
services.postgresql.enable = true;
```

### Create Custom Image Variants
Create new flake outputs for different image types:

```nix
# Add to flake.nix outputs.packages.x86_64-linux
custom-image = nixos-generators.nixosGenerate {
  system = "x86_64-linux";
  format = "do";
  modules = [
    ./configuration.nix
    ./custom-configuration.nix  # Additional configuration
  ];
};
```

### SSH Key Management with Cloud-Init

The image uses **cloud-init** to inject SSH keys from cloud provider metadata. This is the standard way DigitalOcean and other cloud providers handle SSH key injection.

#### For DigitalOcean Droplets:
1. Add your SSH public key to your DigitalOcean account
2. Select the key when creating a droplet from this image
3. Cloud-init will automatically add the key to the root user's `authorized_keys`

#### For Local Testing with QEMU:
You can test cloud-init locally using the provided test script:

```bash
# Make sure you have cdrtools installed for ISO creation
nix-shell -p cdrtools

# Run the test script
./test-cloud-init.sh
```

The test script creates a cloud-init ISO with test SSH keys and boots the image in QEMU.

#### Manual Cloud-Init Configuration:
If you need to embed SSH keys directly in the image (not recommended for production), you can modify `configuration.nix`:

```nix
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... user@host"
];
```

**Note**: For production use with DigitalOcean, rely on cloud-init and add your keys via the DigitalOcean dashboard.

## Troubleshooting

### rclone Configuration Issues
```bash
# Test rclone configuration
./scripts/test-rclone.sh

# Configure via environment variables (recommended)
# Edit .env file (see .env.example for examples)

# Or configure via rclone config file
rclone config
```

### doctl Authentication
```bash
# Test doctl configuration
./scripts/test-doctl.sh

# Authenticate manually
doctl auth init
```

### Image Building Problems
```bash
# Check flake evaluation
nix flake check

# Build with verbose output
nix build .#digitalocean-image --verbose

# Check available disk space
df -h
```

### Upload Script Issues
```bash
# Run with debug output
bash -x ./scripts/upload-nixos-image.sh

# Check environment variables
env | grep -E "(DIGITALOCEAN|RCLONE|NIXOS)"
```

## Best Practices

1. **Use version control**: Commit your `configuration.nix` changes
2. **Test locally**: Use raw images with QEMU before uploading
3. **Tag images**: Use descriptive tags for organization
4. **Monitor costs**: Large images incur storage costs
5. **Clean up**: Remove old images from your remote storage

## Security Considerations

- The base image uses key-based SSH authentication only
- Root login is prohibited (password authentication disabled)
- Firewall allows only SSH by default
- Regular security updates via NixOS channel
- SSH keys are injected via cloud-init from cloud provider metadata
- Cloud-init enables automatic SSH key management from DigitalOcean dashboard

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `nix flake check`
5. Submit a pull request