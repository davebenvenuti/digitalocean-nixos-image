# TODOs for DigitalOcean NixOS Image

## ✅ 1. Switch to nixos-generators with cloud-init
- ✓ Use nixos-generators with format="do" (proven working in other project)
- ✓ Enable cloud-init service for SSH key injection
- ✓ Keep SSH keys array empty (cloud-init populates from metadata)
- ✓ Rebuild and upload test image: nixos-base-cloud-init-test

## 🔄 2. Test SSH key injection with actual DigitalOcean droplet
- Image uploading in progress...
- Once uploaded, create test droplet with SSH key from DigitalOcean dashboard
- Verify SSH access works via cloud-init
- Debug if any issues

## ✅ 3. Simplify project
- ✅ Remove raw image builder and QEMU dependencies
- ✅ Remove test scripts
- ✅ Update documentation
- ✅ Focus on DigitalOcean image building only

## Current Status:
Switched back to proven approach from working project:
- Using `nixos-generators` with `format = "do"`
- Cloud-init enabled for SSH key injection
- Image being uploaded: `nixos-base-cloud-init-test`

Next: Test droplet creation once image is available.