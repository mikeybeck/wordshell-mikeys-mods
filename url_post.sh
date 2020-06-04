function url_post() {
	# Input: $1 = URI, $2 = path, $3 = params
	# $4 is options (comma-separated):
	# ignoreexisting: do not use an existing cache file
	# nocache: do not cache the results (implies ignoreexisting)
	# preferwget to prefer wget (or preferlftp to not do so - presently default, but you never know...). Or prefercurl
	# returnfile to return the full file path (not the contents); setvar to put the contents in URLPOST_RESULTS
	# We assume either lftp or wget or curl is available
	# Output: sets RETCODE_URLPOST
	local POST_OPTS=$4
	# This is needed to use STAT_MODTIME correctly (the spaces in it need recognising as parameter separators)
	local OLDIFS=$IFS
	IFS="
"
	if [[ -z $CHECKSUM ]]; then
		# If no checksum binary, then cannot store predictable cache file name, so just use temp file
		REQHASH_FILE=`mktemp "$WORKINGDIR_FULL/tmp/url-post.XXXXX"`
		# Since the temp file name was not predictable, do not cache the file (unless the caller requested it)
		[[ ! $POST_OPTS =~ returnfile ]] && POST_OPTS="$4,nocache"
	else
		REQHASH_FILE="$WORKINGDIR_FULL/tmp/post-`echo $1 $2 $3 | $CHECKSUM | cut -d' ' -f1`"
	fi
	# Do the download if not cacheing, or if told to ignore existing cache, or cache disabled, or no cache file exists, or if cache file is old

	if [[ $POST_OPTS =~ nocache || $POST_OPTS =~ ignoreexisting || $DISABLECACHE -eq 1 || ! -f $REQHASH_FILE || $((NOWDATE - `$STAT_MODTIME $REQHASH_FILE 2>/dev/null|| echo 0`)) -ge 3600 ]]; then

		if [[ ( $POST_OPTS =~ preferwget && -n $WGET ) || ( -z $CURL && -z $LFTP)  ]]; then
			[[ $DEBUG -ge 1 ]] && ws_event_info "url_post: wget_post: options=$4: $1 $2 $3"
			$WGET $WGETVERB --post-data="$3" -O $REQHASH_FILE $1$2
			RETCODE_URLPOST=$?
		elif [[ ( $POST_OPTS =~ prefercurl && -n $CURL ) || -z $LFTP ]]; then
			[[ $DEBUG -ge 1 ]] && ws_event_info "url_post: curl_post: options=$4: $1 $2 $3"
			CURL_URL=$1
			CURLUSER=""
			CURLOPTS=""
			if [[ $1 =~ ^(https?)://([^/]+):([^/]+)\@(.*)$ ]]; then
				CURLUSER="user = \"${BASH_REMATCH[2]}:${BASH_REMATCH[3]}\"
"
				CURL_URL="${BASH_REMATCH[1]}://${BASH_REMATCH[4]}"
				CURLOPTS="$CURLOPTS --config -"
				[[ $1 =~ ^http ]] && CURLOPTS="$CURLOPTS --fail --anyauth --netrc-optional"
			fi
			echo $CURLUSER | $CURL $CURLVERB $CURLOPTS --output $REQHASH_FILE --data "$3" --url "${CURL_URL}$2"
			RETCODE_URLPOST=$?
		else
			[[ $DEBUG -ge 1 ]] && ws_event_info "url_post: lftp_post: options=$4: $1 $2 $3"
# 			if [[ $1 =~ ^(https?)://([^/]+):([^/]+)\@(.*)$ ]]; then
				# Don't put the URL on the command-line, in case it contains passwords
				$LFTP $LFTPDEBUG  >"$REQHASH_FILE" <<-ENDHERE
				set ssl:verify-certificate $SSLVERIFY
				open $1$2
				quote post '$2' '$3'"
				ENDHERE
				RETCODE_URLPOST=$?
# 			else
# 				# http://api.wordpress.org/themes/info/1.0/ returns a 500 error if HEAD is used, as happens with lftp's open command above. So, avoid that if possible by using this method.
# 				$LFTP $LFTPDEBUG "$1" >"$REQHASH_FILE" <<-ENDHERE
# 				quote post '$2' '$3'"
# 				ENDHERE
# 				RETCODE_URLPOST=$?
# 			fi
		fi
		[[ $DEBUG -ge 1 ]] && ws_event_info "url_post: wrote to file: $REQHASH_FILE"
	else
		[[ $DEBUG -ge 1 ]] && ws_event_info "HTTP POST: options=$4: $1 $2 $3: Found valid cache file: $REQHASH_FILE"
	fi
	if [[ $POST_OPTS =~ returnfile ]]; then
		echo $REQHASH_FILE
	elif [[ $POST_OPTS =~ setvar ]]; then
		URLPOST_RESULTS=`cat $REQHASH_FILE`
		rm -f $REQHASH_FILE
	else
		cat $REQHASH_FILE
		[[ $POST_OPTS =~ nocache ]] && rm -f $REQHASH_FILE
	fi
	IFS=$OLDIFS
}
