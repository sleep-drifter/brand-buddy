#!/usr/bin/env bash
# Installs the Android SDK packages needed to build the app in android/.
# Requires network access to dl.google.com (note: blocked in some sandboxed
# CI/agent environments — GitHub-hosted runners have the SDK preinstalled).
set -euo pipefail

SDK_ROOT="${ANDROID_HOME:-$HOME/android-sdk}"
CMDTOOLS_ZIP="commandlinetools-linux-11076708_latest.zip"

if [[ ! -x "$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]]; then
  echo "Installing Android command-line tools to $SDK_ROOT ..."
  mkdir -p "$SDK_ROOT/cmdline-tools"
  tmp="$(mktemp -d)"
  curl -sSL -o "$tmp/$CMDTOOLS_ZIP" "https://dl.google.com/android/repository/$CMDTOOLS_ZIP"
  unzip -q "$tmp/$CMDTOOLS_ZIP" -d "$tmp"
  rm -rf "$SDK_ROOT/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
  rm -rf "$tmp"
fi

SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

yes | "$SDKMANAGER" --licenses >/dev/null
"$SDKMANAGER" "platform-tools" "platforms;android-36" "build-tools;36.0.0"

echo
echo "Android SDK ready. Export before building:"
echo "  export ANDROID_HOME=$SDK_ROOT"
