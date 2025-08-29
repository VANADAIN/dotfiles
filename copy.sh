#!/bin/sh

# Dotfiles Manager Script
# This script backs up and restores configuration files

set -e

# Configuration
REPO_DIR="$HOME/projects/dotfiles"
BACKUP_DIR="$REPO_DIR/backups"
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
mkdir -p "$REPO_DIR" "$BACKUP_DIR"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to backup configuration
backup_config() {
    local name="$1"
    local source_path="$2"
    
    if [[ ! -e "$source_path" ]]; then
        log "WARNING: $name config not found at $source_path"
        return 1
    fi
    
    local backup_path="$REPO_DIR/$name"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    # Create backup of previous version
    if [[ -e "$backup_path" ]]; then
        mkdir -p "$BACKUP_DIR/$name"
        cp -r "$backup_path" "$BACKUP_DIR/$name/${name}_${timestamp}"
    fi
    
    # Copy current config to repo
    if [[ -d "$source_path" ]]; then
        rsync -av --delete "$source_path/" "$backup_path/" 2>/dev/null || \
        cp -r "$source_path" "$backup_path"
    else
        cp "$source_path" "$backup_path"
    fi
    
    log "Backed up $name from $source_path"
}

# Function to restore configuration
restore_config() {
    local name="$1"
    local target_path="$2"
    local source_path="$REPO_DIR/$name"
    
    if [[ ! -e "$source_path" ]]; then
        log "ERROR: No backup found for $name in repo"
        return 1
    fi
    
    # Create backup of current config before restoring
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    mkdir -p "$BACKUP_DIR/system_backups"
    
    if [[ -e "$target_path" ]]; then
        if [[ -d "$target_path" ]]; then
            cp -r "$target_path" "$BACKUP_DIR/system_backups/${name}_${timestamp}"
        else
            cp "$target_path" "$BACKUP_DIR/system_backups/${name}_${timestamp}"
        fi
    fi
    
    # Restore config
    if [[ -d "$source_path" ]]; then
        mkdir -p "$(dirname "$target_path")"
        rsync -av --delete "$source_path/" "$target_path/" 2>/dev/null || \
        cp -r "$source_path" "$target_path"
    else
        mkdir -p "$(dirname "$target_path")"
        cp "$source_path" "$target_path"
    fi
    
    log "Restored $name to $target_path"
}

# Function to show status
show_status() {
    echo "=== Dotfiles Status ==="
    for name in "${!CONFIG_PATHS[@]}"; do
        local system_path="${CONFIG_PATHS[$name]}"
        local repo_path="$REPO_DIR/$name"
        
        echo -n "$name: "
        if [[ -e "$repo_path" ]]; then
            echo -n "✓ Backed up"
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
            echo "✗ Not backed up"
        fi
    done
}

# Main function
main() {
    case "${1:-}" in
        "backup")
            log "Starting backup operation"
            for name in "${!CONFIG_PATHS[@]}"; do
                backup_config "$name" "${CONFIG_PATHS[$name]}"
            done
            log "Backup completed"
            ;;
        "restore")
            log "Starting restore operation"
            for name in "${!CONFIG_PATHS[@]}"; do
                restore_config "$name" "${CONFIG_PATHS[$name]}"
            done
            log "Restore completed"
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
                echo "backups/" >> .gitignore
                git add .
                git commit -m "Initial dotfiles commit"
                log "Git repository initialized"
            else
                log "Git repository already exists"
            fi
            ;;
        *)
            echo "Usage: $0 {backup|restore|status|init}"
            echo "  backup  - Copy current configs to repo"
            echo "  restore - Copy configs from repo to system"
            echo "  status  - Show current status"
            echo "  init    - Initialize git repository"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
