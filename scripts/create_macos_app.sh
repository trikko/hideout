#!/bin/bash
APP_NAME="Hideout"
BUNDLE_DIR="${APP_NAME}.app"

# Create directory structure
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

# Copy binary and metadata
if [ -f "hideout" ]; then
    cp hideout "${BUNDLE_DIR}/Contents/MacOS/"
else
    echo "Error: 'hideout' binary not found. Build it first."
    exit 1
fi

if [ -f "data/Info.plist" ]; then
    cp data/Info.plist "${BUNDLE_DIR}/Contents/"
else
    echo "Error: 'data/Info.plist' not found."
    exit 1
fi

# Copy icon (if generated)
if [ -f "data/hideout.icns" ]; then
    cp data/hideout.icns "${BUNDLE_DIR}/Contents/Resources/"
else
    echo "Warning: 'data/hideout.icns' not found. App will have default icon."
fi

echo "Bundle ${BUNDLE_DIR} created successfully."
