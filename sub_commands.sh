BOLD='\033[1m'
NORMAL='\033[0m'
IFS=$'\n'
source ./helper_functions.sh

function add_task () {
	local TASK_DATA=( $1 )
	local TASK="$2"
	local TAGS="$3"
	local LAST_ID=${TASK_DATA[0]}
	local LATEST_ID=$(( $LAST_ID + 1 ))

	TAGS=( $( echo $TAGS | cut -d":" -f2 | tr "," "\n" | sort ) )
	TAGS=$( echo "${TAGS[@]}" | tr " " "," )

	TASK_DATA[0]=$LATEST_ID
	TASK_DATA=( ${TASK_DATA[*]} "${LATEST_ID}|0|${TASK}|${TAGS}" )
	echo "${TASK_DATA[*]}"
	return 0
}

function update_new_task () {
	local TASK_DATA=( $1 )
	local TASK="$2"
	local TAGS="$3"
	local FILE_PATH=$4
	local UPDATED_TASK_DATA

	[[ -z $TASK ]] && echo "Invalid task" && return 1
	UPDATED_TASK_DATA=( $( add_task "${TASK_DATA[*]}" "$TASK" "$TAGS" ) ) || return 2
	write_file_data "${UPDATED_TASK_DATA[*]}" "$FILE_PATH" || return 3
	local LATEST_ID=${UPDATED_TASK_DATA[0]}

	echo "Created task ${LATEST_ID}"
	return 0
}

function help () {
	echo -e "${BOLD}task add <description> ${NORMAL}for adding a task"
	echo -e "${BOLD}task list ${NORMAL}for listing all tasks"
	echo -e "${BOLD}task done <id> ${NORMAL}for marking a task as done"
	echo -e "${BOLD}task delete <id> ${NORMAL}for deleting a task"
	echo -e "${BOLD}task longlist ${NORMAL}for listing all tasks with status"
	echo -e "${BOLD}task help ${NORMAL}for showing this help"
}

function list () {
	local TASK_DATA=( $1 )

	# modifying data to give output
	local UNDONE_TASK_DATA=( $( echo "${TASK_DATA[*]}" | grep "|0|" | cut -d"|" -f1,3,4 ) )					# cutting id,task,tags from data
	UNDONE_TASK_DATA=( $( echo "${UNDONE_TASK_DATA[*]}" | sed "s;^\(.*\)|\(.*\)|\(.*\)$;\1.|\2|[\3];" ) )	# enclosing tags by '[' and ']'
	UNDONE_TASK_DATA=( $( echo "${UNDONE_TASK_DATA[*]}" | sed "s/,/ /g" ) )									# changing , to space in tags

	# adding all data which needs to be displayed in an array and displaying them
	local OUTPUT[0]="id|description|tags"
	OUTPUT[1]="--|---------------|--------------"
	OUTPUT=( "${OUTPUT[*]}" "${UNDONE_TASK_DATA[*]}" )
	echo "${OUTPUT[*]}" | column -t -s"|"
}

function longlist () {
	local TASK_DATA=( $1 )
	local TAGS=$2
	local FORMATED_TASK_DATA
	local DONE="✔"
	local UNDONE="⌛"

	TASK_DATA=( $( filter_by_tags "${TASK_DATA[*]:1}" "$TAGS" ) )
	# modifying data to give output
	FORMATED_TASK_DATA=( $( echo "${TASK_DATA[*]}" | sed "s;^\(.*\)|\(.*\)|\(.*\)|\(.*\)$;\1.|\2|\3|[\4];" ) )	# enclosing tags by '[' and ']'
	FORMATED_TASK_DATA=( $( echo "${FORMATED_TASK_DATA[*]}" | sed "s/|0|/|${UNDONE}|/" ) )							# changing to emoji
	FORMATED_TASK_DATA=( $( echo "${FORMATED_TASK_DATA[*]}" | sed "s/|1|/|${DONE}|/" ) )							# changing to emoji
	FORMATED_TASK_DATA=( $( echo "${FORMATED_TASK_DATA[*]}" | sed "s/,/ /g" ) )										# changing , to space in tags

	# adding all data which needs to be displayed in an array and displaying them
	local OUTPUT[0]="id|status|description|tags"
	OUTPUT[1]="--|------|---------------|--------------"
	OUTPUT=( "${OUTPUT[*]}" "${FORMATED_TASK_DATA[*]}" )
	echo "${OUTPUT[*]}" | column -t -s"|"
}

function mark_as_done () {
	local TASK_DATA=( $1 )
	local ID=$2
	local RETURN_STATUS=0

	local TASK=$( array_search "${TASK_DATA[*]}" "^${ID}|.*" )
	if [[ -z $TASK ]] ; then
		RETURN_STATUS=2
	elif echo $TASK | grep -q "|1|" ; then
		RETURN_STATUS=1
	else
		TASK_DATA=( $( echo "${TASK_DATA[*]}" | sed "/^${ID}|.*$/ s/|0|/|1|/" ) )
	fi

	echo "${TASK_DATA[*]}"
	return $RETURN_STATUS
}

function update_done_task () {
	local TASK_DATA=( $1 )
	local ID=$2
	local FILE_PATH=$3
	local RETURN_STATUS

	# validation of input
	[[ -z $ID ]] || ! ( echo $ID | grep -q "^[0-9]\+$" ) && echo "Invalid ID" && return 1

	UPDATED_TASK_DATA=( $( mark_as_done "${TASK_DATA[*]}" "$ID" ) )
	RETURN_STATUS=$?
	if [[ $RETURN_STATUS == 0 ]]
	then
		write_file_data "${UPDATED_TASK_DATA[*]}" "$FILE_PATH" || return 2
		local TASK=$( array_search "${TASK_DATA[*]}" "^${ID}|.*" | cut -d"|" -f3 )
		echo "Marked task ${ID} ${TASK} as done"
	elif [[ $RETURN_STATUS == 1 ]]
	then
		echo "Task ${ID} already marked as done"
	else
		echo "ID doesn't exist, try task list"
	fi
	return $RETURN_STATUS
}

function delete_task () {
	local TASK_DATA=( $1 )
	local ID=$2

	local TASK=$( array_search "${TASK_DATA[*]}" "^${ID}|.*" )
	if [[ -z $TASK ]]
	then
		echo "${TASK_DATA[*]}"
		return 1
	fi
	TASK_DATA=( $( echo "${TASK_DATA[*]}" | grep -v "^$ID|.*" ) )
	echo "${TASK_DATA[*]}"
}

function update_deleted_task () {
	local TASK_DATA=( $1 )
	local ID=$2
	local FILE_PATH=$3
	local RETURN_STATUS

	# validation of input
	[[ -z $ID ]] || ! ( echo $ID | grep -q "^[0-9]\+$" ) && echo "Invalid ID" && return 1

	UPDATED_TASK_DATA=( $( delete_task "${TASK_DATA[*]}" "$ID" ) )
	RETURN_STATUS=$?
	if [[ $RETURN_STATUS == 0 ]]
	then
		write_file_data "${UPDATED_TASK_DATA[*]}" "$FILE_PATH" || return 2
		local TASK=$( array_search "${TASK_DATA[*]}" "^${ID}|.*" | cut -d"|" -f3 )
		echo "Deleted task ${ID} ${TASK}"
	else
		echo "ID doesn't exist, try task list"
	fi
	return $RETURN_STATUS
}

function view_task () {
	local TASK_DATA=( $1 )
	local ID=$2
	local DONE="✔"
	local UNDONE="⌛"

	# validation of input
	[[ -z $ID ]] || ! ( echo $ID | grep -q "^[0-9]\+$" ) && echo "Invalid ID" && return 1

	local TASK=$( array_search "${TASK_DATA[*]}" "^${ID}|.*" )
	[[ -z $TASK ]] && echo "ID not found, try task list" && return 1

	local STATUS=$( echo $TASK | cut -d"|" -f2 | tr "10" "${DONE}${UNDONE}" )
	local TASK_DESC=$( echo $TASK | cut -d"|" -f3 )
	local TAGS=$( echo $TASK | cut -d"|" -f4 | tr "," " " )

	echo -e "id:|${ID}\nstatus:|${STATUS}\ndescription:|${TASK_DESC}\ntags:|[${TAGS}]" | column -t -s"|"
}

function main () {
	local DATA_DIR="$1"
	local SUB_CMD=$2
	local ARGUMENTS=( "$3" "$4" ) # chng name
	local SUB_CMD_STATUS=1

	# validating the data file and reading data from file
	local TASK_TABLE_FILE="${DATA_DIR}/task_table.csv"
	[[ ! -e $TASK_TABLE_FILE ]] && echo 0 > $TASK_TABLE_FILE
	local TASK_DATA=( $( read_file_data $TASK_TABLE_FILE ) )

	if [[ $SUB_CMD == "add" ]]; then
		update_new_task "${TASK_DATA[*]}" "${ARGUMENTS[0]}" "${ARGUMENTS[1]}" "$TASK_TABLE_FILE"
	elif [[ $SUB_CMD == "help" ]]; then
		help
	elif [[ $SUB_CMD == "list" ]]; then
		list "${TASK_DATA[*]}"
	elif [[ $SUB_CMD == "longlist" ]]; then
		longlist "${TASK_DATA[*]}" "${ARGUMENTS}"
	elif [[ $SUB_CMD == "done" ]]; then
		update_done_task "${TASK_DATA[*]}" "${ARGUMENTS[0]}" "$TASK_TABLE_FILE"
	elif [[ $SUB_CMD == "delete" ]]; then
		update_deleted_task "${TASK_DATA[*]}" "${ARGUMENTS[0]}" "$TASK_TABLE_FILE"
	elif [[ $SUB_CMD == "view" ]]; then
		view_task "${TASK_DATA[*]}" "${ARGUMENTS[0]}"
	else
		echo -e "Task: Invalid sub-command\n"
		help
	fi
}
