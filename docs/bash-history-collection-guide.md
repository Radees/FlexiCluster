# Bash Command History Collection Guide

This guide explains how to set up and use centralized bash command history collection using the `script` command with convenient aliases.

## Overview

The bash history collection system provides:
- **Centralized storage** of all terminal sessions
- **Searchable history** across all sessions
- **Timestamped sessions** for easy tracking
- **Easy-to-use aliases** for common operations
- **Command extraction** to filter out output noise

## Quick Start

### 1. Install the Aliases

```bash
cd /home/user/FlexiCluster/scripts
bash bash-aliases-setup.sh install
source ~/.bashrc
```

### 2. Start Recording

```bash
rec-start
```

This starts a new recording session. All commands and their output will be saved to:
```
~/.bash_history_collection/session_YYYYMMDD_HHMMSS.log
```

### 3. Work Normally

Use your terminal as usual. Everything is being recorded.

### 4. Stop Recording

Press `Ctrl+D` or type `exit` to stop recording and save the session.

## Available Commands

### Recording Sessions

| Command | Description |
|---------|-------------|
| `rec-start` | Start recording a new session with timestamp |
| `rec-append <name>` | Append to an existing named session |

### Viewing Sessions

| Command | Description |
|---------|-------------|
| `rec-list` | List all recorded sessions (newest first) |
| `rec-last` | Show last 50 lines of most recent session |
| `rec-view` | Open last session in `less` for scrolling |
| `rec-status` | Show statistics (count, disk usage) |

### Searching & Extracting

| Command | Description |
|---------|-------------|
| `rec-search <term>` | Search for a term across all sessions |
| `rec-commands` | Extract only commands from last session |
| `rec-commands <file>` | Extract commands from specific session |

### Maintenance

| Command | Description |
|---------|-------------|
| `rec-merge` | Merge all sessions into one file |
| `rec-clean` | Delete sessions older than 30 days |

## Usage Examples

### Example 1: Record a Troubleshooting Session

```bash
# Start recording
rec-start

# Do your troubleshooting work
systemctl status nginx
journalctl -u nginx -n 50
cat /var/log/nginx/error.log

# Stop recording (Ctrl+D)
exit

# Later, search for what you did
rec-search "nginx"
```

### Example 2: Append to a Project Session

```bash
# Start a named session for a project
rec-append myproject

# Work on the project
cd /path/to/myproject
git status
npm install
npm test

# Stop (Ctrl+D)
exit

# Continue later
rec-append myproject

# Work more...
# Stop again
exit
```

### Example 3: Extract Commands for Documentation

```bash
# After completing a task, extract just the commands
rec-commands > /tmp/installation-steps.txt

# Review and clean up for documentation
cat /tmp/installation-steps.txt
```

### Example 4: Search Across All Sessions

```bash
# Find when you last used a specific command
rec-search "docker-compose"

# Find configuration file changes
rec-search "vim /etc"
```

## Configuration

### Change Storage Location

Edit `~/.bashrc` and modify:
```bash
export BASH_HISTORY_COLLECTION_DIR="${HOME}/.bash_history_collection"
```

### Change Timestamp Format

Edit `~/.bashrc` and modify:
```bash
export BASH_HISTORY_TIMESTAMP_FORMAT="%Y%m%d_%H%M%S"
```

### Adjust Cleanup Age

Modify the `rec-clean` alias in `~/.bashrc` to change the 30-day default:
```bash
alias rec-clean='find "$BASH_HISTORY_COLLECTION_DIR" -name "*.log" -mtime +60 -delete'
```

## Advanced Usage

### Automated Recording on Login

Add to your `~/.bashrc` to automatically start recording on login:

```bash
# Auto-start recording if not already in a script session
if [ -z "$SCRIPT_RUNNING" ]; then
    export SCRIPT_RUNNING=1
    rec-start
fi
```

### Integration with Git Commits

Create a commit message from your recorded session:

```bash
rec-commands | grep "git" > /tmp/git-changes.txt
```

### Share Sessions with Team

Export a session for sharing:

```bash
# Get the latest session file
latest=$(ls -t ~/.bash_history_collection/session_*.log | head -1)

# Copy to shared location
cp "$latest" /shared/team-sessions/$(whoami)_$(date +%Y%m%d).log
```

## How It Works

The system uses the Linux `script` command, which records everything that happens in a terminal session:

- **Input**: All commands you type
- **Output**: All program output
- **Timing**: When commands were executed (with timestamps)

The aliases wrap `script` with:
- Automatic timestamped filenames
- Centralized storage directory
- Convenient search and viewing functions
- Command extraction utilities

## Best Practices

1. **Start recording** at the beginning of important work sessions
2. **Use named sessions** (`rec-append`) for multi-day projects
3. **Search regularly** to find previously used commands
4. **Clean periodically** to avoid filling disk space
5. **Extract commands** when documenting procedures
6. **Review sessions** before deleting to capture important work

## Comparison with Standard .bash_history

| Feature | Standard .bash_history | This System |
|---------|----------------------|-------------|
| Stores output | ❌ No | ✅ Yes |
| Searchable | Limited | ✅ Full text |
| Timestamped | Optional | ✅ Always |
| Size limit | Yes (500-5000) | ✅ Unlimited |
| Deduplicated | Yes | ❌ No |
| Multiple sessions | Conflict prone | ✅ Separate files |

## Troubleshooting

### Sessions not saving

Check directory exists and is writable:
```bash
rec-status
ls -la ~/.bash_history_collection
```

### Can't find old sessions

List all sessions with full paths:
```bash
find ~/.bash_history_collection -name "*.log" -ls
```

### Aliases not working

Reload bashrc:
```bash
source ~/.bashrc
```

Verify aliases are loaded:
```bash
alias | grep rec-
```

### Disk space issues

Check usage and clean old sessions:
```bash
rec-status
rec-clean
```

## Uninstallation

To remove the aliases:

```bash
cd /home/user/FlexiCluster/scripts
bash bash-aliases-setup.sh uninstall
source ~/.bashrc
```

The recorded sessions in `~/.bash_history_collection` are not deleted automatically.

## See Also

- `man script` - Documentation for the script command
- `man bash` - Bash shell documentation
- FlexiCluster documentation: `/home/user/FlexiCluster/docs/`
