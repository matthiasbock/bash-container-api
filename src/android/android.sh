
#
# Tools to convert an Android image into a Docker container with qemu
# - download image
# - verify download
# - unpack image
# - pack unpacked files into a container
#

function fetch_rom()
{
  # Download ROM
  if [ ! -e "$rom_local" ]; then
    rom_local=$(basename "$rom_local")
  fi
  get_file "$rom_url" "$rom_local"
}


function android_unpack_boot_partition()
{
  echo "Extracting boot partition..."
  unzip -o "$rom_local" boot.img \
    || { echo "An error occured while unpacking the ROM. Aborting."; exit 1; }
  echo "ROM unpacked."

  # Unpack boot image
  echo "Unpacking boot image..."
  abootimg -x boot.img \
    || { echo "Error: Failed to unpack boot partition. Aborting."; exit 1; }
  rm boot.img

  echo "Done."
}



function android_unpack_system_partition()
{
  echo "Extracting system partition from ROM..."
  unzip -o "$rom_local" system.new.dat system.transfer.list \
    || { echo "An error occured while unpacking the ROM. Aborting."; exit 1; }
  echo "ROM unpacked."

  echo "Unpacking system image..."
  $sdat2img system.transfer.list system.new.dat system.img
  rm -v system.transfer.list system.new.dat

  echo "Unpacking system image..."
  if [ ! -d system ]; then
    mkdir system
  fi
  set -x
  if is_active_mountpoint "$(realpath system)"; then
    sudo umount -f system
  fi
  sudo mount -t ext4 -o loop,ro,seclabel,relatime,user_xattr,barrier=1 system.img system \
    || { echo "Error: Failed to mount system partition. Aborting."; exit 1; }
  sudo rsync -ariHS system image/
  sudo umount -d system
  set +x
  rmdir system
  rm system.img

  echo "Done."
}


function android_mkimage()
{
  set -e

  fetch_rom
  verify_image_integrity

  echo "Creating container image..."
  if [ -d image ]; then sudo rm -vfR image/; fi
  mkdir -p image/boot/

  unpack_system_partition
  unpack_boot_partition

  # Extract initial ramdisk to image
  echo "Extracting initial ramdisk..."
  mv initrd.img initrd.img.gz
  gzip -d initrd.img.gz
  sudo cpio -vud --sparse -D image/ --extract < initrd.img
  echo "Done."

  # Add kernel and initial ramdisk to image
  mv -v zImage initrd.img bootimg.cfg image/boot/

  # Add qemu
  cp -av $(which qemu-arm-static) image/

  set +e
}
