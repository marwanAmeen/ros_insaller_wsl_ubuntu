#!/usr/bin/env bash
set -euo pipefail

fail() { echo "[ERROR] $1" >&2; exit 1; }
info() { echo "[INFO] $1"; }

[ "$(id -u)" -ne 0 ] || fail "Run as normal user, not root."
grep -qiE "(microsoft|wsl)" /proc/version || fail "Run inside WSL."
[ -f /etc/os-release ] || fail "/etc/os-release missing."
. /etc/os-release
[ "${ID:-}" = "ubuntu" ] || fail "Ubuntu required."
[ "${VERSION_ID:-}" = "20.04" ] || fail "This script is for Ubuntu 20.04."
command -v sudo >/dev/null 2>&1 || fail "sudo not found."
sudo -v || fail "sudo authentication failed."

info "Installing prerequisites..."
sudo apt update
sudo apt install -y curl gnupg2 lsb-release ca-certificates

info "Adding ROS 1 repository and key..."
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros1-latest.list'
curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

info "Installing ROS 1 Noetic..."
sudo apt update
sudo apt install -y ros-noetic-desktop-full python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential

info "Initializing rosdep..."
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
  sudo rosdep init
fi
rosdep update

info "Configuring shell environment..."
grep -Fq "source /opt/ros/noetic/setup.bash" ~/.bashrc || {
  echo "" >> ~/.bashrc
  echo "# ROS 1 Noetic" >> ~/.bashrc
  echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc
}
source /opt/ros/noetic/setup.bash

command -v roscore >/dev/null 2>&1 || fail "roscore not found after install."
info "Done. ROS 1 Noetic installed."
EOF
