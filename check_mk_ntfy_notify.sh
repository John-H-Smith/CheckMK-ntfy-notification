#!/bin/bash
# Push Notification (using ntfy.sh)
#
# Script Name   : check_mk_ntfy_notify.sh
# Description   : Send Check_MK notifications to ntfy.sh
# Author        : Fabian Heinz | fabian heinz webdesign
# License       : BSD 3-Clause "New" or "Revised" License
# ======================================================================================

# ntfy.sh topic
if [ -z ${NOTIFY_PARAMETER_1} ]; then
        echo "No Topic provided. Exiting" >&2
        exit 2
else
        TOPIC="${NOTIFY_PARAMETER_1}"
fi

# server address
if [[ -z ${NOTIFY_PARAMETER_2} || ${NOTIFY_PARAMETER_2} == "null" || ${NOTIFY_PARAMETER_2} == "" ]]; then
        SERVER_HOST="https://ntfy.sh"
else
                SERVER_HOST=${NOTIFY_PARAMETER_2}
fi

# username
if [ -n ${NOTIFY_PARAMETER_3} ]; then
        SERVER_USER=${NOTIFY_PARAMETER_3}
fi

# password
if [ -n ${NOTIFY_PARAMETER_4} ]; then
        SERVER_PASSWORD=${NOTIFY_PARAMETER_4}
fi

if [[ ${NOTIFY_WHAT} == "SERVICE" ]]; then
        STATE="${NOTIFY_SERVICESHORTSTATE}"
else
        STATE="${NOTIFY_HOSTSHORTSTATE}"
fi
case "${STATE}" in
    OK|UP)
        EMOJI='white_check_mark'
        PRIORITY='default'
        ;;
    WARN)
        EMOJI='warning'
        PRIORITY='high'
        ;;
    CRIT|DOWN)
        EMOJI='exclamation'
        PRIORITY='urgent'
        ;;
    UNKN)
        EMOJI='grey_question'
        PRIORITY='high'
        ;;
esac


if [[ ${NOTIFY_WHAT} == "SERVICE" ]]; then
        SERVICE_TYPE=${NOTIFY_SERVICEDESC}
        ERROR_DESCRIPTION=${NOTIFY_SERVICEOUTPUT}
        PREV_STATE=${NOTIFY_PREVIOUSSERVICEHARDSHORTSTATE}
        CURRENT_STATE=${NOTIFY_SERVICESHORTSTATE}
else
        SERVICE_TYPE=""
        ERROR_DESCRIPTION=${NOTIFY_HOSTOUTPUT}
        PREV_STATE=${NOTIFY_PREVIOUSHOSTHARDSHORTSTATE}
        CURRENT_STATE=${NOTIFY_HOSTSHORTSTATE}
fi

MESSAGE="${NOTIFY_HOSTNAME}
reports

${SERVICE_TYPE}
${ERROR_DESCRIPTION}

State changed from ${PREV_STATE} to ${CURRENT_STATE}

Server: ${NOTIFY_HOSTNAME}
Alias: ${NOTIFY_HOSTALIAS}
IPv4: ${NOTIFY_HOST_ADDRESS_4}
IPv6: ${NOTIFY_HOST_ADDRESS_6}
Alert found on site '${OMD_SITE}' at ${NOTIFY_SHORTDATETIME}"


if [[ -z ${SERVER_USER} && -z ${SERVER_PASSWORD} ]]; then
        curl -s -X POST "${SERVER_HOST}/${TOPIC}" -H "Title: ${NOTIFY_WHAT} ${SERVICE_TYPE} ${STATE}" -H "Priority: high" -H "Tags: ${EMOJI}" -d "${MESSAGE}"
else
        curl -s -X POST "${SERVER_HOST}/${TOPIC}" -u ${SERVER_USER}:${SERVER_PASSWORD} -H "Title: ${NOTIFY_WHAT} ${SERVICE_TYPE} ${STATE}" -H "Priority: high" -H "Tags: ${EMOJI}" -d "${MESSAGE}"
fi

if [ $? -ne 0 ]; then
        echo "Not able to send ntfy message" >&2
        exit 2
else
        exit 0
fi