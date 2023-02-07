
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
if [ "$container_cli" == "" ]; then
  # container_cli must not be left empty
  # or unforseeable things may happen when container functions are called.
  container_cli="@echo \$ podman-stub"
fi
