#!/usr/bin/env bash

set -o pipefail
shopt -s nullglob

# Log message colors. Remember to use COLOR_NONE to reset output.
COLOR_GREEN='\033[0;32m'
COLOR_NONE='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0;33m'
COLOR_YELLOW='\033[0;33m'

DEBUG="false"
EX_OPT_A="false"
EX_OPT_B="false"
COLOR_OUTPUT="false"

if [[ -t 0 ]]; then
    # STDIN is a TTY, show the user colors.
    COLOR_OUTPUT="true"
fi

logprio () {
    # Output messages to STDOUT/STDERR and Syslog
    # Colorize messages based on priority if running on a TTY
    PRIO="$1"
    shift

    LOGCOLOR=${COLOR_NONE}
    if [[ "${COLOR_OUTPUT}" == "true" ]]; then
        case "${PRIO}" in
            debug)
                LOGCOLOR=${COLOR_GREEN}
                ;;
            warning)
                LOGCOLOR=${COLOR_YELLOW}
                ;;
            error)
                LOGCOLOR=${COLOR_RED}
                ;;
        esac
    fi

    # Output the colorized message to STDOUT
    logger -p "${PRIO}" -t "$(basename ${0})[$$]" -- "${*}"

    if [[ "${prio}" == "error" || "${prio}" == "debug" ]]; then
        # Always output error messages to STDERR.
        # Also output debug messages to STDERR.
        echo -e "${LOGCOLOR}${PRIO^}: ${*}${COLOR_NONE}" >&2
    else
        echo -e "${LOGCOLOR}${PRIO^}: ${*}${COLOR_NONE}"
    fi
}

logdebug () {
    if [[ "${DEBUG}" == "true" ]]; then
        logprio debug "${*}"
    fi
}

loginfo () {
    logprio info "${*}"
}

logwarn () {
    logprio warning "${*}"
}

logerror () {
    logprio error "${*}"
}

validvalue() {
    local value="$1"

    if [[ "${value}" =~ ^-.* ]]; then
        logdebug "Value ${value} starts with -"
        return 1
    fi
}

usage() {
    scriptname="$(basename $0)"

    cat <<EOF

${scriptname} -- Apply firmware updates

Usage: ${scriptname} [--a | -b]
    -a | --a       Exclusive option A
    -b | --b       Exclusive option B

EOF
}

do_something() {
    loginfo "Doing something."
    return 0
}

if [[ -z "${BASH_VERSINFO}" || -z "${BASH_VERSINFO[0]}" || ${BASH_VERSINFO[0]} -lt 4 ]]; then
    echo -e "${COLOR_RED}Error: This script requires BASH >= 4.0.${COLOR_NONE}" >&2
    echo -e "${COLOR_RED}Error: Bash 4.0 was released in 2009. Get with it. Seriously.${COLOR_NONE}" >&2
    exit 1
fi

while [[ -n $1 ]]; do
    param=$1
    case ${param} in
        -a|--a)
            EX_OPT_A="true"
            shift
            ;;
        -b|--b)
            EX_OPT_B="true"
            shift
            ;;
        -c|--c)
            shift
            value=$1

            logdebug "${param}: ${value}"
            if ! validvalue "${value}"; then
                logerror "Invalid value ${value} for parameter ${param}."
                exit 1
            fi
            shift
            ;;
        -d|--debug)
            DEBUG="true"
            shift
            ;;
        -h|--help)
            shift
            usage
            exit 0
            ;;
        -*)
            logerror "Unknown option"
            shift
            usage
            exit 1
            ;;
    esac
done

if [[ "${EX_OPT_A}" == "true" && "${EX_OPT_B}" == "true" ]]; then
    logerror "Option A and Option B are exclusive."
    usage
    exit 1
fi

do_something
