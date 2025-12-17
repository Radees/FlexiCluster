# FlexiCluster Scripts

This directory contains utility scripts for the FlexiCluster project.

## Bash History Collection System

A comprehensive system for collecting and managing centralized bash command history using the `script` command.

### Files

- **bash-history-collector.sh** - Core script for history collection
- **bash-aliases-setup.sh** - Install/uninstall convenient aliases

### Quick Setup

```bash
# Install the aliases
./bash-aliases-setup.sh install

# Reload your shell
source ~/.bashrc

# Start recording
rec-start
```

### Documentation

See the complete guide: [Bash History Collection Guide](../docs/bash-history-collection-guide.md)

### Features

- ✅ Centralized command history storage
- ✅ Timestamped session files
- ✅ Full-text search across all sessions
- ✅ Command extraction (filter out output)
- ✅ Session merging and management
- ✅ Easy-to-use aliases
- ✅ Automatic cleanup of old sessions

### Available Commands

Once installed, you'll have these commands:

| Command | Purpose |
|---------|---------|
| `rec-start` | Start recording a new session |
| `rec-list` | List all recorded sessions |
| `rec-search <term>` | Search across all sessions |
| `rec-view` | View last session |
| `rec-commands` | Extract commands only |
| `rec-status` | Show system status |

For full documentation, see [bash-history-collection-guide.md](../docs/bash-history-collection-guide.md)
