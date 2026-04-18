{
  description = "NixOS base image builder for DigitalOcean";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }: {
    # Build a DigitalOcean image using the base configuration
    packages.x86_64-linux = {
      digitalocean-image = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "do";
        modules = [
          # General-purpose NixOS configuration
          ./configuration.nix
        ];
      };
      
      # Also provide a raw image format for testing
      raw-image = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "raw";
        modules = [
          ./configuration.nix
        ];
      };
    };
    
    # Development shell for building and uploading images
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      packages = with nixpkgs.legacyPackages.x86_64-linux; [
        # Image building tools
        nixos-generators.packages.x86_64-linux.nixos-generate
        
        # Compression tools
        gzip
        pigz
        zstd
        
        # Disk utilities
        parted
        util-linux
        
        # QEMU for testing
        qemu
        qemu_kvm
        
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
        echo "  nix build .#raw-image            - Build raw image for testing"
        echo "  ./scripts/upload-nixos-image.sh  - Upload image to DigitalOcean"
        echo ""
        echo "To test with QEMU:"
        echo "  nix build .#raw-image"
        echo "  qemu-system-x86_64 -m 2048 -drive file=result/nixos.img,format=raw"
        echo ""
        echo "Images will be available at:"
        echo "  DigitalOcean: result/nixos-image-digital-ocean-*.qcow2.gz"
        echo "  Raw: result/nixos.img"
        echo ""
        echo "This is a general-purpose NixOS base image."
        echo "Configure environment variables in .env file."
      '';
    };
  };
}