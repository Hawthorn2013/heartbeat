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
[ -z "$enabled" ] && enabled=0
[ -z "$server_name" ] && enabled=0
[ -z "$server_port" ] && server_port=1883
[ -z "$update_interval" ] && update_interval=5
[ -z "$mqtt_topic" ] && mqtt_topic="heartbeat"
[ -z "$mqtt_message" ] && mqtt_message="heartbeat"
[ -z "$mqtt_id" ] && mqtt_id="`uname -n`"
[ -z "$use_password" ] && use_password=0
[ -z "$username" ] && use_password=0
[ -z "$password" ] && use_password=0
if [ "$enabled" -eq 0 ]; then
	exit 0
fi
while : ; do
if [ "$use_password" -eq 0 ]; then
	eval mosquitto_pub -h $server_name -p $server_port -q 1 -t "$mqtt_topic" -m "$mqtt_message" -i "$mqtt_id"
else
	eval mosquitto_pub -h $server_name -p $server_port -q 1 -t "$mqtt_topic" -m "$mqtt_message" -i "$mqtt_id" -u "$username" -P "$password"
fi
	sleep $update_interval
done
