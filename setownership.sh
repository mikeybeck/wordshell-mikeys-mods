# A function to recursively set directory ownership, recursively, based upon the owner of a specified file. Hopefully again this will "just work", but if not please let us know and send us the output of /bin/uname

function setownership() {
# Input: $1 = the reference file
# Input: $2 = the directory to set ownership upon
# Note - where you specify a directory finishing with /, this routine will not touch that directory itself (or dotfiles inside it)
if [[ $UNAME = "Linux" || $UNAME =~ ^Cygwin || $UNAME =~ ^CYGWIN ]]; then
	# GNU style
	if [[ $2 =~ \/$ ]]; then
		[[ $DEBUG -ge 1 ]] && ws_event_debug "setownership: GNU: contents: $2"
		chown -R --reference="$1" "$2"/*
		if [[ $SELINUX -eq 1 ]]; then
			if [[ $DEBUG -ge 1 ]]; then
				ws_event_debug "setownership: SELinux chcon: contents: $2"
				chcon -R --reference="$1" "$2"/*
			else
				chcon -R --reference="$1" "$2"/* 2>/dev/null
			fi
		fi
	else
		[[ $DEBUG -ge 1 ]] && ws_event_debug "setownership: GNU: $2"
		chown -R --reference="$1" "$2"
		if [[ $SELINUX -eq 1 ]]; then
			if [[ $DEBUG -ge 1 ]]; then
				ws_event_debug "setownership: SELinux chcon: $2"
				chcon -R --reference="$1" "$2"
			else
				chcon -R --reference="$1" "$2" 2>/dev/null
			fi
		fi
	fi
else
	# Should work on some BSDs (including Mac OS X)
	local REFOWNER=`stat -f %u "$1"`
	local REFGROUP=`stat -f %g "$1"`
	if [[ $2 =~ \/$ ]]; then
		[[ $DEBUG -ge 1 ]] && ws_event_debug "setownership: BSD: contents: $2"
		chown -R $REFOWNER:$REFGROUP "$2"/*
	else
		[[ $DEBUG -ge 1 ]] && ws_event_debug "setownership: BSD: $2"
		chown -R $REFOWNER:$REFGROUP "$2"
	fi
fi
}
