
#
# Make sure a tool for container manipulation is defined
#
if is_set CONTAINER_CLI; then
  # Use cli defined by the caller
  container_cli="$CONTAINER_CLI"
fi
if [ "$container_cli" != "" ]; then
  if [ "$container_cli" == "stub" ]; then
    # Use stub
    container_cli="container_cli_stub"
  elif ! is_program_available $container_cli; then
    echo "Warning: Configured container CLI not found: \"$container_cli\""
  fi
else
  # Guess the CLI to use
  if is_program_available podman; then
    container_cli="$(which podman)"
    echo "Using $container_cli for container manipulation."
  elif is_program_available docker; then
    container_cli="$(which docker)"
    echo "Using $container_cli for container manipulation."
  else
    # Should not be left empty, in case the container functions are called regardless.
    container_cli="container_cli_stub"
    echo "Warning: No program for container manipulation is available."
  fi
fi
