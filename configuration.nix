{ config, lib, pkgs, ... }:
{
  # Note: SSH keys are now handled by cloud-init from cloud metadata

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

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Cloud-init for SSH key injection from cloud providers
  services.cloud-init = {
    enable = true;
    # Allow cloud-init to configure network (needed for metadata access)
    network.enable = true;
    # DigitalOcean uses its own datasource via metadata service
    # NoCloud datasource is for local/ISO-based metadata (testing)
    settings = {
      datasource_list = [ "NoCloud" "DigitalOcean" "ConfigDrive" ];
    };
  };

  # Security hardening
  security.sudo.wheelNeedsPassword = false;
  
  # Note: SSH keys will be injected by cloud-init from cloud metadata
  # Remove the build-time SSH key injection
  users.users.root.openssh.authorizedKeys.keys = [];

  # Firewall - minimal defaults, can be extended by runtime config
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH only by default
    allowedUDPPorts = [ ];
  };

  # Time synchronization
  services.timesyncd.enable = true;
  
  # Systemd-networkd for cloud-init network configuration
  systemd.network.enable = true;
  networking.useNetworkd = true;

  # Logging
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    RuntimeMaxUse=50M
  '';

  # Enable container runtime (podman) for containerized services
  virtualisation.podman.enable = true;

  # Enable Caddy for reverse proxy (but don't configure it yet)
  services.caddy.enable = true;
  
  # Enable serial console for debugging
  # This allows us to see boot messages and cloud-init output in QEMU
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.loader.timeout = 10;
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
    serviceConfig.Restart = "always";
  };
}