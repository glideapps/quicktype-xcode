#!/usr/bin/env bash -e

source appcenter/slack.sh

# TODO There's no way to indicate failure from build scripts
slack_notify_build_passed

# TODO this should be handled by better App Center built-in notifications
if [ "$APPCENTER_BRANCH" == "master" ]; then
    slack_notify_deployed
fi