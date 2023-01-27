
#
# Functions for interaction with web pages
#
# Note:
# Requires local.sh to be included earlier.
#

user_agent_default="bash-container-library"


#
# Retrieve the page at the given URL
#
# @return 0 upon success and the page content on stdout
# @return 1 upon errors and possibly an error message on stdout
#
function get_url() {
  local url="$1"

  # If no user_agent is defined globally, use the default one.
  if ! is_set user_agent; then
    local user_agent=user_agent_default;
  fi

  #
  # Select an available program for download
  #
  if is_program_available wget; then
    wget -q -O - --user-agent="$user_agent" "$url" 2>/dev/null \
    || { echo "Error: wget failed to get $url."; return 1; }
    return 0
  fi

  echo "Error: No program for web page download is available."
  return 1
}
