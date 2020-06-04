function url_get() {
# Input: $1=URI If $2=stdout then output on terminal, else (if set) indicates output filename
# We assume one of LFTP and WGET and CURL is there (caller should check first)
# FTP requires you to set tryonlycurl
# $3: Other parameters:
#   e.g. tryonlylftp, tryonlywget, tryonlycurl
#   passwarning (if password will be put on command line)
#   testonly - informs url_get that we wish to test if the server returns an error code. You would likely then also specify $2=stdout and redirect to /dev/null. Note that without this switch, the return code from url_get may be zero in the case of failure; curl does this, returning the error document and suppressing the HTTP error.
# Returns URLGET_RETURNCODE as the return code, in case you were piping the output somewhere

# Set the command to get the desire output concerning the output selection ($2)
if [[ $2 = "stdout" ]]; then
	local LFTP_COM="cat"
	local URL_GOT="-"
	local CURL_OUTPUT=""
elif [[ -n $2 ]]; then
	local LFTP_COM="get1 -o \"$2\""
	local URL_GOT=$2
	local CURL_OUTPUT="-o $2"
else
	local LFTP_COM="get1"
	local URL_GOT=`basename "$1" 2>/dev/null`
	local CURL_OUTPUT="-O"
fi

if [[ -n $LFTP && ( -z $3 || $3 = "passwarning" || $3 = "testonly" || $3 =~ "tryonlylftp" ) ]]; then
	if [[ -n $LFTP ]]; then
		if [[ $DEBUG -ge 1 ]]; then
			ws_event_info "url_get: lftp: $1"
			# We don't put the URL on the command-line in case it contains passwords
			$LFTP $LFTPDEBUG <<-ENDHERE
			set xfer:max-redirections 16
			set ssl:verify-certificate $SSLVERIFY
			$LFTP_COM "$1"
			ENDHERE
		else
			$LFTP $LFTPDEBUG 2>/dev/null <<-ENDHERE
			set xfer:max-redirections 16
			set ssl:verify-certificate $SSLVERIFY
			$LFTP_COM "$1"
			ENDHERE
		fi
		URLGET_RETURNCODE=$?
	else
		URLGET_RETURNCODE=3
	fi
elif [[ -n $CURL && ( -z $3 || $3 = "passwarning" || $3 = "testonly" || $3 =~ "tryonlycurl" ) ]]; then
	if [[ -n $CURL ]]; then
		[[ $DEBUG -ge 1 ]] && ws_event_info "url_get: curl: $1"
		local CURLOPTS="--location"
		local CURL_URL=$1
		local CURLUSER=""
		local CURLRET
		[[ $1 =~ ^s?ftp ]] && CURLOPTS="$CURL_FTPOPTIONS "
		# --location forces curl to follow any Location: headers; otherwise the test may fail (a redirect code comes successfully back, though the site you'd get if you followed it may be down)
		[[ $3 =~ testonly ]] && CURLOPTS="$CURLOPTS --fail"
		if [[ $1 =~ ^(https?|s?ftps?)://([^/]+):([^/]+)\@(.*)$ ]]; then
			CURLUSER="user = \"${BASH_REMATCH[2]}:${BASH_REMATCH[3]}\"
"
			CURL_URL="${BASH_REMATCH[1]}://${BASH_REMATCH[4]}"
			CURLOPTS="$CURLOPTS --config -"
			[[ $1 =~ ^http ]] && CURLOPTS="$CURLOPTS --fail --anyauth --netrc-optional"
		fi
		if [[ $DEBUG -ge 2 ]]; then
			echo
			echo $CURLUSER | $CURL $CURLVERB --show-error $CURLOPTS $CURL_OUTPUT "$CURL_URL"
			CURLRET=$?
		else
			if [[ "$MODE" = "downloadonly" || $DEBUG -eq 1 ]]; then
				echo $CURLUSER | $CURL $CURL_OUTPUT $CURLOPTS -# "$CURL_URL"
				CURLRET=$?
			else
				echo $CURLUSER | $CURL $CURL_OUTPUT $CURLOPTS --silent "$CURL_URL"
				CURLRET=$?
			fi
		fi
		URLGET_RETURNCODE=$CURLRET
	else
		URLGET_RETURNCODE=3
	fi
# We try wget last because it is harder to hide username/passwords in the URL with
elif [[ -n $WGET && ( -z $3 || $3 = "passwarning" || $3 = "testonly" || $3 =~ "tryonlywget" ) ]]; then
	if [[ -n $WGET ]]; then
		local WGET_URL=$1
		if [[ $3 =~ passwarning && $WGET_URL =~ ^(https?|s?ftps?)://([^/]+):([^/]+)\@(.*)$ ]]; then
			check_continue "${BOLD}Warning:${OFFBOLD} Your system does not have lftp or curl installed, so we are using wget to fetch URLs. However, wget has no easy way to hide passwords contained in URLs. This is not a problem unless your system is multi-user; someone then may be able to spot the password in the system's process table (by running the 'ps' command). To avoid this, you should (if you cannot install lftp or curl) add a line to your .netrc file in your home directory (see 'man netrc' for more information on how to do so; a typical line is 'machine www.example.com<tab>login myusername<tab>password mypassword'). After doing that, you can tell WordShell the URL without needing to include a username or password; wget will pick up the username/password automatically without WordShell needing to pass it. Do you want to continue? (c to continue if this does not matter, e.g. you are on a single user system, or if the entry is already in your .netrc; or any other key to abort): "
		fi
		if [[ $DEBUG -ge 1 ]]; then
			ws_event_info "url_get: wget: $1"
			$WGET $WGETVERB -O $URL_GOT "$WGET_URL"
		else
			if [[ $MODE = "downloadonly" ]]; then
				$WGET -O $URL_GOT -nv "$WGET_URL"
			else
				$WGET -O $URL_GOT -q "$WGET_URL"
			fi
		fi
	else
		URLGET_RETURNCODE=3
	fi
else
	ws_event_error "No suitable program to fetch the URL was found"
	URLGET_RETURNCODE=254
fi
return $URLGET_RETURNCODE
}
