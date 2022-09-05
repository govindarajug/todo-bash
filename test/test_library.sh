source ./sub_commands.sh
source ./test/tools.sh

TEST_DATA_PATH="./test/test_data"
IFS=$'\n'
ERROR=()
RESULT=( 0 0 )

function test_array_search () {
	local TEST_DATA=( $1 )
	local PATTERN=$2
	local EXPECTED_OUTPUT=$3
	local DESCRIPTION=$4

	local ACTUAL_OUTPUT=( $( array_search "${TEST_DATA[*]}" "$PATTERN" ) )

	local INPUTS="Array : ${TEST_DATA[@]}\n\tPattern : $PATTERN"
	assert "$INPUTS" "`echo ${EXPECTED_OUTPUT[@]}`" "`echo ${ACTUAL_OUTPUT[@]}`" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_array_search () {
	local TEST1_DATA=( $( cat $TEST_DATA_PATH/model2.csv ) )
	local TEST1_DESC="Should give the element matched with the given string"
	test_array_search "${TEST1_DATA[*]}" "Task" "3|1|Task Manager Testing|array,function,tools" "$TEST1_DESC"

	local TEST2_DATA=( "hello" "how are you?" "abc123" "good_bye" )
	local TEST2_DESC="Should give the element matched with the given pattern"
	test_array_search "${TEST2_DATA[*]}" "^[a-z].*[0-9]$" "abc123" "$TEST2_DESC"
}

function test_read_file_data () {
	local FILE=$1
	local EXPECTED_OUTPUT=( $2 )
	local DESCRIPTION=$3

	local ACTUAL_OUTPUT=( $( read_file_data $FILE ) )

	local INPUTS="File : ${FILE}"
	assert "$INPUTS" "${EXPECTED_OUTPUT[*]}" "${ACTUAL_OUTPUT[*]}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_read_file_data () {
	local EXPECTED_OUTPUT=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )
	local TEST_DESC="Should read file, then store and return it back as an array"
	test_read_file_data "$TEST_DATA_PATH/model2.csv" "${EXPECTED_OUTPUT[*]}" "$TEST_DESC"
}

function test_write_file_data () {
	local TEST_DATA=( $1 )
	local FILE_TO_WRITE=$2
	local EXPECTED_OUTPUT_FILE=$3
	local DESCRIPTION=$4

	write_file_data "${TEST_DATA[*]}" "$FILE_TO_WRITE"
	local ACTUAL_OUTPUT_FILE=$FILE_TO_WRITE

	local INPUTS="Test data : ${TEST_DATA[*]}, File : ${FILE_TO_WRITE}"
	assert_file "$INPUTS" "$EXPECTED_OUTPUT_FILE" "$ACTUAL_OUTPUT_FILE" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_write_file_data () {
	local TEST1_DATA=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )
	local TEST1_SPACE="${TEST_DATA_PATH}/task_table.csv"
	local EXPECTED_OUTPUT_FILE="$TEST_DATA_PATH/model2.csv"
	local TEST1_DESC="Should write the data of given array in the given file"
	test_write_file_data "${TEST1_DATA[*]}" "$TEST1_SPACE" "$EXPECTED_OUTPUT_FILE" "$TEST1_DESC"

	local TEST2_DATA=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )
	local TEST2_SPACE="${TEST_DATA_PATH}/hello/task_table.csv"
	local TEST2_DESC="Should return 1 when the path is invalid"
	test_write_file_data "${TEST2_DATA[*]}" "$TEST2_SPACE" "" "$TEST2_DESC"
}

function test_filter_by_tags () {
	local TEST_DATA=( $1 )
	local TAGS=$2
	local EXPECTED_OUTPUT=( $3 )
	local DESCRIPTION=$4

	local ACTUAL_OUTPUT=$( filter_by_tags "${TEST_DATA[*]}" "$TAGS" )
	local INPUTS="TASK DATA : ${TEST_DATA[*]}, Tags : ${TAGS}"
	assert "$INPUTS" "${EXPECTED_OUTPUT[*]}" "${ACTUAL_OUTPUT[*]}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_filter_by_tags () {
	local TEST_DATA=( $(cat "${TEST_DATA_PATH}/model2.csv" ) )

	local TEST1_DESC="Should filter out tasks based on the given single tag"
	local TEST1_EXPECTED_OUTPUT=( "3|1|Task Manager Testing|array,function,tools" )
	test_filter_by_tags "${TEST_DATA[*]}" "tags:array" "${TEST1_EXPECTED_OUTPUT[*]}" "$TEST1_DESC"

	local TEST2_DATA=( $(cat "${TEST_DATA_PATH}/model3.csv" ) )
	local TEST2_DESC="Should filter out tasks when multiple tags given"
	local TEST2_EXPECTED_OUTPUT=( "4|0|music|jazz,pop,retro" "6|1|singing|classic,pop,retro" )
	test_filter_by_tags "${TEST2_DATA[*]}" "tags:retro,pop" "${TEST2_EXPECTED_OUTPUT[*]}" "$TEST2_DESC"

	local TEST3_DESC="Should return back all tasks when there is no tags given"
	local TEST3_EXPECTED_OUTPUT=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )
	test_filter_by_tags "${TEST_DATA[*]}" "" "${TEST3_EXPECTED_OUTPUT[*]}" "$TEST3_DESC"
}

function test_add_task () {
	local TASK_DATA=( $1 )
	local TASK="$2"
	local TAGS=$3
	local EXPECTED_OUTPUT=( $4 )
	local DESCRIPTION="$5"
	local ACTUAL_OUTPUT=( $( add_task "${TASK_DATA[*]}" "$TASK" "$TAGS" ) )

	local INPUTS="Task : ${TASK}, Tags : ${TAGS}, Task data : ${TASK_DATA[*]}"
	assert "$INPUTS" "${EXPECTED_OUTPUT[*]}" "${ACTUAL_OUTPUT[*]}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_add_task () {
	local TEST1_DESC="Starting task ID should be 1"
	local TEST1_DATA=( "0" )
	local TEST1_EXPECTED_OUTPUT=( "1" "1|0|coding|bash" )
	test_add_task "${TEST1_DATA[*]}" "coding" "tags:bash" "${TEST1_EXPECTED_OUTPUT[*]}" "$TEST1_DESC"

	local TEST2_DESC="ID should increment by 1 each time if it already have some tasks"
	local TEST2_DATA=( "2" "1|0|sleep" "2|0|coding" )
	local TEST2_EXPECTED_OUTPUT=( "3" "1|0|sleep" "2|0|coding" "3|0|read books|comics,fantasy" )
	test_add_task "${TEST2_DATA[*]}" "read books" "tags:fantasy,comics" "${TEST2_EXPECTED_OUTPUT[*]}" "$TEST2_DESC"

	local TEST3_DESC="Should add empty tags if no tags passed as argument"
	local TEST3_DATA=( "3" "1|0|sleep|everyday" "2|0|coding|bash,terminal" "3|0|read books|comics,fantasy" )
	local TEST3_EXPECTED_OUTPUT=( "4" "1|0|sleep|everyday" "2|0|coding|bash,terminal" "3|0|read books|comics,fantasy" "4|0|testing code|" )
	test_add_task "${TEST3_DATA[*]}" "testing code" "" "${TEST3_EXPECTED_OUTPUT[*]}" "$TEST3_DESC"
}

function test_update_new_task () {
	local TASK_DATA=( $1 )
	local TASK="$2"
	local TAGS=$3
	local FILE_PATH=$4
	local EXPECTED_OUTPUT=$5
	local DESCRIPTION="$6"
	local ACTUAL_OUTPUT=$( update_new_task "${TASK_DATA[*]}" "$TASK" "$TAGS" "$FILE_PATH" )

	local INPUTS="Task : ${TASK}, Tags : ${TAGS}, Task data : ${TASK_DATA[*]}"
	assert "$INPUTS" "${EXPECTED_OUTPUT}" "${ACTUAL_OUTPUT}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT

}

function test_cases_update_new_task () {
	local TEST_DATA=( "2" "1|0|sleep" "2|0|coding" )

	local TEST1_DESC="Should display the information about the new task added"
	test_update_new_task "${TEST_DATA[*]}" "testing" "tags:bash" "$TEST_DATA_PATH/task_table.csv" "Created task 3" "${TEST1_DESC}"

	local TEST2_DESC="Should display the error message when task is empty"
	test_update_new_task "${TEST_DATA[*]}" "" "" "$TEST_DATA_PATH/task_table.csv" "Invalid task" "${TEST2_DESC}"

	local TEST3_DESC="Shouldn't update file if the filepath is wrong"
	test_update_new_task "${TEST_DATA[*]}" "sleeping" "tags:night,deep" "$TEST_DATA_PATH/hi/task_table.csv" "" "${TEST3_DESC}"
}

function test_help () {
	local DESCRIPTION="Should print the usage of all sub-commands"
	help > ${TEST_DATA_PATH}/help_act.txt

	assert_file "" "${TEST_DATA_PATH}/help_exp.txt" "${TEST_DATA_PATH}/help_act.txt" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_list () {
	local TEST_DATA=( $1 )
	local EXPECTED_OUTPUT_FILE=$2
	local DESCRIPTION=$3

	local ACTUAL_OUTPUT_FILE="${TEST_DATA_PATH}/output.txt"
	list "${TEST_DATA[*]}" > $ACTUAL_OUTPUT_FILE
	local INPUTS="TASK DATA : ${TEST_DATA[*]}"
	assert_file "$INPUTS" "$EXPECTED_OUTPUT_FILE" "$ACTUAL_OUTPUT_FILE" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_list () {
	local TEST1_DESC="Should list undone tasks only"
	local TEST1_DATA=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )
	test_list "${TEST1_DATA[*]}" "$TEST_DATA_PATH/list1_exp.txt" "$TEST1_DESC"
}

function test_longlist () {
	local TEST_DATA=( $1 )
	local TAGS=$2
	local EXPECTED_OUTPUT_FILE=$3
	local DESCRIPTION=$4

	local ACTUAL_OUTPUT_FILE="${TEST_DATA_PATH}/output.txt"
	longlist "${TEST_DATA[*]}" "$TAGS" > $ACTUAL_OUTPUT_FILE
#	local IFS=$' \t\n'
	local INPUTS="TASK DATA : ${TEST_DATA[@]}"
#	echo "$INPUTS"
#	local IFS=$'\n'
	assert_file "$INPUTS" "$EXPECTED_OUTPUT_FILE" "$ACTUAL_OUTPUT_FILE" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_longlist () {
	local TEST1_DATA=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )
	local TEST1_DESC="Should list all tasks with status when no tags given"
	test_longlist "${TEST1_DATA[*]}" "" "$TEST_DATA_PATH/longlist1_exp.txt" "$TEST1_DESC"

	local TEST2_DATA=( $( cat "${TEST_DATA_PATH}/model3.csv" ) )
	local TEST2_DESC="Should list all tasks with status that matched with tags given"
	test_longlist "${TEST2_DATA[*]}" "tags:retro,pop" "$TEST_DATA_PATH/longlist2_exp.txt" "$TEST2_DESC"
}

function test_mark_as_done() {
	local TEST_DATA=( $1 )
	local ID=$2
	local EXPECTED_OUTPUT=( $3 )
	local DESCRIPTION=$4

	local ACTUAL_OUTPUT=( $( mark_as_done "${TEST_DATA[*]}" "$ID" ) )

	local INPUTS="TASK DATA : ${TEST_DATA[@]}, ID : ${ID}"
	assert "$INPUTS" "${EXPECTED_OUTPUT[*]}" "${ACTUAL_OUTPUT[*]}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_mark_as_done () {
	local TEST_DATA=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )

	local TEST1_DESC="Should mark the status of given id as done"
	local TEST1_EXPECTED=( "4" "1|1|Play Games|cricket" "2|1|coding|" "3|1|Task Manager Testing|array,function,tools" "4|0|music|" )
	test_mark_as_done "${TEST_DATA[*]}" "1" "${TEST1_EXPECTED[*]}" "$TEST1_DESC"

	local TEST2_DESC="Shouldn't mark the status of given id as done when the task is already done"
	local TEST2_EXPECTED=( "4" "1|0|Play Games|cricket" "2|1|coding|" "3|1|Task Manager Testing|array,function,tools" "4|0|music|" )
	test_mark_as_done "${TEST_DATA[*]}" "2" "${TEST2_EXPECTED[*]}" "$TEST2_DESC"

	local TEST3_DESC="Shouldn't mark the status of given id as done when ID doesn't exist"
	local TEST3_EXPECTED=( "4" "1|0|Play Games|cricket" "2|1|coding|" "3|1|Task Manager Testing|array,function,tools" "4|0|music|" )
	test_mark_as_done "${TEST_DATA[*]}" "10" "${TEST3_EXPECTED[*]}" "$TEST3_DESC"
}

function test_update_done_task () {
	local TEST_DATA=( $1 )
	local ID=$2
	local FILE_PATH=$3
	local EXPECTED_OUTPUT=$4
	local DESCRIPTION=$5

	local ACTUAL_OUTPUT=$( update_done_task "${TEST_DATA[*]}" "$ID" "${FILE_PATH}" )

	local IFS=$' \t\n'
	local INPUTS="Task Data - ${TEST_DATA[@]};ID - ${ID};File Path - ${FILE_PATH}"
	local IFS=$'\n'
	assert "$INPUTS" "${EXPECTED_OUTPUT}" "${ACTUAL_OUTPUT}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_update_done_task () {
	local TEST_DATA=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )

	local TEST1_DESC="Should display the information about the task that marked as done"
	test_update_done_task "${TEST_DATA[*]}" "4" "${TEST_DATA_PATH}/task_table.csv" "Marked task 4 music as done" "$TEST1_DESC"

	local TEST2_DESC="Should display Invalid ID when ID is not an integer"
	test_update_done_task "${TEST_DATA[*]}" "1a" "${TEST_DATA_PATH}/task_table.csv" "Invalid ID" "$TEST2_DESC"

	local TEST3_DESC="Should display already marked as done for previously done tasks"
	test_update_done_task "${TEST_DATA[*]}" "2" "${TEST_DATA_PATH}/task_table.csv" "Task 2 already marked as done" "$TEST3_DESC"

	local TEST4_DESC="Should display ID doesn't exist for IDs that doesn't exist"
	test_update_done_task "${TEST_DATA[*]}" "10" "${TEST_DATA_PATH}/task_table.csv" "ID doesn't exist, try task list" "$TEST4_DESC"
}

function test_delete_task () {
	local TEST_DATA=( $1 )
	local ID=$2
	local EXPECTED_OUTPUT=( $3 )
	local DESCRIPTION=$4

	local ACTUAL_OUTPUT=( $( delete_task "${TEST_DATA[*]}" "$ID" ) )

	local INPUTS="TASK DATA : ${TEST_DATA[*]}, ID : ${ID}"
	assert "$INPUTS" "${EXPECTED_OUTPUT[*]}" "${ACTUAL_OUTPUT[*]}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_delete_task () {
	local TEST_DATA=( $( cat $TEST_DATA_PATH/model2.csv ) )

	local TEST1_EXPECTED=( "4" "1|0|Play Games|cricket" "2|1|coding|" "3|1|Task Manager Testing|array,function,tools" )
	local TEST1_DESC="Should delete the given ID and it's data"
	test_delete_task "${TEST_DATA[*]}" "4" "${TEST1_EXPECTED[*]}" "$TEST1_DESC"

	local TEST2_EXPECTED=( "4" "1|0|Play Games|cricket" "2|1|coding|" "3|1|Task Manager Testing|array,function,tools" "4|0|music|" )
	local TEST2_DESC="Shouldn't delete when the ID is invalid"
	test_delete_task "${TEST_DATA[*]}" "10" "${TEST2_EXPECTED[*]}" "$TEST2_DESC"
}

function test_update_deleted_task () {
	local TEST_DATA=( $1 )
	local ID=$2
	local FILE_PATH=$3
	local EXPECTED_OUTPUT=$4
	local DESCRIPTION=$5

	local ACTUAL_OUTPUT=$( update_deleted_task "${TEST_DATA[*]}" "$ID" "${FILE_PATH}" )

	local INPUTS="Task Data : ${TEST_DATA[@]}, ID : ${ID}, File Path : ${FILE_PATH}"
	assert "$INPUTS" "${EXPECTED_OUTPUT}" "${ACTUAL_OUTPUT}" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_update_deleted_task () {
	local TEST_DATA=( $( cat "${TEST_DATA_PATH}/model2.csv" ) )

	local TEST1_DESC="Should display the information about the task deleted"
	test_update_deleted_task "${TEST_DATA[*]}" "4" "${TEST_DATA_PATH}/task_table.csv" "Deleted task 4 music" "$TEST1_DESC"

	local TEST2_DESC="Should display Invalid ID when ID is not an integer"
	test_update_deleted_task "${TEST_DATA[*]}" "1a" "${TEST_DATA_PATH}/task_table.csv" "Invalid ID" "$TEST2_DESC"

	local TEST3_DESC="Should display ID doesn't exist for IDs that doesn't exist"
	test_update_deleted_task "${TEST_DATA[*]}" "10" "${TEST_DATA_PATH}/task_table.csv" "ID doesn't exist, try task list" "$TEST3_DESC"

	local TEST4_DESC="Should not write to file when something related to 'write_file_data' is wrong"
	test_update_deleted_task "${TEST_DATA[*]}" "2" "${TEST_DATA_PATH}/hi/task_table.csv" "" "$TEST4_DESC"
}

function test_view_task () {
	local TEST_DATA=( $1 )
	local ID=$2
	local EXPECTED_OUTPUT=$3
	local DESCRIPTION=$4

	local ACTUAL_OUTPUT=$( view_task "${TEST_DATA[*]}" "$ID" )

	local INPUTS="TASK DATA : ${TEST_DATA[*]}, ID : ${ID}"
	assert "$INPUTS" "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT" "$DESCRIPTION"
	local TEST_RESULT=$?
	update_result $TEST_RESULT
}

function test_cases_view_task () {
	local TEST_DATA=( $( cat "$TEST_DATA_PATH/model3.csv" ) )

	local TEST1_DESC="Should display all the details of given ID"
	local TEST1_EXPECTED_OUTPUT=$( cat ${TEST_DATA_PATH}/view1_exp.txt )
	test_view_task "${TEST_DATA[*]}" "3" "$TEST1_EXPECTED_OUTPUT" "$TEST1_DESC"

	local TEST2_DESC="Should display error when given ID format is invalid"
	local TEST2_EXPECTED_OUTPUT="Invalid ID"
	test_view_task "${TEST_DATA[*]}" "3a" "$TEST2_EXPECTED_OUTPUT" "$TEST2_DESC"

	local TEST3_DESC="Should display error when given ID doesn't exist"
	local TEST3_EXPECTED_OUTPUT="ID not found, try task list"
	test_view_task "${TEST_DATA[*]}" "10" "$TEST3_EXPECTED_OUTPUT" "$TEST3_DESC"
}

function test_main () {
	local MODEL_DATA_FILE=$1
	local SUB_CMD=$2
	local TASK="$3"
	local TAGS="$4"
	local EXPECTED_OUTPUT="$5"
	local DESCRIPTION="$6"
	local TEST_DATA_FILE="${TEST_DATA_PATH}/task_table.csv"

	[[ -e $MODEL_DATA_FILE ]] && cp $MODEL_DATA_FILE $TEST_DATA_FILE
	local ACTUAL_OUTPUT=$( main "$TEST_DATA_PATH" "$SUB_CMD" "$TASK" "$TAGS" )
	local INPUTS="Sub-command : ${SUB_CMD}, Task : ${TASK}, Task table : ${TEST_DATA_FILE}"
	assert "${INPUTS}" "${EXPECTED_OUTPUT}" "${ACTUAL_OUTPUT}" "${DESCRIPTION}"
	local test_result=$?
	update_result $test_result
}

function test_cases_main () {
	# function "model data file" "sub-cmd" "arg1" "arg2" "exp" "desc"
	test_main "$TEST_DATA_PATH/model2.csv" "add" "singing" "tags:pop" "Created task 5" "Should add task and display ID"
	test_main "$TEST_DATA_PATH/model2.csv" "help" "" "" "`cat $TEST_DATA_PATH/help_exp.txt`" "Should print the usage of all sub-cmds"
	test_main "$TEST_DATA_PATH/model2.csv" "list" "" "" "`cat $TEST_DATA_PATH/list1_exp.txt`" "Should list all undone tasks"
	test_main "$TEST_DATA_PATH/model3.csv" "longlist" "tags:pop,retro" "" "`cat $TEST_DATA_PATH/longlist2_exp.txt`" "Should longlist all tasks matched with tags"
	test_main "$TEST_DATA_PATH/model2.csv" "done" "4" "" "Marked task 4 music as done" "Should mark given task ID as done"
	test_main "$TEST_DATA_PATH/model2.csv" "delete" "1" "" "Deleted task 1 Play Games" "Should delete the given ID and data"
	test_main "$TEST_DATA_PATH/model3.csv" "view" "3" "" "$( cat ${TEST_DATA_PATH}/view1_exp.txt )" "Should display details of the given ID"
	test_main "$TEST_DATA_PATH/model2.csv" "abcd" "" "" "`cat $TEST_DATA_PATH/invalid_cmd_exp.txt`" "Should print the usage of all sub-commands when the sub-command is invalid"
}

function all_tests () {
	header "array_search"
	test_cases_array_search

	header "\nread_file_data"
	test_cases_read_file_data

	header "\nwrite_file_data"
	test_cases_write_file_data

	header "\nfilter_by_tags"
    test_cases_filter_by_tags

	header "\nadd_task"
	test_cases_add_task

	header "\nupdate_new_task"
	test_cases_update_new_task

	header "\nhelp"
	test_help

	header "\nlist"
	test_cases_list

	header "\nlonglist"
	test_cases_longlist

	header "\nmark_as_done"
	test_cases_mark_as_done

	header "\nupdate_done_task"
	test_cases_update_done_task

	header "\ndelete_task"
	test_cases_delete_task

	header "\nupdate_deleted_task"
	test_cases_update_deleted_task

	header "\nview_task"
    test_cases_view_task

	header "\nmain"
	test_cases_main

	display_tests_summary "${RESULT[@]}"
	echo -e "\tTotal count 42\n"
}

all_tests
