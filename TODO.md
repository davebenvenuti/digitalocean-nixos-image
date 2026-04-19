# TODOs for Cloud-Init SSH Key Fix

## ✅ 1. Update test-cloud-init.sh to generate SSH key automatically
- ✓ Generate temporary SSH key pair for testing
- ✓ Make test script self-contained and reproducible
- ✓ Use generated key in cloud-init configuration
- ✓ Include instructions for using the private key to SSH

## 🔄 2. Fix cloud-init configuration issue before testing
- ✓ Enable cloud-init network configuration
- ✓ Fix networkd/DHCP conflict
- ✗ Test shows SSH keys not being injected
- Need to debug cloud-init NoCloud datasource setup

## 🔄 3. Research proper DigitalOcean cloud-init configuration for NixOS
- Find correct datasource configuration for DigitalOcean
- Ensure DigitalOcean metadata service compatibility
- Update `.#digitalocean-image` flake build target as needed
- Test with actual DigitalOcean droplets