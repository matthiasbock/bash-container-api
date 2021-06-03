
function update_networks()
{
	export networks=$($container_cli network ls --format "{{.Name}}")
}


# TODO: Unfinished function follows
function network_create()
{
  update_networks
  if [ "$(echo $networks | fgrep $net)" == "" ]; then
    echo -n "Creating missing buildenv network '$net' ... "
    $container_cli network create $net &> /dev/null
    echo "Done."
  fi
}


# TODO: Pods
