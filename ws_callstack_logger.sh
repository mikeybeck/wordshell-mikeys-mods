# The next function (only) is under the MIT licence
# http://blog.yjl.im/2012/01/printing-out-call-stack-in-bash.html
function ws_callstack() {
  local i=0
  local FRAMES=${#BASH_LINENO[@]}
  # FRAMES-2 skips main, the last one in arrays
  for ((i=FRAMES-2; i>=0; i--)); do
    echo '  File' \"${BASH_SOURCE[i+1]}\", line ${BASH_LINENO[i]}, in ${FUNCNAME[i+1]}
    # Grab the source code of the line
    sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i+1]}"
  done
}

function ws_logger() {

	# Code everywhere calls into here (eventually) to log an event.
	# The task here is to decide what to do with it. This can be outputting on the screen, logging, syslog, etc.

	# If/when adding syslog, note that whilst POSIX specifies no parameters for logger, Linux/Net/Open/FreeBSD/Solaris/Mac all accept -i -p and -t

	# Input:
	# $1 = log level
	# $2 = log message

	# Screen printing: all ERROR and WARNING level messages; and everything when in debug mode
	if [[ ( $1 = "ERROR" || $1 = "WARNING" ) || $DEBUG -ge 1 ]]; then
		# Use bold only with ERROR/WARNING
		[[ ( $1 = "ERROR" || $1 = "WARNING" ) ]] && echo -n "${BOLD}" >/dev/stderr
		echo -n "$1: " >/dev/stderr
		[[ ( $1 = "ERROR" || $1 = "WARNING" ) ]] && echo -n "${OFFBOLD}" >/dev/stderr
		echo "$2" >/dev/stderr
	fi

	# File logging: all ERROR, WARNING and NOTICE messages
	if [[ $1 = "ERROR" || $1 = "WARNING" || $1 = "NOTICE" ]]; then
		# Log if the working directory path is now known, and if the log file location is not a symlink
		[[ -n $WORKINGDIR_FULL && ! -L $WORKINGDIR_FULL/log ]] && echo "`$DATE +'%Y-%b-%d %T'` [$WORDSHELL_PID] $1: $2" >> "$WORKINGDIR_FULL/log"
	fi

}
