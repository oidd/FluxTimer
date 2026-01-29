#!/bin/bash
set -e

# Run build script
chmod +x build_app.sh
./build_app.sh

echo "Build complete. Running..."
open FluxTimer.app
