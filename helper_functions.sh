function array_search () {
	local TASK_DATA=( $1 )
	local PATTERN=$2
	local TASK=$( echo "${TASK_DATA[*]}" | grep "${PATTERN}" )
	echo $TASK
}

function read_file_data () { # validate input
	local FILE_PATH=$1
	local DATA=( $( cat $FILE_PATH ) )
	echo "${DATA[*]}"
}

function write_file_data () {
	local DATA=( $1 )
	local FILE_PATH=$2
	( echo "${DATA[*]}" > $FILE_PATH ) 2> /dev/null || return 1
}

function filter_by_tags () {
	local TASK_DATA=( $1 )
	local TAGS=$2
	local FILTERED_TASK_DATA=( ${TASK_DATA[*]} )

	TAGS=( $( echo $TAGS | cut -d":" -f2 | tr "," "\n" ) )
	for TAG in `echo "${TAGS[*]}"`; do
		FILTERED_TASK_DATA=( $( echo "${FILTERED_TASK_DATA[*]}" | grep "\([,|]${TAG},.*\|[,|]${TAG}\)$" ) )		# matching tags as a word in last field
	done
	echo "${FILTERED_TASK_DATA[*]}"
}
