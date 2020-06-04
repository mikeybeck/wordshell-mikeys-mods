# $1 = prompt
# $2 = optional file to delete if user aborts
function check_continue() {
	read -p "$1" -n 1 DOCONT
	echo >/dev/stderr
	if [[ $DOCONT != "c" && $DOCONT != "C" ]]; then
		[[ -n $2 ]] && rm -f "$2"
		abort_die 27 "User chose to abort"
	fi
}
