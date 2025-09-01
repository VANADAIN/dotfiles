#!/bin/sh

# Dotfiles Manager Script
# This script copies configuration files between system and repo

set -e

# Configuration
REPO_DIR="$HOME/projects/dotfiles"
LOG_FILE="$REPO_DIR/backup.log"

# Configuration files and directories to manage
declare -A CONFIG_PATHS=(
    ["i3"]="$HOME/.config/i3"
    ["i3blocks"]="$HOME/.config/i3blocks"
    ["kitty"]="$HOME/.config/kitty"
    ["neovim"]="$HOME/.config/nvim"
    ["nixos"]="/etc/nixos"
)

# Create necessary directories
mkdir -p "$REPO_DIR"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to copy configuration to repo
copy_to_repo() {
    local name="$1"
    local source_path="$2"
    
    if [[ ! -e "$source_path" ]]; then
        log "WARNING: $name config not found at $source_path"
        return 1
    fi
    
    local repo_path="$REPO_DIR/$name"
    
    # Copy current config to repo
    if [[ -d "$source_path" ]]; then
        rsync -av --delete "$source_path/" "$repo_path/" 2>/dev/null || \
        cp -r "$source_path" "$repo_path"
    else
        cp "$source_path" "$repo_path"
    fi
    
    log "Copied $name from $source_path to repo"
}

# Function to copy configuration from repo to system
copy_to_system() {
    local name="$1"
    local target_path="$2"
    local source_path="$REPO_DIR/$name"
    
    if [[ ! -e "$source_path" ]]; then
        log "ERROR: No copy found for $name in repo"
        return 1
    fi
    
    # Copy config from repo to system
    if [[ -d "$source_path" ]]; then
        mkdir -p "$(dirname "$target_path")"
        rsync -av --delete "$source_path/" "$target_path/" 2>/dev/null || \
        cp -r "$source_path" "$target_path"
    else
        mkdir -p "$(dirname "$target_path")"
        cp "$source_path" "$target_path"
    fi
    
    log "Copied $name from repo to $target_path"
}

# Function to show status
show_status() {
    echo "=== Dotfiles Status ==="
    for name in "${!CONFIG_PATHS[@]}"; do
        local system_path="${CONFIG_PATHS[$name]}"
        local repo_path="$REPO_DIR/$name"
        
        echo -n "$name: "
        if [[ -e "$repo_path" ]]; then
            echo -n "✓ In repo"
            if [[ -e "$system_path" ]]; then
                # Check if files differ
                if diff -r "$system_path" "$repo_path" >/dev/null 2>&1; then
                    echo " (in sync)"
                else
                    echo " (modified)"
                fi
            else
                echo " (system config missing)"
            fi
        else
            echo "✗ Not in repo"
        fi
    done
}

# Main function
main() {
    case "${1:-}" in
        "to-repo")
            log "Starting copy to repo operation"
            for name in "${!CONFIG_PATHS[@]}"; do
                copy_to_repo "$name" "${CONFIG_PATHS[$name]}"
            done
            log "Copy to repo completed"
            ;;
        "to-system")
            log "Starting copy to system operation"
            for name in "${!CONFIG_PATHS[@]}"; do
                copy_to_system "$name" "${CONFIG_PATHS[$name]}"
            done
            log "Copy to system completed"
            ;;
        "status")
            show_status
            ;;
        "init")
            # Initialize git repo
            cd "$REPO_DIR"
            if [[ ! -d ".git" ]]; then
                git init
                echo "*.log" > .gitignore
                git add .
                git commit -m "Initial dotfiles commit"
                log "Git repository initialized"
            else
                log "Git repository already exists"
            fi
            ;;
        *)
            echo "Usage: $0 {to-repo|to-system|status|init}"
            echo "  to-repo   - Copy current configs from system to repo"
            echo "  to-system - Copy configs from repo to system"
            echo "  status    - Show current status"
            echo "  init      - Initialize git repository"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
