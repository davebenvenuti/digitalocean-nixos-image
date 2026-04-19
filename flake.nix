{
  description = "NixOS base image builder for DigitalOcean";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    config = {
      imports = [
        # Official DigitalOcean image module
        (pkgs.path + "/nixos/modules/virtualisation/digital-ocean-image.nix")
        # Our custom configuration
        ./configuration.nix
      ];
    };
  in {
    # Build a DigitalOcean image using the official NixOS module
    packages.${system}.digitalocean-image = (pkgs.nixos config).digitalOceanImage;
    
    # Development shell for building and uploading images
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        # Compression tools
        gzip
        pigz
        zstd
        
        # Disk utilities
        parted
        util-linux
        
        # SSH tools
        openssh
        
        # DigitalOcean CLI (for image upload)
        doctl
        
        # Cloud storage for image upload
        rclone
      ];
      
      shellHook = ''
        echo "NixOS DigitalOcean Base Image Builder"
        echo ""
        echo "Available commands:"
        echo "  nix build .#digitalocean-image   - Build DigitalOcean image"
        echo "  ./scripts/upload-nixos-image.sh  - Upload image to DigitalOcean"
        echo ""
        echo "Images will be available at:"
        echo "  DigitalOcean: result/nixos-image-digital-ocean-*.qcow2.gz"
        echo ""
        echo "This is a general-purpose NixOS base image."
        echo "Configure environment variables in .env file."
      '';
    };
  };
}