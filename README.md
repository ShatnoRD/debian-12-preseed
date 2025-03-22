# Debian 12 Preseed for Ansible Integration

This repository provides an automated solution for creating customized Debian 12 (Bookworm) installation ISOs with UEFI/GPT support through preseed configuration, designed to prepare systems for seamless Ansible adoption with pre-configured SSH key access or temporary password authentication.

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

Run the `assemble_preseed_iso.sh` script to create a customized installation ISO. The script will:

1. Extract the contents of the source Debian ISO
2. Inject your preseed configuration and SSH key
3. Create a new bootable ISO configured for UEFI/GPT systems
4. Generate an ISO that performs a completely unattended installation

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

### Customizing the Installation

The default configuration targets **GPT partitioning with UEFI boot**. If your target system has different requirements:

- **GRUB Configuration**: Modify `grub.cfg` to change boot parameters or support legacy BIOS systems
- **Preseed Configuration**: Edit `preseed.cfg` to adjust:
  - Partitioning scheme (current setup uses GPT)
  - Boot method (UEFI vs. BIOS)
  - Package selection
  - Network configuration

Both files contain comments explaining the major configuration sections. For legacy BIOS or MBR partitioning, you'll need to modify the partitioning sections in the preseed file.

## Ansible Integration & Security

This preseed setup prepares your systems for immediate Ansible management:

1. **Initial Access**: The default root password is set to `r00tme` during installation, but this is **only intended for initial setup on secure networks (LANs, VPCs, or isolated environments)**
2. **Secure Management**: The preseed process injects your SSH public key, enabling immediate passwordless Ansible access

Your Ansible playbooks should implement these security best practices:

1. Change the default root password or disable root password login entirely (if enabled)
2. Create proper user accounts with appropriate privileges
3. Configure SSH according to your security policies (key-only authentication, non-standard ports, etc.)

This approach allows for zero-touch provisioning while maintaining a clear path to a secure configuration.

## Additional Resources

- [Debian Installer/Writable USB Stick](https://wiki.debian.org/DebianInstaller/WritableUSBStick)
- [Debian Preseed Documentation](https://www.debian.org/releases/stable/amd64/apb.en.html)