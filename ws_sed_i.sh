# sed -i is not part of POSIX; an -i option is present on BSDs but works differently to GNU.
# Must provide the filename as $2
function ws_sed_i() {
	if [[ $UNAME = "Linux" || $UNAME =~ ^Cygwin || $UNAME =~ ^CYGWIN ]]; then
		sed -i "$@"
	elif [[ $UNAME = "FreeBSD" || $UNAME = "Darwin" ]]; then
		sed -i "" "$@"
	else
		local SED_TMP=`mktemp`
		sed "$@" >$SED_TMP
		cat $SED_TMP >"$2"
		rm -f $SED_TMP
	fi
}
