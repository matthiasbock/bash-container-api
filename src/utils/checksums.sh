
function verify_image_integrity()
{
  echo "Verifying image integrity..."
  md5=$(md5sum "$rom_local" | cut -d " " -f 1)
  if [ "$md5" != "$rom_md5sum" ]; then
    echo "md5sum is $md5, expected $rom_md5sum."
    echo "Error: File integrity verification failed. Aborting."
    exit 1
  fi
  sha256=$(sha256sum "$rom_local" | cut -d " " -f 1)
  if [ "$sha256" != "$rom_sha256sum" ]; then
    echo "sha256sum is $sha256, expected $rom_sha256sum."
    echo "Error: File integrity verification failed. Aborting."
    exit 1
  fi
  echo "Verification successful."
}
