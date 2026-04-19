# TODOs for Cloud-Init SSH Key Fix

## ✅ 1. Update test-cloud-init.sh to generate SSH key automatically
- ✓ Generate temporary SSH key pair for testing
- ✓ Make test script self-contained and reproducible
- ✓ Use generated key in cloud-init configuration
- ✓ Include instructions for using the private key to SSH
- **REMOVED**: Raw image testing removed due to complexity

## 🔄 2. Fix cloud-init configuration issue
- ✓ Enable cloud-init network configuration
- ✓ Fix networkd/DHCP conflict
- ✗ Test shows SSH keys not being injected
- Need to verify cloud-init works with DigitalOcean metadata service

## 🔄 3. Research proper DigitalOcean cloud-init configuration for NixOS
- Find correct datasource configuration for DigitalOcean
- Ensure DigitalOcean metadata service compatibility
- Test with actual DigitalOcean droplets

## 🆕 4. Simplify project
- ✅ Remove raw image builder and QEMU dependencies
- ✅ Update documentation
- Focus on DigitalOcean image building only