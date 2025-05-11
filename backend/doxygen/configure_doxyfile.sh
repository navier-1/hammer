#!/bin/bash

# Usage: ./generate_docs.sh path/to/Doxyfile path/to/README.md

DOXYFILE="$1"
README="$2"

if [[ ! -f "$DOXYFILE" ]]; then
    echo "Error: Doxyfile not found at '$DOXYFILE'"
    exit 1
fi

# TODO: in realtà, in questo caso si può fare che passo il nome della dir, e nessuna descrizione.
if [[ ! -f "$README" ]]; then
    echo "Error: README not found at '$README'"
    exit 1
fi

# --- Configure the doxyfile based on the README.md --- #
readarray -t lines < <(grep -v '^$' "$README")

# Clean up PROJECT_NAME line: remove leading '#'s and trim whitespace
project_name=$(echo  "${lines[0]}" | sed 's/^#\+\s*//' | sed 's/"/\\"/g')
project_brief=$(echo "${lines[1]}" | sed 's/"/\\"/g')

sed -i "s|^PROJECT_NAME\s*=.*$|PROJECT_NAME   = \"$project_name\"|"  "$DOXYFILE"
sed -i "s|^PROJECT_BRIEF\s*=.*$|PROJECT_BRIEF = \"$project_brief\"|" "$DOXYFILE"

