function ws_event_error() {
	# "Non-urgent failures, these should be relayed to developers or admins; each item must be resolved within a given time."
	ws_logger ERROR "$1"
}

function ws_event_warning() {
	# "Warning messages, not an error, but indication that an error will occur if action is not taken, e.g. file system 85% full - each item must be resolved within a given time."
	ws_logger WARNING "$1"
}

function ws_event_notice() {
	# "Events that are unusual but not error conditions - might be summarized in an email to developers or admins to spot potential problems - no immediate action required."
	ws_logger NOTICE "$1"
}

function ws_event_info() {
	# "Normal operational messages - may be harvested for reporting, measuring throughput, etc. - no action required."
	# If $2 is 1, then also echo to the screen
	[[ $2 = "1" ]] && echo "$1"
	ws_logger INFO "$1"
}

function ws_event_debug() {
	# "Info useful to developers for debugging the application, not useful during operations."
	ws_logger DEBUG "$1"
}
