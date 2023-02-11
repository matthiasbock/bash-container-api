
#
# Functions operating on the host machine
#
local_sh="$(realpath "${BASH_SOURCE[0]}")"


#
# @return 0 if an environment with the given name is set (may be empty)
# @return 1 if no such environment variable is set
#
function is_set() {
  local variable_name="$1"
  printenv $variable_name &>/dev/null
  if [ $? == 0 ]; then
    return 0
  fi
  return 1
}


#
# Return whether the given program is available or not
#
# @return 0 when program is available and it's full path on stdout
# @return 1 otherwise and nothing on stdout
#
function is_program_available() {
  local program_name="$1"
  local which="$(which $program_name)"
  if [ "$which" != "" ]; then
    return 0
  fi
  return 1
}


function is_active_mountpoint()
{
  local mountpoint="$1"
  if [ "$(mount | fgrep $mountpoint)" != "" ]; then
    return 0
  else
    return 1
  fi
}



#
# Return the running Linux kernel's architecture
#
# TODO
