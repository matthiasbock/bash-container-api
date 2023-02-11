
#
# Functions to interface with GitHub's REST API
#
# Note:
# * Some functions may need GITHUB_TOKEN to be set.
# * Uses functions from web.sh and constants from constants.sh.
# * Depends on jq being installed.
#
# Links:
# - https://docs.github.com/en/rest
# - https://stateful.com/blog/github-api-list-repositories
#
github_sh="$(realpath "${BASH_SOURCE[0]}")"
cwd="$(dirname "$github_sh")"

# Source dependencies
if [ "$web_sh" == "" ]; then
 . "$cwd/../utils/web.sh"
fi
unset cwd


#
# Retrieve all (publicly accessible) information
# about a GitHub user or organization
#
function github_get_public_info_json() {

  local name=$1

  # Check function argument
  [[ "$name" == "" ]] && return $ERROR_ILLEGAL_ARGUMENT

  # Use REST API to get a JSON
  local info=$(get_page https://api.github.com/users/$name)
  local retval=$?
  [[ $retval == 0 ]] || return $retval
  [[ "$info" != "" ]] || return $ERROR_GITHUB_JSON

  # Output JSON to stdout
  echo $info

  # Use jq to parse message from JSON
  local message="$(jq --raw-output '.message' - <<< $info)"
  [[ $? == 0 ]] || return $ERROR_JQ_FAILED

  # A message in the response JSON indicates an error.
  if [ "$message" != "null" ]; then
    return $ERROR_GITHUB_API
  fi
}

#
# Get the type of the GitHub account with the given name
#
function github_get_account_type() {

  local name=$1

  # Get account info JSON
  local info="$(github_get_public_info_json $name)"
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  # Use jq to parse account type from account info JSON
  local account_type=$(jq --raw-output '.type' - <<< $info)
  local retval=$?
  [[ $retval == 0 ]] || return $ERROR_JQ_FAILED

  # Check result
  if ([ "$account_type" != "User" ] && [ "$account_type" != "Organization" ]); then
    echo "Error: Illegal account type for \"$name\": \"$account_type\"" >&2
    return $ERROR_GITHUB_JSON
  fi
}

#
# Determine whether the given account name belongs to a regular user
#
function is_github_user() {

  local name=$1

  # Get account type as string
  local account_type=$(github_get_account_type $name)
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  echo $account_type

  [[ "$account_type" == "User" ]]
  return $?
}

#
# Determine whether the given account name belongs to an organization
#
function is_github_organization() {

  local name=$1

  # Get account type as string
  local account_type=$(github_get_account_type $name)
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  echo $account_type

  [[ "$account_type" == "Organization" ]]
  return $?
}

#
# Get a JSON about a user's or organization's
# publicly accessible git repositories
#
function github_get_public_repos_json() {

  local name=$1

  # Get acount type
  local account_type=$(github_get_account_type $name)
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  # Only two types of accounts can have repos
  if [ "$account_type" == "User" ]; then
    account_type="users"
  elif [ "$account_type" == "Organization" ]; then
    account_type="orgs"
  else
    echo "Error: Illegal account type for \"$name\": $account_type" >&2
    return $GITHUB_JSON_PARSING_FAILED
  fi

  # Use REST API to get a JSON
  local json=$(get_page https://api.github.com/$account_type/$name/repos)
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  echo $json
}

#
# Get the list of a user's or organization's
# publicly accessible git repositories
#
function github_get_public_repos() {

  local name=$1

  # Get repo list as JSON
  local json=$(github_get_public_repos_json $name)
  local retval=$?
  [[ $? == 0 ]] || return $retval

  # Use jq to parse https:// URLs from JSON
  jq --raw-output '.[].http_url' - <<< $json
}
