# LLM Agent Instructions for DigitalOcean NixOS Image Builder

This repository uses a simplified workflow that assumes proper environment setup via direnv.

## Key Assumptions

1. **direnv is configured** - The `.envrc` file automatically loads the development shell and `.env` file
2. **Nix shell provides tools** - All required tools (`doctl`, `rclone`, etc.) are available via `nix develop`
3. **Environment is pre-loaded** - Scripts assume `.env` has been loaded by direnv

## Working with Scripts

### Upload Script (`scripts/upload-nixos-image.sh`)
- No longer manually sources `.env` (assumes direnv loaded it)
- No explicit checks for `rclone` or `doctl` (assumes nix shell provides them)
- Simplified error messages that direct users to check `.env` setup

### Testing Scripts
- `scripts/test-doctl.sh` - Tests doctl configuration
- `scripts/test-rclone.sh` - Tests rclone configuration
- Both assume direnv has loaded the environment

## Environment Setup

Users should:
1. Copy `.env.example` to `.env`
2. Fill in required values (DigitalOcean token, rclone config)
3. Ensure direnv is installed and allowed (`direnv allow`)
4. Enter the directory (direnv automatically loads environment)

## Common Tasks for LLMs

### When Making Changes to Scripts
- Remove manual `.env` loading logic
- Assume tools are available via nix shell
- Use simplified error messages that reference `.env.sample`
- Update documentation to reflect direnv-based workflow

### When Helping Users
- First check if `.envrc` exists and is allowed
- Verify `.env` file is properly configured
- Remind users to reload direnv after changes: `direnv reload`

### When Testing Changes
- Run scripts from within the nix shell
- Ensure environment variables are properly set
- Use the test scripts to verify configuration

## Error Handling

Scripts now use simplified error messages:
- Instead of detailed configuration instructions, direct users to `.env.sample`
- Assume users understand the direnv/nix workflow
- Focus on the specific missing configuration rather than tool installation

## Example Workflow for Users

```bash
# Clone repository
git clone <repo-url>
cd digitalocean-nixos-image

# Setup environment
cp .env.example .env
# Edit .env with your credentials

# Allow direnv
direnv allow

# Build image
nix build .#digitalocean-image

# Upload image
./scripts/upload-nixos-image.sh [image-name]
```

## For LLM Agents

When working in this repository:
1. Don't add manual `.env` loading to scripts
2. Don't check for tool availability (assume nix shell)
3. Keep error messages concise and reference `.env.sample`
4. Follow existing patterns in simplified scripts