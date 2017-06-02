#!/bin/sh
. /lib/functions.sh
SECTION_ID="$1"
load_all_config_options() {
	local __PKGNAME="$1"
	local __SECTIONID="$2"
	local __VAR
	local __ALL_OPTION_VARIABLES=""
	config_cb()
	{
		if [ ."$2" = ."$__SECTIONID" ]; then
			option_cb()
			{
				__ALL_OPTION_VARIABLES="$__ALL_OPTION_VARIABLES $1"
			}
		else
			option_cb() { return 0; }
		fi
	}
	config_load "$__PKGNAME"
	[ -z "$__ALL_OPTION_VARIABLES" ] && return 1
	for __VAR in $__ALL_OPTION_VARIABLES
	do
		config_get "$__VAR" "$__SECTIONID" "$__VAR"
	done
	return 0
}
load_all_config_options "heartbeat" "$SECTION_ID"
while : ; do
	eval mosquitto_pub -h $server_name -p $server_port -q 1 -t "heartbeat" -m "heartbeat"
	sleep $update_interval
done
