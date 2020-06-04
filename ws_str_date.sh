function ws_strtotime() {
	if [[ $GNU_DATE -eq 1 ]]; then
		date --date="$1" +%s
	elif [[ -n $PHP ]]; then
		$PHP -r "print strtotime(\"$1\");"
	else
		echo "error";
	fi
}

# The follow function converts UNIX (epoch) times into the given format. The reason for its existence is because --date=@ is not part of POSIX.
# Input: $1 = epoch time, $2 = output format (accepted by the system's date binary)
function ws_date_from_epoch() {
	if [[ ${BASH_VERSINFO[0]} -ge 4 && ${BASH_VERSINFO[1]} -ge 2 ]]; then
		printf "%($2)T" "$1"
	elif [[ $GNU_DATE -eq 1 ]]; then
		date --date=@"$1" +"$2"
	else
		date -r "$1" +"$2"
	fi
}
