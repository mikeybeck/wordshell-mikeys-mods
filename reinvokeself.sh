function reinvokeself() {
	# Purpose - re-invoke self, replacing any instances of --everything or --pluginsandthemes with another
	# $1 : Replacement parameter
	local LINE
	for i in $ORIGINAL_PARAMS; do
		if [[ $i = "--everything" || $i = "-e" || $i = "--pluginsandthemes" ]]; then
			LINE="$LINE $1"
		elif [[ ( $i != "--selfinvoked" && $i != "--selfinvoked=e" ) && $i != "--nocountdiskspace" && $i != "--groupbytype" && ( ( $1 != "--plugin" && $1 != "--theme" && $1 != "--content" && $1 != "--database" ) || ( $i != "--justwp" && $i != "--justwpwipeothers" ) ) ]]; then
			LINE="$LINE $i"
		fi
	done
	ws_pushd "$ORIGDIR"
	[[ $METAMODE = "everything" ]] && $BASH $0 $LINE --selfinvoked=e --nocountdiskspace
	[[ $METAMODE != "everything" ]] && $BASH $0 $LINE --selfinvoked --nocountdiskspace
	ws_popd
}
