#!/usr/bin/env bash -e

source appcenter/slack.sh

if [ "$AGENT_JOBSTATUS" != "Succeeded" ]; then
    slack_notify_build_failed
    exit 0
fi

# TODO this should be handled by better App Center built-in notifications
if [ "$APPCENTER_BRANCH" == "master" ] && [ "$AGENT_JOBSTATUS" == "Succeeded" ]; then
    slack_notify_deployed
fi