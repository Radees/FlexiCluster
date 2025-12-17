#!/bin/bash
# Bash History Collection Aliases Setup
# This script sets up convenient aliases for centralized command history collection

# Define the alias content
ALIAS_CONTENT='
# ============================================================
# Bash Command History Collection Aliases
# ============================================================

# Configuration
export BASH_HISTORY_COLLECTION_DIR="${HOME}/.bash_history_collection"
export BASH_HISTORY_TIMESTAMP_FORMAT="%Y%m%d_%H%M%S"

# Create collection directory if it does not exist
[ ! -d "$BASH_HISTORY_COLLECTION_DIR" ] && mkdir -p "$BASH_HISTORY_COLLECTION_DIR"

# Alias: Start a recorded session
alias rec-start='"'"'_rec_start() {
    local session_name="session_$(date +${BASH_HISTORY_TIMESTAMP_FORMAT})"
    local session_file="${BASH_HISTORY_COLLECTION_DIR}/${session_name}.log"
    echo "🔴 Recording session: $session_name"
    echo "📝 Output file: $session_file"
    echo "Press Ctrl+D or type '"'"'exit'"'"' to stop recording"
    script -f -q "$session_file"
    echo "✅ Session saved: $session_file"
}; _rec_start'"'"'

# Alias: Start recording with append mode
alias rec-append='"'"'_rec_append() {
    local session_name="${1:-default}"
    local session_file="${BASH_HISTORY_COLLECTION_DIR}/${session_name}.log"
    echo "🔴 Appending to session: $session_name"
    echo "📝 Output file: $session_file"
    script -a -f -q "$session_file"
    echo "✅ Session appended: $session_file"
}; _rec_append'"'"'

# Alias: List all recorded sessions
alias rec-list='"'"'ls -lht "$BASH_HISTORY_COLLECTION_DIR" | head -20'"'"'

# Alias: Search through recorded sessions
alias rec-search='"'"'_rec_search() {
    if [ -z "$1" ]; then
        echo "Usage: rec-search <search_term>"
        return 1
    fi
    echo "🔍 Searching for: $1"
    grep -r --color=auto "$1" "$BASH_HISTORY_COLLECTION_DIR"
}; _rec_search'"'"'

# Alias: Show last recorded session
alias rec-last='"'"'ls -t "$BASH_HISTORY_COLLECTION_DIR"/*.log 2>/dev/null | head -1 | xargs tail -50'"'"'

# Alias: Open last session in less
alias rec-view='"'"'ls -t "$BASH_HISTORY_COLLECTION_DIR"/*.log 2>/dev/null | head -1 | xargs less'"'"'

# Alias: Clean old sessions (older than 30 days)
alias rec-clean='"'"'find "$BASH_HISTORY_COLLECTION_DIR" -name "*.log" -mtime +30 -delete && echo "✅ Cleaned sessions older than 30 days"'"'"'

# Alias: Show recording status
alias rec-status='"'"'echo "📊 History Collection Status:"; echo "Directory: $BASH_HISTORY_COLLECTION_DIR"; echo "Total sessions: $(ls -1 "$BASH_HISTORY_COLLECTION_DIR"/*.log 2>/dev/null | wc -l)"; echo "Disk usage: $(du -sh "$BASH_HISTORY_COLLECTION_DIR" 2>/dev/null | cut -f1)"'"'"'

# Alias: Extract commands only from last session (remove output noise)
alias rec-commands='"'"'_rec_commands() {
    local session_file="${1:-$(ls -t "$BASH_HISTORY_COLLECTION_DIR"/*.log 2>/dev/null | head -1)}"
    if [ -z "$session_file" ]; then
        echo "No session file found"
        return 1
    fi
    echo "📋 Extracting commands from: $(basename "$session_file")"
    # Extract lines that look like commands (starts with $ or # prompt)
    cat "$session_file" | col -b | grep -E "^(\$|#|>)" | sed "s/^[$#>] //"
}; _rec_commands'"'"'

# Alias: Merge all sessions into one file
alias rec-merge='"'"'cat "$BASH_HISTORY_COLLECTION_DIR"/session_*.log > "$BASH_HISTORY_COLLECTION_DIR/merged_all_$(date +%Y%m%d_%H%M%S).log" && echo "✅ Merged all sessions"'"'"'

# Enhanced history settings for better command tracking
export HISTSIZE=50000
export HISTFILESIZE=50000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# ============================================================
'

# Function to add aliases to bashrc
install_aliases() {
    local bashrc="${HOME}/.bashrc"
    local backup_file="${bashrc}.backup_$(date +%Y%m%d_%H%M%S)"

    echo "Installing bash history collection aliases..."

    # Create backup
    if [ -f "$bashrc" ]; then
        cp "$bashrc" "$backup_file"
        echo "✅ Created backup: $backup_file"
    fi

    # Check if aliases already exist
    if grep -q "Bash Command History Collection Aliases" "$bashrc" 2>/dev/null; then
        echo "⚠️  Aliases already exist in $bashrc"
        read -p "Do you want to update them? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            return 1
        fi
        # Remove old aliases
        sed -i '/# Bash Command History Collection Aliases/,/# ============================================================/d' "$bashrc"
    fi

    # Append aliases
    echo "$ALIAS_CONTENT" >> "$bashrc"
    echo "✅ Aliases installed to $bashrc"
    echo ""
    echo "To activate, run: source ~/.bashrc"
    echo ""
    echo "Available commands:"
    echo "  rec-start      - Start recording a new session"
    echo "  rec-append     - Append to an existing session"
    echo "  rec-list       - List all recorded sessions"
    echo "  rec-search     - Search through recorded sessions"
    echo "  rec-last       - Show last 50 lines of last session"
    echo "  rec-view       - View last session in less"
    echo "  rec-clean      - Clean sessions older than 30 days"
    echo "  rec-status     - Show collection status"
    echo "  rec-commands   - Extract only commands from a session"
    echo "  rec-merge      - Merge all sessions into one file"
}

# Function to uninstall aliases
uninstall_aliases() {
    local bashrc="${HOME}/.bashrc"

    if grep -q "Bash Command History Collection Aliases" "$bashrc" 2>/dev/null; then
        sed -i '/# Bash Command History Collection Aliases/,/# ============================================================/d' "$bashrc"
        echo "✅ Aliases removed from $bashrc"
    else
        echo "⚠️  No aliases found in $bashrc"
    fi
}

# Main script logic
case "${1:-install}" in
    install)
        install_aliases
        ;;
    uninstall)
        uninstall_aliases
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        echo "  install   - Install bash history collection aliases"
        echo "  uninstall - Remove bash history collection aliases"
        exit 1
        ;;
esac
