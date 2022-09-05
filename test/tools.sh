#! /bin/bash

NOCOLOR='\033[0m'
RED='\033[0;31m'
LIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NORMAL='\033[0m'

function update_result () {
	local TEST_STATUS=$1
	if [[ $TEST_STATUS -eq 0 ]]
	then
		RESULT[0]=$(( ${RESULT[0]} + 1 ))
	else
		RESULT[1]=$(( ${RESULT[1]} + 1 ))
	fi
}

function header(){
	local TEXT=$1

	echo -e "${BOLD}${TEXT}${NORMAL}"
}

function display_tests_summary () {
	local IFS=$'\n'
	local RESULT=( "$@" )

	echo -en "\n\t${GREEN}PASS : ${RESULT[0]}${NOCOLOR}"
	echo -e "\t${RED}FAIL : ${RESULT[1]}${NOCOLOR}\n"

	[[ -z "${ERROR[*]}" ]] && return 0
	local INDEX=0
	local LENGTH=${#ERROR[*]}
	while [[ $INDEX -lt $LENGTH ]]; do
		local ERROR_DETAILS=( ${ERROR[$INDEX]} )
		echo ${#ERROR_DETAILS[*]}
		local FORMATTED_INPUTS=$( echo ${ERROR_DETAILS[1]} | sed "s/;/\n\t/g" )

		echo -e "$(( $INDEX + 1 )).${LIGHT_RED}"
		echo -e "DESCRIPTION ${LIGHT_RED}:\n\t${ERROR_DETAILS[0]}\n"
		echo -e "INPUTS :\n\t${FORMATTED_INPUTS}\n"
		echo -e "EXPECTED :\n\t${ERROR_DETAILS[2]}\n"
		echo -e "ACTUAL :\n\t${ERROR_DETAILS[3]}\n${NOCOLOR}"
		echo -en "\n"

		INDEX=$(( $INDEX + 1 ))
	done
}

function assert () {
	local IFS=$'\n'
	local INPUTS=$1
	local EXPECTED=$2
	local ACTUAL=$3
	local DESCRIPTION=$4
	local TEST_RESULT="${RED}✗${NOCOLOR}"
	local RETURN_STATUS=1

	if [[ "${ACTUAL}" == "${EXPECTED}" ]]
	then
		TEST_RESULT="${GREEN}✔${NOCOLOR}"
		RETURN_STATUS=0
	fi

	if [[ $RETURN_STATUS == 1 ]]; then
		local ERROR_DETAILS=( "${DESCRIPTION}" "${INPUTS}" "${EXPECTED}" "${ACTUAL}" )
		local LENGTH=${#ERROR[*]}
		ERROR[$LENGTH]="${ERROR_DETAILS[*]}"
		DESCRIPTION="${RED}${DESCRIPTION}${NOCOLOR}"
	fi
	echo -e "$TEST_RESULT ${DESCRIPTION}"

	return $RETURN_STATUS
}

function assert_file () {
	local IFS=$'\n'
	local INPUTS=$1
	local EXPECTED_FILE_PATH=$2
	local ACTUAL_FILE_PATH=$3
	local DESCRIPTION=$4
	local TEST_RESULT="${RED}✗${NOCOLOR}"
	local RETURN_STATUS=1

	local EXPECTED_CONTENT=( $( [[ -f $EXPECTED_FILE_PATH ]] && cat $EXPECTED_FILE_PATH || echo "Error : no such file" ) )
	local ACTUAL_CONTENT=( $( [[ -f $ACTUAL_FILE_PATH ]] && cat $ACTUAL_FILE_PATH || echo "Error : no such file" ) )

	if diff $ACTUAL_FILE_PATH $EXPECTED_FILE_PATH &> /dev/null
	then
		TEST_RESULT="${GREEN}✔${NOCOLOR}"
		RETURN_STATUS=0
	fi

	if [[ "${ACTUAL_CONTENT[*]}" == "${EXPECTED_CONTENT[*]}" ]]
	then
		TEST_RESULT="${GREEN}✔${NOCOLOR}"
		RETURN_STATUS=0
	fi

	if [[ $RETURN_STATUS == 1 ]]
	then
		local IFS=$' \t\n'
		local ERROR_DETAILS=( "${DESCRIPTION}" "${INPUTS}" "${EXPECTED_CONTENT[@]}" "${ACTUAL_CONTENT[@]}" )
#		echo "${ERROR_DETAILS[*]}"
		local IFS=$'\n'
		local LENGTH=${#ERROR[*]}
		ERROR[$LENGTH]="${ERROR_DETAILS[*]}"
		DESCRIPTION="${RED}${DESCRIPTION}${NOCOLOR}"
	fi

	echo -e "$TEST_RESULT ${DESCRIPTION}"
	return $RETURN_STATUS
}
