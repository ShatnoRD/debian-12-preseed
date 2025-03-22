# Debian 12 Preseed for Ansible Integration

This repository contains tools to create a customized Debian 12 (Bookworm) installation ISO with preseed configuration. The primary purpose is to initialize new systems that will later be managed by Ansible.

## Overview

The preseed configuration automates the Debian installation process, creating a bare system that's ready for Ansible management. This approach:

1. Installs a minimal Debian 12 system without user interaction, that can be further customized by Ansible
2. Injects your SSH public key for passwordless Ansible access

## Prerequisites

1. **Install genisoimage**: This tool is required to create the custom ISO
   ```bash
   sudo apt-get update && sudo apt-get install -y genisoimage
   ```

2. **Install isohybrid**: This tool is required to make the ISO bootable as a USB device with UEFI support
   ```bash
   sudo apt-get update && sudo apt-get install -y syslinux syslinux-utils
   ```

3. **Debian netinst ISO**: Download the Debian 12 netinst ISO from the [Debian download page](https://www.debian.org/download) if not using the included one

4. **SSH key pair**: Generate or use an existing key pair for Ansible automation

## Usage

### Generating the Preseed ISO

Run the `assemble_preseed_iso.sh` script to create a customized installation ISO:

### Customizing the Installation

The default configuration targets **GPT partitioning with UEFI boot**. If your target system has different requirements:

- **GRUB Configuration**: Modify `grub.cfg` to change boot parameters or support legacy BIOS systems
- **Preseed Configuration**: Edit `preseed.cfg` to adjust:
  - Partitioning scheme (current setup uses GPT)
  - Boot method (UEFI vs. BIOS)
  - Package selection
  - Network configuration

Both files contain comments explaining the major configuration sections. For legacy BIOS or MBR partitioning, you'll need to modify the partitioning sections in the preseed file.

#### Script Options

The script accepts the following options:

```bash
Usage: ./assemble_preseed_iso.sh [options]
Options:
  -i, --iso PATH       Source ISO file path (default: ./debian-12.10.0-amd64-netinst.iso)
  -g, --grub PATH      Custom GRUB config file (default: ./grub.cfg)
  -p, --preseed PATH   Custom preseed file (default: ./preseed.cfg)
  -k, --key PATH       SSH public key to include (default: ~/.ssh/id_rsa.pub)
  -o, --output PATH    Output ISO path (default: ./debian-12-preseed.iso)
  -h, --help           Display this help message
```

Example with custom options:
```bash
./assemble_preseed_iso.sh --iso ~/Downloads/debian-12.10.0-amd64-netinst.iso --key ~/.ssh/custom_key.pub
```

## Ansible Integration

This preseed setup is designed to work seamlessly with Ansible:

1. **Initial Access**: The default root password is set to `r00tme` during installation
2. **Secure Management**: The preseed process injects your SSH public key, allowing Ansible to connect securely
3. **Password Management**: Your Ansible playbooks should immediately secure the system by changing the default password

## Security Note

The default password (`r00tme`) is only intended for initial setup. Your Ansible playbooks should:

1. Change the root password
2. Create proper user accounts with appropriate privileges
3. Configure SSH according to your security policies

## Additional Resources

- [Debian Installer/Writable USB Stick](https://wiki.debian.org/DebianInstaller/WritableUSBStick)
- [Debian Preseed Documentation](https://www.debian.org/releases/stable/amd64/apb.en.html)