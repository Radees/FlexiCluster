#!/bin/bash
# Bash Command History Collector
# This script provides functionality to collect centralized command history using the 'script' command

# Configuration
HISTORY_DIR="${HOME}/.bash_history_collection"
HISTORY_PREFIX="session"
HISTORY_FORMAT="typescript"  # typescript or timing

# Create history collection directory if it doesn't exist
initialize_history_collection() {
    if [ ! -d "$HISTORY_DIR" ]; then
        mkdir -p "$HISTORY_DIR"
        echo "Created history collection directory: $HISTORY_DIR"
    fi
}

# Start a new history collection session
start_history_session() {
    local session_name="${HISTORY_PREFIX}_$(date +%Y%m%d_%H%M%S)"
    local session_file="${HISTORY_DIR}/${session_name}.log"
    local timing_file="${HISTORY_DIR}/${session_name}.timing"

    echo "Starting command history collection..."
    echo "Session file: $session_file"
    echo "To exit and save history, press Ctrl+D or type 'exit'"
    echo "----------------------------------------"

    # Start script with timing information
    if [ "$HISTORY_FORMAT" = "timing" ]; then
        script -t 2>"$timing_file" "$session_file"
    else
        script -a "$session_file"
    fi

    echo "----------------------------------------"
    echo "History session saved to: $session_file"
}

# Extract only commands from session log (remove prompts and output)
extract_commands_only() {
    local session_file="$1"
    local output_file="${session_file}.commands"

    # This is a basic extraction - may need adjustment based on your prompt format
    grep -E "^\$|^#" "$session_file" | sed 's/^[$#] //' > "$output_file"
    echo "Extracted commands to: $output_file"
}

# List all collected history sessions
list_history_sessions() {
    echo "Available history sessions in $HISTORY_DIR:"
    ls -lh "$HISTORY_DIR" | grep -v "^total"
}

# Search through all collected histories
search_history() {
    local search_term="$1"
    if [ -z "$search_term" ]; then
        echo "Usage: search_history <search_term>"
        return 1
    fi

    echo "Searching for: $search_term"
    grep -r "$search_term" "$HISTORY_DIR"
}

# Merge all command histories into a single file
merge_histories() {
    local merged_file="${HISTORY_DIR}/merged_history_$(date +%Y%m%d_%H%M%S).log"
    echo "Merging all histories into: $merged_file"
    cat "${HISTORY_DIR}"/session_*.log > "$merged_file"
    echo "Merge complete!"
}

# Main function
main() {
    initialize_history_collection

    case "${1:-start}" in
        start)
            start_history_session
            ;;
        list)
            list_history_sessions
            ;;
        search)
            search_history "$2"
            ;;
        merge)
            merge_histories
            ;;
        extract)
            extract_commands_only "$2"
            ;;
        *)
            echo "Usage: $0 {start|list|search|merge|extract}"
            echo "  start   - Start a new history collection session"
            echo "  list    - List all collected history sessions"
            echo "  search  - Search through collected histories"
            echo "  merge   - Merge all histories into one file"
            echo "  extract - Extract only commands from a session log"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
