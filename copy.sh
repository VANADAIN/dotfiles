#!/bin/sh

# Dotfiles Manager Script
# This script backs up and restores configuration files

set -e

# Configuration
REPO_DIR="$HOME/projects/dotfiles"
BACKUP_DIR="$REPO_DIR/backups"
LOG_FILE="$REPO_DIR/backup.log"
KEEP_BACKUPS=1  # Number of backup versions to keep

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

# Function to clean up old backups
cleanup_old_backups() {
    local name="$1"
    local backup_dir="$BACKUP_DIR/$name"
    
    if [[ ! -d "$backup_dir" ]]; then
        return 0
    fi
    
    # Get list of backups sorted by modification time (newest first)
    local backups=($(find "$backup_dir" -maxdepth 1 -name "${name}_*" -type d -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-))
    
    # Remove old backups if we have more than KEEP_BACKUPS
    if [[ ${#backups[@]} -gt $KEEP_BACKUPS ]]; then
        for ((i = KEEP_BACKUPS; i < ${#backups[@]}; i++)); do
            local backup_to_remove="${backups[$i]}"
            log "Removing old backup: $backup_to_remove"
            rm -rf "$backup_to_remove"
        done
    fi
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
        
        # Clean up old backups after creating new one
        cleanup_old_backups "$name"
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
        
        # Clean up old system backups
        local system_backups=($(find "$BACKUP_DIR/system_backups" -maxdepth 1 -name "${name}_*" -type d -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-))
        if [[ ${#system_backups[@]} -gt $KEEP_BACKUPS ]]; then
            for ((i = KEEP_BACKUPS; i < ${#system_backups[@]}; i++)); do
                rm -rf "${system_backups[$i]}"
            done
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
            
            # Show backup count
            local backup_count=0
            if [[ -d "$BACKUP_DIR/$name" ]]; then
                backup_count=$(find "$BACKUP_DIR/$name" -maxdepth 1 -name "${name}_*" -type d | wc -l)
            fi
            echo "  Backups available: $backup_count (keeping $KEEP_BACKUPS latest)"
            
        else
            echo "✗ Not backed up"
        fi
        echo
    done
}

# Function to list all backups
list_backups() {
    echo "=== Available Backups ==="
    for name in "${!CONFIG_PATHS[@]}"; do
        local backup_dir="$BACKUP_DIR/$name"
        if [[ -d "$backup_dir" ]]; then
            echo "$name backups:"
            find "$backup_dir" -maxdepth 1 -name "${name}_*" -type d -printf '  %f\n' | sort -r
        else
            echo "$name: No backups available"
        fi
        echo
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
        "list-backups")
            list_backups
            ;;
        "cleanup")
            log "Starting cleanup operation"
            for name in "${!CONFIG_PATHS[@]}"; do
                cleanup_old_backups "$name"
            done
            # Also clean system backups
            if [[ -d "$BACKUP_DIR/system_backups" ]]; then
                for name in "${!CONFIG_PATHS[@]}"; do
                    local system_backups=($(find "$BACKUP_DIR/system_backups" -maxdepth 1 -name "${name}_*" -type d -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-))
                    if [[ ${#system_backups[@]} -gt $KEEP_BACKUPS ]]; then
                        for ((i = KEEP_BACKUPS; i < ${#system_backups[@]}; i++)); do
                            rm -rf "${system_backups[$i]}"
                        done
                    fi
                done
            fi
            log "Cleanup completed"
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
            echo "Usage: $0 {backup|restore|status|list-backups|cleanup|init}"
            echo "  backup       - Copy current configs to repo (with backup rotation)"
            echo "  restore      - Copy configs from repo to system"
            echo "  status       - Show current status and backup counts"
            echo "  list-backups - List all available backups"
            echo "  cleanup      - Manually clean up old backups"
            echo "  init         - Initialize git repository"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
