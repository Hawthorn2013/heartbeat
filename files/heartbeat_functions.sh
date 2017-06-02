#!/bin/sh
. /lib/functions.sh
load_all_service_sections() {
	local __DATA=""
	config_cb() {
		[ "$1" = "service" ] && __DATA="$__DATA $2"
	}
	config_load "heartbeat"
	eval "$1=\"$__DATA\""
	return
}
start_daemon_for_all_heartbeat_sections() {
	local __SECTIONS="$1"
	local __SECTIONID=""
	load_all_service_sections __SECTIONS
	for __SECTIONID in $__SECTIONS; do
		/usr/lib/heartbeat/heartbeat_updater.sh $__SECTIONID >/dev/null 2>&1 &
	done
}
