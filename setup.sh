#!/bin/bash
set -euo pipefail

apt-get update
apt-get install -y curl git unzip xz-utils

curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz
mkdir -p "$HOME"
tar xf flutter.tar.xz -C "$HOME"
export PATH="$PATH:$HOME/flutter/bin"

flutter doctor
flutter pub get
