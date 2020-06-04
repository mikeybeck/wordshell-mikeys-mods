# These functions allow us to follow the flow more easily when debugging
function ws_cd() {
	[[ $DEBUG -ge 1 ]] && ws_event_debug "ws_cd: (`caller`): $1"
	cd "$1" || abort_die 71 "Failed to cd ($1), pwd=`pwd`, caller=`caller`"
}

function ws_pushd() {
	if [[ $DEBUG -ge 1 ]]; then
		ws_event_debug "ws_pushd: (`caller`): (pwd: `pwd`)"
		pushd "$1" >/dev/stderr || abort_die 71 "Failed to pushd ($1), pwd=`pwd`"
	else
		pushd "$1" >/dev/null || abort_die 71 "Failed to pushd ($1), pwd=`pwd`"
	fi
}

function ws_popd() {
	if [[ $DEBUG -ge 1 ]]; then
		ws_event_debug "ws_popd: (`caller`): (pwd: `pwd`)"
		popd >/dev/stderr || abort_die 71 "Failed to popd"
	else
		popd >/dev/null || abort_die 71 "Failed to popd"
	fi
}
