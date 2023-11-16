#!/bin/bash
#ENVFILE="./.env"

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Background colors
BG_BLACK='\033[0;40m'
BG_RED='\033[0;41m'
BG_GREEN='\033[0;42m'
BG_YELLOW='\033[0;43m'
BG_BLUE='\033[0;44m'
BG_MAGENTA='\033[0;45m'
BG_CYAN='\033[0;46m'
BG_WHITE='\033[0;47m'

# Text attributes
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINED='\033[4m'
BLINKING='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

# Reset all attributes
NC='\033[0m' # No color

# Cursor movement
CURSOR_UP='\033[A'       # Move cursor up one line
CURSOR_DOWN='\033[B'     # Move cursor down one line
CURSOR_RIGHT='\033[C'    # Move cursor right one column
CURSOR_LEFT='\033[D'     # Move cursor left one column
CURSOR_NEXT_LINE='\033[E'   # Move cursor to beginning of next line
CURSOR_PREV_LINE='\033[F'   # Move cursor to beginning of previous line
CURSOR_SAVE_POSITION='\033[s'  # Save cursor position
CURSOR_RESTORE_POSITION='\033[u'   # Restore saved cursor position

# Text deletion
DELETE_RIGHT='\033[K'   # Delete text from the cursor position to the end of the line
DELETE_LEFT='\033[1K'   # Delete text from the beginning of the line to the cursor position
DELETE_LINE='\033[2K'   # Delete the entire line where the cursor is positioned
DELETE_SCREEN='\033[2J'   # Clear the entire screen


print_header() {
    echo -e "${BG_BLUE}${UNDERLINED}${BOLD}${1}${NC}"
}

# Function to execute a command and print warnings/errors
print_action() {
    local command="$1"
    local message="$2"

    echo -e "${YELLOW}[RUNNING]${NC} $message..."

    output="$($command 2>&1 > log.txt)"

    # Print the colorized output

   # Check if there were any errors (non-zero exit code)
    if [ $? -eq 0 ]; then
        echo -e "${CURSOR_PREV_LINE}${GREEN}[DONE]${NC} $message${DELETE_RIGHT}"
    else
        echo -e "${CURSOR_PREV_LINE}${RED}[FAIL]${NC} $message${DELETE_RIGHT}"
        echo "$output"
        exit 1
    fi
}

print_info() {
    local message="$1"

    echo -e "${BOLD}[INFO]${NC} $message"
}