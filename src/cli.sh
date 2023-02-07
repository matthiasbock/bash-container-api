
#
# Select the program that will be used for container manipulation
#
# Note:
# If the CONTAINER_CLI variable is set,
# it's value will override any other setting.
# If no program is configured,
# a suitable one is chosen automatically.
#
if is_set CONTAINER_CLI; then
  # Use cli defined by the caller
  container_cli="$CONTAINER_CLI"
fi
if is_set container_cli; then
  # Check whether the configured program is available
  if ! is_program_available $container_cli; then
    echo "Warning: Configured container CLI not found: \"$container_cli\"" >&2
  fi
else
  # No program is defined, choose one that is available
  if is_program_available podman; then
    container_cli="$(which podman)"
    echo "Using $container_cli for container manipulation." >&2
  elif is_program_available docker; then
    container_cli="$(which docker)"
    echo "Using $container_cli for container manipulation." >&2
  else
    echo "Error: No program for container manipulation is available." >&2
  fi
fi


#
# Determine whether the currently set container CLI is valid
#
function verify_container_cli() {
  [[ "$container_cli" != "" ]] || return $ERROR_ILLEGAL_CONTAINER_CLI
  is_program_available "$container_cli" || return $ERROR_ILLEGAL_CONTAINER_CLI
}
