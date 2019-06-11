#!/usr/bin/env bash

set -o pipefail
shopt -s nullglob

# Log message colors. Remember to use COLOR_NONE to reset output.
COLOR_GREEN='\033[0;32m'
COLOR_NONE='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_WHITE='\033[0;33m'
COLOR_YELLOW='\033[0;33m'

COLOR_OUTPUT="false"
DEBUG="false"
EX_OPT_A="false"
EX_OPT_B="false"
SYSLOG="true"

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

    if [[ "${SYSLOG}" == "true" ]]; then
        logger -p "${PRIO}" -t "$(basename ${0})[$$]" -- "${*}"
    fi

    # If the message is an error or debugging, output to STDERR. Otherwise output to STDOUT.
    if [[ "${prio}" == "error" || "${prio}" == "debug" ]]; then
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
            shift
            logdebug "EX_OPT_A=true"
            EX_OPT_A="true"
            ;;
        -b|--b)
            shift
            logdebug "EX_OPT_B=true"
            EX_OPT_B="true"
            ;;
        -c|--c)
            shift
            value=$1
            if ! validvalue "${value}"; then
                logerror "Invalid value ${value} for parameter ${param}."
                exit 1
            fi
            logdebug "${param}: ${value}"
            shift
            ;;
        -d|--debug)
            shift
            DEBUG="true"
            logdebug "Debugging output enabled."
            ;;
        -h|--help)
            shift
            usage
            exit 0
            ;;
        -s|--no-syslog)
            shift
            logdebug "Disabling SYSLOG logging."
            SYSLOG="false"
            ;;
        -*)
            shift
            logerror "Unknown option"
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
