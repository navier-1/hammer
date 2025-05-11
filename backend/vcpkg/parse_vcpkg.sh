#!/bin/bash

VCPKG_JSON="$1/vcpkg.json"
OUTPUT_FILE="$2/vcpkg_libraries.cmake"

# Check if jq is installed (best JSON parser)
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required. Install with: sudo apt-get install jq"
    exit 1
fi

# Extract dependencies using jq
DEPS=$(jq -r '.dependencies[] | split("@")[0]' "$VCPKG_JSON" 2>/dev/null)

if [ -z "$DEPS" ]; then
    echo "message(WARNING \"No dependencies found in vcpkg.json\")" > "$OUTPUT_FILE"
else
    # Convert to CMake list format
    CMAKE_LIST=$(echo "$DEPS" | tr '\n' ';')
    echo "set(VCPKG_LIBRARIES ${CMAKE_LIST})" > "$OUTPUT_FILE"
fi

echo "Generated: $OUTPUT_FILE"