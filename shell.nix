# shell.nix - DRY wrapper that delegates to flake.nix
# This provides backward compatibility for tools that expect shell.nix
# while ensuring single source of truth via flake.nix
#
# This file is a thin wrapper around flake.nix that:
# 1. Uses the exact same packages as flake.nix
# 2. Maintains the same nixpkgs pin via flake.lock
# 3. Provides shell.nix for tools that don't understand flakes
# 4. Single source of truth: update flake.nix, shell.nix stays in sync

(builtins.getFlake (toString ./.)).devShells.${builtins.currentSystem}.default