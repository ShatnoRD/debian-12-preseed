#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default variables
ISO_PATH="$SCRIPT_DIR/debian-12.10.0-amd64-netinst.iso"
MOUNT_DIR="$HOME/iso_mount"
WORK_DIR="$HOME/iso_work"
GRUB_FILE="$SCRIPT_DIR/grub.cfg"
PRESEED_FILE="$SCRIPT_DIR/preseed.cfg"
PUB_KEY="$HOME/.ssh/id_rsa.pub"
DEST_PUB_KEY="ansible-rescue.pub"
OUTPUT_ISO="$SCRIPT_DIR/debian-12-preseed.iso"

# Check for required tools
check_required_tools() {
    if ! command -v genisoimage >/dev/null 2>&1; then
        echo "Error: genisoimage is not installed. Please install it with:"
        echo "sudo apt-get update && sudo apt-get install -y genisoimage"
        exit 1
    fi

    if ! command -v isohybrid >/dev/null 2>&1; then
        echo "Warning: isohybrid is not installed. The ISO may not be bootable as USB."
        echo "Install with: sudo apt-get update && sudo apt-get install -y syslinux syslinux-utils"
        HAVE_ISOHYBRID=false
    else
        HAVE_ISOHYBRID=true
    fi
}

# Display usage information
function usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --iso PATH       Source ISO file path (default: ./debian-12.10.0-amd64-netinst.iso)"
    echo "  -g, --grub PATH      Custom GRUB config file (default: ./grub.cfg)"
    echo "  -p, --preseed PATH   Custom preseed file (default: ./preseed.cfg)"
    echo "  -k, --key PATH       SSH public key to include (default: ~/.ssh/id_rsa.pub)"
    echo "  -o, --output PATH    Output ISO path (default: ./debian-12-preseed.iso)"
    echo "  -h, --help           Display this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -i | --iso)
        ISO_PATH="$2"
        shift 2
        ;;
    -g | --grub)
        GRUB_FILE="$2"
        shift 2
        ;;
    -p | --preseed)
        PRESEED_FILE="$2"
        shift 2
        ;;
    -k | --key)
        PUB_KEY="$2"
        shift 2
        ;;
    -o | --output)
        OUTPUT_ISO="$2"
        shift 2
        ;;
    -h | --help)
        usage
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
done

# Check for required tools first
check_required_tools

# Check if files exist
for file in "$ISO_PATH" "$GRUB_FILE" "$PRESEED_FILE" "$PUB_KEY"; do
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        exit 1
    fi
done

echo "Using the following files:"
echo "Source ISO:   $ISO_PATH"
echo "GRUB config:  $GRUB_FILE"
echo "Preseed file: $PRESEED_FILE"
echo "SSH key:      $PUB_KEY"
echo "Output ISO:   $OUTPUT_ISO"
echo

# Clean up any previous run
if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
    echo "Unmounting previous mount..."
    sudo umount "$MOUNT_DIR" 2>/dev/null || true
fi
if [ -d "$MOUNT_DIR" ]; then
    rmdir "$MOUNT_DIR" 2>/dev/null || true
fi
if [ -d "$WORK_DIR" ]; then
    sudo rm -rf "$WORK_DIR" 2>/dev/null || true
fi

# Create fresh directories
mkdir -p "$MOUNT_DIR"
mkdir -p "$WORK_DIR"

# Mount the ISO
echo "Mounting ISO..."
sudo mount -o loop "$ISO_PATH" "$MOUNT_DIR"

# Copy the ISO contents to a working directory with sudo
echo "Copying ISO contents (this may take a while)..."
sudo cp -a "$MOUNT_DIR/." "$WORK_DIR/"

# Unmount the ISO
echo "Unmounting ISO..."
sudo umount "$MOUNT_DIR"

# Give ownership of the work directory to the current user
echo "Setting permissions..."
sudo chown -R $(id -u):$(id -g) "$WORK_DIR"
sudo chmod -R u+w "$WORK_DIR"

# Create directories if they don't exist
mkdir -p "$WORK_DIR/boot/grub"
mkdir -p "$WORK_DIR/preseed"

# Copy the GRUB and preseed files to the working directory
echo "Copying configuration files..."
cp "$GRUB_FILE" "$WORK_DIR/boot/grub/"
cp "$PRESEED_FILE" "$WORK_DIR/"

# Copy and rename the public key
echo "Copying SSH public key as $DEST_PUB_KEY..."
cp "$PUB_KEY" "$WORK_DIR/$DEST_PUB_KEY"

# Create a new ISO with the modified contents
echo "Creating new ISO..."
genisoimage -o "$OUTPUT_ISO" \
    -r -J \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -V "Custom Debian ISO" \
    -A "Debian Custom Installation" \
    "$WORK_DIR"

# Make the ISO hybrid (bootable as USB)
if [ "$HAVE_ISOHYBRID" = true ]; then
    echo "Making ISO hybrid (USB bootable)..."
    isohybrid --uefi "$OUTPUT_ISO"
fi

# Clean up
echo "Cleaning up..."
sudo rm -rf "$WORK_DIR"
sudo rmdir "$MOUNT_DIR"

echo "New ISO created at: $OUTPUT_ISO"
