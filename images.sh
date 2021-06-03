
function update_images()
{
	export images=$($container_cli image ls -a --format "{{.Repository}}:{{.Tag}}")
}


function image_exists()
{
	update_images
	local name="$1"
	if [ "$(echo "$images" | fgrep "$name")" == "" ]; then
		return 1;
	fi
	return 0;
}
