# WQF7010 — Robotics and Automation
## ROS Installation Guide for WSL Ubuntu

> **Supported Platforms**
> | Ubuntu Version | ROS Distribution | Type |
> |---|---|---|
> | 20.04 LTS (Focal) | ROS 1 Noetic | Long-Term Support |
> | 22.04 LTS (Jammy) | ROS 2 Humble | Long-Term Support |

---

## Prerequisites (Windows Side)

Before starting, ensure WSL2 is installed on your Windows machine.

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
wsl --set-default-version 2
```

Check your Ubuntu version inside WSL:

```bash
lsb_release -a
```

---

## Quick Start

### Step 1 — Copy the installer into WSL

From your Windows filesystem, open WSL and navigate to the project:

```bash
cd /mnt/c/path/to/ros_insaller_wsl_ubuntu
```

### Step 2 — Fix line endings and set permissions

```bash
sed -i 's/\r$//' install_ros_wsl.sh
chmod +x install_ros_wsl.sh
```

### Step 3 — Run the installer

```bash
./install_ros_wsl.sh
```

The script **automatically detects** your Ubuntu version and installs the correct ROS distribution:
- Ubuntu **20.04** → installs **ROS 1 Noetic**
- Ubuntu **22.04** → installs **ROS 2 Humble**

### Step 4 — Reload shell environment

```bash
source ~/.bashrc
```

---

## ROS 1 Noetic (Ubuntu 20.04)

### Verify Installation

```bash
roscore
```

Expected output:
```
started roslaunch server http://<hostname>:XXXXX/
ROS_MASTER_URI=http://<hostname>:11311/
process[master]: started with pid [XXXXX]
started core service [/rosout]
```

### First Demo — TurtleSim

**Terminal 1** — Start ROS master:
```bash
roscore
```

**Terminal 2** — Launch turtle window:
```bash
source ~/.bashrc
rosrun turtlesim turtlesim_node
```

**Terminal 3** — Control the turtle:
```bash
source ~/.bashrc
rosrun turtlesim turtle_teleop_key
```

#### Keyboard Controls (in turtle_teleop_key terminal)

| Key | Action |
|-----|--------|
| `↑` Arrow Up | Move forward |
| `↓` Arrow Down | Move backward |
| `←` Arrow Left | Rotate left |
| `→` Arrow Right | Rotate right |
| `Space` | Stop |
| `Ctrl+C` | Quit |

> **Note:** Click the `turtle_teleop_key` terminal to keep it focused before pressing keys.

### Useful ROS 1 Commands

```bash
# List all running nodes
rosnode list

# List all active topics
rostopic list

# Print messages from a topic
rostopic echo /turtle1/pose

# Show node info
rosnode info /turtlesim

# Show topic info
rostopic info /turtle1/cmd_vel
```

### Catkin Workspace

The installer creates `~/catkin_ws` automatically. To create a new package:

```bash
cd ~/catkin_ws/src
catkin_create_pkg my_package std_msgs rospy roscpp
cd ~/catkin_ws
catkin_make
source devel/setup.bash
```

---

## ROS 2 Humble (Ubuntu 22.04)

### Verify Installation

```bash
ros2 --help
```

### First Demo — Talker / Listener

**Terminal 1:**
```bash
source ~/.bashrc
ros2 run demo_nodes_cpp talker
```

**Terminal 2:**
```bash
source ~/.bashrc
ros2 run demo_nodes_py listener
```

Expected: Terminal 2 prints messages published by Terminal 1.

### Useful ROS 2 Commands

```bash
# List all running nodes
ros2 node list

# List all active topics
ros2 topic list

# Print messages from a topic
ros2 topic echo /chatter

# Show topic info
ros2 topic info /chatter

# Check ROS 2 version
ros2 --version
```

### Colcon Workspace

The installer creates `~/ros2_ws` automatically. To create a new package:

```bash
cd ~/ros2_ws/src
ros2 pkg create --build-type ament_cmake my_package
cd ~/ros2_ws
colcon build --symlink-install
source install/setup.bash
```

---

## Troubleshooting

### `/usr/bin/env: 'bash\r': No such file or directory`

Windows line endings in the script. Fix with:

```bash
sed -i 's/\r$//' install_ros_wsl.sh
```

### `[ERROR] ROS 2 Humble is targeted for Ubuntu 22.04`

Your WSL is running Ubuntu 20.04. The script will automatically install ROS 1 Noetic instead. If you want ROS 2, upgrade to Ubuntu 22.04:

```powershell
# In Windows PowerShell
wsl --install -d Ubuntu-22.04
```

### `sudo: command not found`

```bash
apt-get install -y sudo
```

### `rosdep update` fails

```bash
rosdep update --include-eol-distros
```

### ROS 1 nodes can't communicate

Ensure `roscore` is running in a separate terminal before launching any nodes.

### Permission denied on script

```bash
chmod +x install_ros_wsl.sh
```

---

## Project Structure

```
WQF7010 ROBOTICS AND AUTOMATION/
├── install_ros_wsl.sh      # Unified ROS installer (ROS 1 + ROS 2)
└── README.md               # This documentation file
```

---
You’re hitting a Python-environment mismatch (Conda Python is being used for ROS Noetic), so I’ll walk you through resetting to system Python and installing missing ROS Python deps.

### Checklist
- [ ] Exit Conda so ROS uses Ubuntu/system Python
- [ ] Install missing package `python3-empy` (and common ROS Python deps)
- [ ] Clean catkin cache/build artifacts
- [ ] Rebuild with `/usr/bin/python3`
- [ ] Verify `em` and `rospy` imports

From your log, this is the key line:
- `Using PYTHON_EXECUTABLE: /home/mameenali/anaconda3/bin/python3`

ROS1 Noetic on Ubuntu should typically build against system Python, not Conda.

```bash
conda deactivate
```

If Conda auto-activates, disable that:

```bash
conda config --set auto_activate_base false
exec bash
```

Install required packages:

```bash
sudo apt update
sudo apt install -y python3-empy python3-rospkg python3-catkin-pkg python3-yaml
```

Clean workspace (to remove cached Conda Python path):

```bash
cd ~/catkin_ws
rm -rf build devel
```

Source ROS and rebuild with system Python explicitly:

```bash
source /opt/ros/noetic/setup.bash
catkin_make -DPYTHON_EXECUTABLE=/usr/bin/python3
```

Verify:

```bash
python3 -c "import em; print('em OK')"
python3 -c "import rospy; print('rospy OK')"
```

Then source workspace:

```bash
source ~/catkin_ws/devel/setup.bash
```

If you want to keep using Conda for other projects, best practice is:
1. Use **system Python** for ROS1 builds/runs.
2. Only activate Conda in non-ROS terminals.
## References

- [ROS 1 Noetic Installation](http://wiki.ros.org/noetic/Installation/Ubuntu)
- [ROS 2 Humble Installation](https://docs.ros.org/en/humble/Installation/Ubuntu-Install-Debians.html)
- [WSL2 Setup Guide](https://learn.microsoft.com/en-us/windows/wsl/install)
- [ROS Tutorials](http://wiki.ros.org/ROS/Tutorials)
- [ROS 2 Tutorials](https://docs.ros.org/en/humble/Tutorials.html)

---

*Course: WQF7010 Robotics and Automation*

