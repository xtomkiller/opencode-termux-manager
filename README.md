# OpenCode Termux Manager

A simple and powerful manager for running OpenCode CLI on Android through Termux and Ubuntu Proot-Distro.

## Overview

OpenCode Termux Manager simplifies the process of installing and managing the OpenCode CLI on ARM64 Android devices.

The official Linux ARM64 OpenCode binary requires the GNU C Library (glibc), while Android uses Bionic. Because of this compatibility difference, OpenCode cannot reliably run directly inside Termux.

This project solves that problem by running OpenCode inside an Ubuntu environment managed through Proot-Distro.

## Features

- Install OpenCode automatically
- Reinstall OpenCode when needed
- Update to the latest configured version
- Uninstall OpenCode completely
- Check installation and environment status
- Interactive terminal-based UI
- Automatic Ubuntu setup
- Automatic dependency installation
- Linux ARM64 binary support
- Current directory support
- Simple Termux launcher command
- No root access required

## Requirements

- Android device with ARM64 architecture
- Termux
- Internet connection
- Sufficient storage space

Root access is not required.

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/opencode-termux-manager.git
cd opencode-termux-manager 
chmod +x opencode-manager.sh
bash opencode-manager.sh
