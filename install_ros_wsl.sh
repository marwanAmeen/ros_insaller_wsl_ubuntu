#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
#  Unified ROS Installer for WSL Ubuntu
#  - Ubuntu 20.04  →  ROS 1 Noetic
#  - Ubuntu 22.04  →  ROS 2 Humble
#
#  Usage:
#    chmod +x install_ros_wsl.sh
#    ./install_ros_wsl.sh
# =============================================================================

fail() { echo "[ERROR] $1" >&2; exit 1; }
info() { echo "[INFO]  $1"; }
section() { echo ""; echo "==> $1"; echo ""; }

# ---------- Preflight checks ----------
section "Pre-flight checks"

[ "$(id -u)" -ne 0 ] || fail "Do not run as root. Run as your normal WSL user."
grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null || fail "This script must be run inside WSL."
[ -f /etc/os-release ] || fail "/etc/os-release not found."
. /etc/os-release
[ "${ID:-}" = "ubuntu" ] || fail "This script supports Ubuntu only. Detected: ${ID:-unknown}"
command -v sudo >/dev/null 2>&1 || fail "sudo is not installed."
sudo -v || fail "sudo authentication failed."

info "Detected Ubuntu ${VERSION_ID}"

# ---------- Route by Ubuntu version ----------
case "${VERSION_ID}" in
  20.04)
    ROS_DISTRO="noetic"
    ROS_VERSION=1
    info "Ubuntu 20.04 detected → Installing ROS 1 Noetic"
    ;;
  22.04)
    ROS_DISTRO="humble"
    ROS_VERSION=2
    info "Ubuntu 22.04 detected → Installing ROS 2 Humble"
    ;;
  *)
    fail "Unsupported Ubuntu version: ${VERSION_ID}. Supported: 20.04 (Noetic) and 22.04 (Humble)."
    ;;
esac

# ---------- Common prerequisites ----------
section "Installing prerequisite packages"
sudo apt update
sudo apt install -y \
  curl \
  gnupg2 \
  lsb-release \
  ca-certificates \
  software-properties-common \
  locales \
  build-essential

info "Configuring locale en_US.UTF-8..."
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# =============================================================================
#  ROS 1 NOETIC (Ubuntu 20.04)
# =============================================================================
install_ros1_noetic() {
  section "Adding ROS 1 repository and key"
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros1-latest.list'
  curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -

  section "Installing ROS 1 Noetic Desktop Full"
  sudo apt update
  sudo apt install -y \
    ros-noetic-desktop-full \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool

  section "Setting up rosdep"
  if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
  else
    info "rosdep already initialized, skipping."
  fi
  rosdep update

  section "Configuring shell environment"
  ROS_SOURCE="source /opt/ros/noetic/setup.bash"
  grep -Fq "$ROS_SOURCE" ~/.bashrc || {
    printf "\n# ROS 1 Noetic\n%s\n" "$ROS_SOURCE" >> ~/.bashrc
    info "Added ROS 1 Noetic source line to ~/.bashrc"
  }
  source /opt/ros/noetic/setup.bash

  section "Creating catkin workspace"
  mkdir -p ~/catkin_ws/src
  cd ~/catkin_ws
  source /opt/ros/noetic/setup.bash
  catkin_make
  if ! grep -Fq "catkin_ws/devel/setup.bash" ~/.bashrc; then
    printf "\n# Catkin Workspace\nsource ~/catkin_ws/devel/setup.bash\n" >> ~/.bashrc
  fi

  section "Verification"
  command -v roscore >/dev/null 2>&1 || fail "roscore not found after install."
  info "ROS 1 Noetic installed successfully."
  echo ""
  echo "  Run:  roscore"
  echo "  Demo: rosrun turtlesim turtlesim_node"
}

# =============================================================================
#  ROS 2 HUMBLE (Ubuntu 22.04)
# =============================================================================
install_ros2_humble() {
  section "Enabling universe repository"
  sudo add-apt-repository -y universe

  section "Adding ROS 2 repository and key"
  sudo mkdir -p /usr/share/keyrings
  sudo curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu ${UBUNTU_CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/ros2.list >/dev/null

  section "Installing ROS 2 Humble Desktop"
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y \
    ros-humble-desktop \
    python3-rosdep \
    python3-colcon-common-extensions \
    python3-argcomplete

  section "Setting up rosdep"
  if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
  else
    info "rosdep already initialized, skipping."
  fi
  rosdep update

  section "Configuring shell environment"
  ROS_SOURCE="source /opt/ros/humble/setup.bash"
  grep -Fq "$ROS_SOURCE" ~/.bashrc || {
    printf "\n# ROS 2 Humble\n%s\n" "$ROS_SOURCE" >> ~/.bashrc
    info "Added ROS 2 Humble source line to ~/.bashrc"
  }
  source /opt/ros/humble/setup.bash

  section "Creating colcon workspace"
  mkdir -p ~/ros2_ws/src
  cd ~/ros2_ws
  colcon build --symlink-install 2>/dev/null || true
  if ! grep -Fq "ros2_ws/install/setup.bash" ~/.bashrc; then
    printf "\n# Colcon Workspace\n[ -f ~/ros2_ws/install/setup.bash ] && source ~/ros2_ws/install/setup.bash\n" >> ~/.bashrc
  fi

  section "Verification"
  command -v ros2 >/dev/null 2>&1 || fail "ros2 command not found after install."
  info "ROS 2 Humble installed successfully."
  echo ""
  echo "  Test: ros2 run demo_nodes_cpp talker"
  echo "  Test: ros2 run demo_nodes_py listener  (new terminal)"
}

# ---------- Run the correct installer ----------
if [ "$ROS_VERSION" -eq 1 ]; then
  install_ros1_noetic
else
  install_ros2_humble
fi

# ---------- Done ----------
section "Setup complete"
echo "Open a new terminal or reload your shell:"
echo ""
echo "  source ~/.bashrc"
echo ""
echo "Ubuntu version : ${VERSION_ID}"
echo "ROS distro     : ${ROS_DISTRO}"
echo ""

