#!/bin/bash
set -euo pipefail

apt-get update
apt-get install -y curl git unzip xz-utils

curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.2-stable.tar.xz
mkdir -p "$HOME"
tar xf flutter.tar.xz -C "$HOME"
export PATH="$HOME/flutter/bin:$PATH"

# Allow flutter's internal git repos to be used by root
git config --global --add safe.directory "$HOME/flutter"

flutter doctor
flutter pub get
