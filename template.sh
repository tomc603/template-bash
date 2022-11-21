#!/usr/bin/env bash
#
# Describe this script's purpose

# Copyright 2022 Tom Cameron
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# TODO: Update script description in the header.
# TODO: Update script description in the usage text.
# TODO: Update parameter parsing.

set -e
set -o pipefail
shopt -s nullglob

# Verify we're using BASH 4.0 or newer, otherwise bail out
if [[ -z "${BASH_VERSINFO}" || -z "${BASH_VERSINFO[0]}" || ${BASH_VERSINFO[0]} -lt 4 ]]; then
    echo -e "${COLOR_RED}Error: This script requires BASH >= 4.0.${COLOR_NONE}" >&2
    echo -e "${COLOR_RED}Error: Bash 4.0 was released in 2009. Get with it. Seriously.${COLOR_NONE}" >&2
    exit 254
fi

# Log message colors. Remember to use COLOR_NONE to reset output.
declare COLOR_GREEN='\033[0;32m'
declare COLOR_NONE='\033[0m'
declare COLOR_RED='\033[0;31m'
declare COLOR_WHITE='\033[0;33m'
declare COLOR_YELLOW='\033[0;33m'

# Runtime option variables
declare COLOR_OUTPUT="false"
declare DEBUG="false"
declare INPUT_FILE=""
declare OPT_A="false"
declare OPT_B="false"
declare -a REMAINING
declare SCRIPT_NAME
declare SYSLOG="false"
declare VERBOSE="false"

SCRIPT_NAME="$(basename "$0")"

# STDIN is a TTY, show the user colors.
if [[ -t 0 ]]; then
    COLOR_OUTPUT="true"
fi

#######################################
# Output optionally colorized messages
# Globals:
#   COLOR_GREEN
#   COLOR_YELLOW
#   COLOR_RED
#   COLOR_NONE
# Arguments:
#   Priority string
# Outputs:
#   Log message to stdout/stderr and/or syslog
########################################
log_prio () {
    local PRIO="$1"
    shift

    local LOGCOLOR=${COLOR_NONE}
    if [[ "${COLOR_OUTPUT}" == "true" ]]; then
        case "${PRIO}" in
            debug) LOGCOLOR=${COLOR_GREEN} ;;
            error) LOGCOLOR=${COLOR_RED} ;;
            info) LOGCOLOR=${COLOR_WHITE} ;;
            warning) LOGCOLOR=${COLOR_YELLOW} ;;
        esac
    fi

    # Output messages to system logger
    if [[ "${SYSLOG}" == "true" ]]; then
        logger -p "${PRIO}" -t "${SCRIPT_NAME}[$$]" -- "${*}"
    fi

    # If the message is an error or debugging, output to STDERR. Otherwise output to STDOUT.
    if [[ "${PRIO}" == "error" || "${PRIO}" == "debug" ]]; then
        echo -e "${LOGCOLOR}${PRIO^}: ${*}${COLOR_NONE}" >&2
    else
        echo -e "${LOGCOLOR}${PRIO^}: ${*}${COLOR_NONE}"
    fi
}

#######################################
# Output debug message if debugging is enabled
# Globals:
#   DEBUG
# Arguments:
#   Log message string
########################################
log_debug () {
    if [[ "${DEBUG}" == "true" ]]; then
        log_prio debug "${*}"
    fi
}

#######################################
# Output information message
# Arguments:
#   Log message string
########################################
log_info () {
    log_prio info "${*}"
}

#######################################
# Output warning message
# Arguments:
#   Log message string
########################################
log_warn () {
    log_prio warning "${*}"
}

#######################################
# Output error message
# Arguments:
#   Log message string
########################################
log_error () {
    log_prio error "${*}"
}

#######################################
# Print a helpful usage information message
# Globals:
#   SCRIPT_NAME
# Outputs:
#   Usage details to stdout
########################################
usage() {
    cat <<EOF

${SCRIPT_NAME} -- Describe the function of this script

Usage: ${SCRIPT_NAME} [-a | -b] [-d] [-v] -i INPUT_FILE SOMETHING [SOMETHING ...]
    -a               Exclusive option A
    -b               Exclusive option B
    -d               Output debugging messages.
    -h               Print this usage message.
    -i               File containing data to read. Required.
    -v               Output verbose messages.
    SOMETHING        One or more extra options, like a directory.

EOF
}

#######################################
# The main function that performs the script action
# Globals:
#   DEBUG
#   INPUT_FILE
#   OPT_A
#   OPT_B
#   SYSLOG
#   VERBOSE
#   REMAINING
# Outputs:
#
# Returns:
#
########################################
do_something() {
    log_info "Doing something."

    cat << EOF
Option Report:
DEBUG     = ${DEBUG}
INPUT_FILE = ${INPUT_FILE}
OPT_A     = ${OPT_A}
OPT_B     = ${OPT_B}
SYSLOG    = ${SYSLOG}
VERBOSE   = ${VERBOSE}

REMAINING = ${REMAINING[@]}

EOF
}

# Process command line options
while getopts :abdhi:Sv OPTION; do
    case "${OPTION}" in
      a) OPT_A="true" ;;
      b) OPT_B="true" ;;
      d)
        DEBUG="true"
        VERBOSE="true"
        ;;
      h)
        usage
        exit 0
        ;;
      i) INPUT_FILE="${OPTARG}" ;;
      S) SYSLOG="true" ;;
      v) VERBOSE="true" ;;
      *)
        log_error "Invalid option -${OPTARG}"
        usage
        exit 1
        ;;
    esac
done

# Gather remaining options
shift $((OPTIND - 1))
REMAINING=( "$@" )

# Verify mutually exclusive options don't conflict
if [[ "${OPT_A}" == "true" && "${OPT_B}" == "true" ]]; then
    log_error "Option A and Option B are exclusive."
    usage
    exit 1
fi

# Call the main function of the script
do_something
