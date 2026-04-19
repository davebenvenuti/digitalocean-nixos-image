{ config, lib, pkgs, ... }:
{
  # Basic system configuration
  system.stateVersion = "24.11";

  # Essential packages for a general-purpose server
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    git
    jq
    tmux
    ncdu
    lsof
    netcat
    bind.dnsutils
    iputils
    podman
    podman-compose
    caddy
  ];

  # Automatic upgrades (optional)
  system.autoUpgrade = {
    enable = false; # Disabled by default for production
    allowReboot = false;
    dates = "weekly";
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Security hardening
  security.sudo.wheelNeedsPassword = false;

  # Time synchronization
  services.timesyncd.enable = true;

  # Logging
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=50M
  '';

  # Enable container runtime (podman) for containerized services
  virtualisation.podman.enable = true;

  # Enable Caddy for reverse proxy (but don't configure it yet)
  services.caddy.enable = true;

  # Note: The DigitalOcean image module provides:
  # - SSH configuration (services.openssh)
  # - SSH key injection from DigitalOcean metadata (digitalocean-ssh-keys service)
  # - Network configuration
  # - Disk setup and auto-resize
  # - Kernel parameters for DigitalOcean
  # - Metadata service integration
  # - Firewall configuration
  
  # Let the DigitalOcean module handle network and firewall
  # Don't override its defaults
}