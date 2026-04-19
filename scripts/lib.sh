#!/bin/bash
# Simple library for error handling
# Assumes direnv has already loaded .env

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_and_exit() {
    echo "❌ $1" >&2
    exit 1
}

# Simple validation - just check if variable is set
validate_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    
    if [ -z "$var_value" ]; then
        log_and_exit "$var_name is not set. Make sure .env is loaded."
    fi
}

# Find the newest NixOS image in result/ directory
# Usage: find_nixos_image [image_type]
#   image_type: "digitalocean" (default) or "raw" or "all"
# Supports environment variable NIXOS_IMAGE_PATH to specify exact image
# Otherwise finds newest by lexicographic sort (newest comes last)
find_nixos_image() {
    local image_type="${1:-digitalocean}"  # digitalocean, raw, or all
    local image_path=""
    
    # Check if user specified an exact image path
    if [ -n "${NIXOS_IMAGE_PATH:-}" ]; then
        if [ -f "$NIXOS_IMAGE_PATH" ]; then
            echo "$NIXOS_IMAGE_PATH"
            return 0
        else
            # Try relative to project root
            local full_path="$PROJECT_ROOT/$NIXOS_IMAGE_PATH"
            if [ -f "$full_path" ]; then
                echo "$full_path"
                return 0
            else
                log_and_exit "Specified image not found: $NIXOS_IMAGE_PATH"
            fi
        fi
    fi
    
    # Determine which patterns to search based on image_type
    local patterns=()
    case "$image_type" in
        digitalocean)
            patterns=("$PROJECT_ROOT/result/"*.qcow2.gz "$PROJECT_ROOT/result/"*.img.tar.gz)
            ;;
        # Note: raw image support removed - project focuses on DigitalOcean only
        raw)
            log_and_exit "Raw image support has been removed. Use 'digitalocean' image type."
            ;;
        all)
            patterns=("$PROJECT_ROOT/result/"*.qcow2.gz "$PROJECT_ROOT/result/"*.img.tar.gz)
            ;;
        *)
            log_and_exit "Invalid image type: $image_type. Use 'digitalocean' or 'all'."
            ;;
    esac
    
    # Look for image files in result/ directory
    local newest_image=""
    local pattern
    
    # Check each pattern and find the newest file for that pattern
    for pattern in "${patterns[@]}"; do
        # Skip if pattern doesn't match any files
        [ -e "$pattern" ] || continue
        
        # Find the newest file matching this pattern
        # sort -r reverses sort, tail -1 gets last (newest when sorted normally)
        local pattern_newest=$(ls -1 "$pattern" 2>/dev/null | sort | tail -1)
        
        if [ -n "$pattern_newest" ] && [ -f "$pattern_newest" ]; then
            # If we don't have a newest yet, or this one is newer (lexicographically)
            if [ -z "$newest_image" ] || [[ "$pattern_newest" > "$newest_image" ]]; then
                newest_image="$pattern_newest"
            fi
        fi
    done
    
    if [ -n "$newest_image" ] && [ -f "$newest_image" ]; then
        echo "$newest_image"
        return 0
    fi
    
    # No image found
    return 1
}