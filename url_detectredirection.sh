function url_detectredirection {
	# Input: $1=URI
	# Output: returns 0 if no redirection detected, 1 if found; and if so, sets URL_REDIRECTEDURL

	if [[ -n $CURL ]]; then
		local CURLOPTS=""
		local CURL_URL=$1
		if [[ $1 =~ ^(https?)://([^/]+):([^/]+)\@(.*)$ ]]; then
			CURLUSER="user = \"${BASH_REMATCH[2]}:${BASH_REMATCH[3]}\"
"
			CURL_URL="${BASH_REMATCH[1]}://${BASH_REMATCH[4]}"
			CURLOPTS="$CURLOPTS --config - --fail --anyauth --netrc-optional"
		fi
		local RTMP=`mktemp "$WORKINGDIR_FULL/tmp/URLREDIRECT.XXXXX"`
		echo $CURLUSER | $CURL $CURLVERB --head $CURLOPTS -o $RTMP "$CURL_URL"
		CURLRET=$?
		if [[ $CURLRET -eq 47 ]]; then
			rm -f $RTMP
			# Maximum redirections exceeded - try to find the URL
			return 1
		fi
		rm -f $RTMP
		if [[ $CURLRET -eq 0 ]]; then
			return 0
		else
			[[ $DEBUG -ge 1 ]] && ws_event_info "Curl returned code $CURLRET when trying to detect redirections at $CURL_URL"
			return 0
		fi
	fi

	# TODO - wget / lftp; then use this function in the intended places
	true
	cat <<-ENDHERE

$ wget --max-redirect=0 --spider -S http://www.homeedsuccess.co.uk -q
  HTTP/1.0 301 Moved Permanently
  Location: http://www.homeedsuccess.co.uk/he
  Connection: keep-alive
  Date: Tue, 15 May 2012 10:20:31 GMT
  Server: lighttpd

$ lftp -c "set xfer:max-redirections 0; open http://www.homeedsuccess.co.uk"
cd: File moved: 301 Moved Permanently (/ -> http://www.homeedsuccess.co.uk/he)
Or with -d:
<--- HTTP/1.1 301 Moved Permanently
<--- Location: http://www.homeedsuccess.co.uk/he
<--- Date: Tue, 15 May 2012 10:26:17 GMT
<--- Server: lighttpd
<---
cd: File moved: 301 Moved Permanently (/ -> http://www.homeedsuccess.co.uk/he)

curl --head http://www.homeedsuccess.co.uk
HTTP/1.1 301 Moved Permanently
Location: http://www.homeedsuccess.co.uk/he
Date: Tue, 15 May 2012 10:14:14 GMT
Server: lighttpd
	ENDHERE
}
