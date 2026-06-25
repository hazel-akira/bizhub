#!/usr/bin/env bash
# One-time fix for snap Flutter Linux builds:
# "Failed to find any of [ld.lld, ld] in .../llvm-10/bin"
set -euo pipefail

LLVM_BIN="/snap/flutter/current/usr/lib/llvm-10/bin"

if [[ ! -d "$LLVM_BIN" ]]; then
  echo "Snap Flutter LLVM bin not found at $LLVM_BIN"
  exit 1
fi

echo "Linking system linker into $LLVM_BIN ..."
sudo ln -sf /usr/bin/ld "$LLVM_BIN/ld"
sudo ln -sf /usr/bin/ld.lld "$LLVM_BIN/ld.lld"

echo "Done. Run: flutter run -d linux"
