
#
# Functions for interaction with web pages
#
# Note:
# Uses functions from constants.sh and local.sh.
#
web_sh="$(realpath "${BASH_SOURCE[0]}")"
cwd="$(dirname "$web_sh")"

# Source dependencies
if [ "$constants_sh" == "" ]; then
 . "$cwd/../constants.sh"
fi
if [ "$local_sh" == "" ]; then
 . "$cwd/local.sh"
fi
unset cwd

default_user_agent="bash-container-library"


#
# Retrieve the page at the given URL
#
# @return 0 upon success and the page content on stdout
# @return 1 upon errors and possibly an error message on stdout
#
function get_page() {

  local url="$1"

  # Check argument
  [[ "$url" != "" ]] || return $ERROR_MISSING_ARGUMENT

  # If no user_agent is defined globally, use the default one.
  if ! is_set user_agent; then
    local user_agent="$default_user_agent";
  fi

  # Select a program for download
  if is_program_available wget; then
    wget -q -O - --user-agent="$user_agent" "$url" 2>/dev/null || return $ERROR_CRAWLER_FAILED
  # TODO: support using curl or aria2c as alternatives
  else
    return $ERROR_CRAWLER_MISSING
  fi
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
  [[ "$filepath" != "" ]] || return $ERROR_MISSING_ARGUMENT
  [[ "$url" != "" ]] || return $ERROR_MISSING_ARGUMENT

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
    aria2c -c --user-agent="$user_agent" --dir="$dir" --out="$fn" $urls 1>&2 || return $ERROR_CRAWLER_FAILED
  elif is_program_available wget; then
    wget -c --progress=dot --user-agent="$user_agent" -O "$filepath" $url 1>&2 || return $ERROR_CRAWLER_FAILED
  elif is_program_available curl; then
    curl -C - --user-agent "$user_agent" -o "$filepath" $url 1>&2 || return $ERROR_CRAWLER_FAILED
  else
    echo "Error: No downloader program is available."
    return $ERROR_CRAWLER_MISSING
  fi

  # Determine success
  [[ -f "$filepath" ]] || return $ERROR_COMMAND_FAILED
}
