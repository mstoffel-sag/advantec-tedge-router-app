#!/bin/sh
# Sets up the Advantech Router App build environment next to this repository.
#
# Result layout:
#   <workspace>/
#     |-- ModulesSDK/                 Advantech Router App SDK (built)
#     |-- Toolchains/                 cross toolchains (installed via dpkg)
#     +-- advantec-tedge-router-app/  this repository
#
# Requires: Ubuntu 24.04+ with: git make pkg-config build-essential cryptsetup-bin curl
set -e

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORKSPACE=$(dirname "$REPO_DIR")
cd "$WORKSPACE"

echo "Workspace: $WORKSPACE"

echo "==> Installing host build prerequisites"
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y git make pkg-config build-essential cryptsetup-bin curl ccache
else
    echo "   (skipping: apt-get not found -- install the prerequisites manually)"
fi

echo "==> Fetching cross toolchains (Advantech)"
if [ ! -d Toolchains ]; then
    git clone https://bitbucket.org/bbsmartworx/Toolchains.git
fi
echo "   Installing toolchain .deb packages (needs sudo)"
sudo dpkg -i Toolchains/deb/*.deb || true

echo "==> Fetching and building the Router App SDK (ModulesSDK)"
if [ ! -d ModulesSDK ]; then
    git clone https://bitbucket.org/bbsmartworx/ModulesSDK.git
fi
( cd ModulesSDK && make )

echo
echo "Done. Build the thin-edge.io Router App with:"
echo "    cd $REPO_DIR && make PLATFORMS=\"v4i\"        # ICR-1642"
