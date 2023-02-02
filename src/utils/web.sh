
#
# Functions for interaction with web pages
#
# Note:
# Requires local.sh to be included earlier.
#

default_user_agent="bash-container-library"


#
# Retrieve the page at the given URL
#
# @return 0 upon success and the page content on stdout
# @return 1 upon errors and possibly an error message on stdout
#
function get_page() {
  local url="$1"

  # If no user_agent is defined globally, use the default one.
  if ! is_set user_agent; then
    local user_agent="$default_user_agent";
  fi

  # Select a program for download
  if is_program_available wget; then
    wget -q -O - --user-agent="$user_agent" "$url" 2>/dev/null || return 1
    return 0
  # TODO: support using curl or aria2c as alternatives
  fi
  return 1
}


#
# Download a file to a given path from one or more URLs (parallel download)
#
# @return 0 upon success
# @return 1 upon errors
#
function get_file() {
  local filepath="$1"
  local urls=${@:2}
  local url=$2

  # Check arguments
  [[ "$filepath" != "" ]] || return 1
  [[ "$url" != "" ]] || return 1

  # If no user_agent is defined globally, use the default one.
  if ! is_set user_agent; then
    local user_agent="$default_user_agent";
  fi

  # Make sure the target directory exists
  local dir="$(dirname "$filepath")"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi

  # Select a program for download
  if is_program_available aria2c; then
    local dir="$(dirname "$filepath")"
    local fn="$(basename "$filepath")"
    aria2c -c --user-agent="$user_agent" --dir="$dir" --out="$fn" $urls || return 1
  elif is_program_available wget; then
    wget -c --progress=dot --user-agent="$user_agent" -O "$filepath" $url || return 1
  elif is_program_available curl; then
    curl -C - --user-agent "$user_agent" -o "$filepath" $url || return 1
  else
    echo "Error: No download program is available."
    return 1
  fi

  # Return success status
  [[ -f "$filepath" ]] || return 1
  return 0
}
