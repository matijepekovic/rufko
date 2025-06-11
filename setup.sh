#!/bin/bash
set -euo pipefail

apt-get update
apt-get install -y curl git unzip xz-utils

git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

# Allow flutter's internal git repos to be used by root
git config --global --add safe.directory "$HOME/flutter"

flutter doctor
flutter pub get
