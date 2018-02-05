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
prase_mqtt()
{
        [ -z "$mqtt_enabled" ] && mqtt_enabled=0 && echo "mqtt message: mqtt_enabled is missing, mqtt disabled." && return
        [ ! -x /usr/bin/mosquitto_pub ] && mqtt_enabled=0 && echo "mqtt message: mosquitto_pub not found, mqtt disabled." && return
        [ -z "$mqtt_hostname" ] && mqtt_enabled=0 && echo "mqtt message: mqtt_hostname is missing, mqtt disabled." && return
        [ -z "$mqtt_port" ] && mqtt_port=1883 && echo "mqtt message: mqtt_port is missing, use 1883."
        [ -z "$mqtt_id" ] && mqtt_id="$client_id" && echo "mqtt message: mqtt_id is missing, use client_id."
        [ -z "$mqtt_topic" ] && mqtt_topic="heartbeat" && echo "mqtt message: mqtt_topic is missing, use heartbeat."
        [ -z "$mqtt_message" ] && mqtt_message="heartbeat" && echo "mqtt message: mqtt_message is missing, use heartbeat."
        [ -z "$mqtt_use_password" ] && mqtt_use_password=0 && echo "mqtt message: mqtt_use_password is missing, mqtt password authentication disabled."
        [ -z "$mqtt_username" ] && mqtt_use_password=0 && echo "mqtt message: mqtt_username is missing, mqtt password authentication disabled."
        [ -z "$mqtt_password" ] && mqtt_use_password=0 && echo "mqtt message: mqtt_password is missing, mqtt password authentication disabled."
        [ -z "$mqtt_use_tls" ] && mqtt_use_tls=0 && echo "mqtt message: mqtt_use_tls is missing, mqtt tls disabled."
        [ -n "$mqtt_cafile" ] && [ -f "$mqtt_cafile" ] && mqtt_cafile_availible=1 && echo "mqtt message: cafile found."
        [ -n "$mqtt_capath" ] && [ -d "$mqtt_capath" ] && mqtt_capath_availible=1 && echo "mqtt message: capath found."
        [ -z "$mqtt_cafile_availible" ] && [ -z "$mqtt_capath_availible" ] && mqtt_use_tls=0 && echo "mqtt message: mqtt_cafile and mqtt_capath are invalid, mqtt tls disabled."
        [ -z "$mqtt_insecure" ] && mqtt_insecure=0 && echo "mqtt message: mqtt_insecure is missing, use 0."
        if [ "$mqtt_enabled" -eq 1 ]; then
                [ "$mqtt_use_password" -eq 1 ] && mqtt_subcmd_password="-u '${mqtt_username}' -P '${mqtt_password}'"
                if [ "$mqtt_use_tls" -eq 1 ]; then
                        if [ -n "$mqtt_cafile_availible" ]; then
                                mqtt_subcmd_tls="--cafile '${mqtt_cafile}'"
                        elif [ -n "$mqtt_capath_availible" ]; then
                                mqtt_subcmd_tls="--capath '${mqtt_capath}'"
                        fi
                        if [ "$mqtt_insecure" -eq 1 ]; then
                                mqtt_subcmd_tls="${mqtt_subcmd_tls} --insecure"
                        fi
                fi
                mqtt_cmd="mosquitto_pub -d -h '${mqtt_hostname}' -p '${mqtt_port}' -q 1 -t '${mqtt_topic}' -m '${mqtt_message}' -i '${mqtt_id}' ${mqtt_subcmd_password} ${mqtt_subcmd_tls}"
        fi
}
prase_http()
{
        [ -z "$http_enabled" ] && http_enabled=0 && echo "http message: http_enabled is missing, http disabled." && return
        [ ! -x /usr/bin/wget ] &&  http_enabled=0 && echo "http message: wget not found, http disabled." && return
        [ -z "$http_hostname" ] && http_enabled=0 && echo "http message: http_hostname is missing, http disabled." && return
        [ -z "$http_id" ] && http_id="$client_id" && echo "http message: http_id is missing, use client_id."
        [ -z "$http_ssl_enabled" ] && http_ssl_enabled=0 && echo "http message: http_ssl_enabled is missing, http ssl disabled."
        [ -n "$http_ssl_cafile" ] && [ -f "$http_ssl_cafile" ] && http_ssl_cafile_availible=1 && echo "http message: cafile found."
        [ -n "$http_ssl_capath" ] && [ -d "$http_ssl_capath" ] && http_ssl_capath_availible=1 && echo "http message: capath found."
        [ -z "$http_ssl_cafile_availible" ] && [ -z "$http_ssl_capath_availible" ] && http_ssl_enabled=0 && echo "http message: http_cafile and http_capath are invalid, http ssl disabled."
        [ -z "$http_ssl_verify_client_enabled" ] && http_ssl_verify_client_enabled=0 && echo "http message: http_ssl_verify_client_enabled is missing, http ssl verify client disabled."
        [ -z "$http_ssl_verify_client_cert" ] || [ ! -f "$http_ssl_verify_client_cert" ] && http_ssl_verify_client_enabled=0 && echo "http message: client cert is invalid, http ssl verify client disabled."
        [ -z "$http_ssl_verify_client_key" ] || [ ! -f "$http_ssl_verify_client_key" ] && http_ssl_verify_client_enabled=0 && echo "http message: client key is invalid, http ssl verify client disabled."
        if [ "$http_enabled" -eq 1 ]; then
                if [ "$http_ssl_enabled" -eq 1 ]; then
                        http_protocol="https"
                        if [ -n "$http_ssl_cafile_availible" ]; then
                                http_subcmd_http_ssl="--certificate='${http_ssl_cafile}'"
                        elif [ -n "$http_ssl_capath_availible" ]; then
                                http_subcmd_http_ssl="--ca-directory='${http_ssl_capath}'"
                        fi
                        if [ "$http_ssl_verify_client_enabled" -eq 1 ]; then
				http_subcmd_http_ssl_verify_client="--certificate='${http_ssl_verify_client_cert}' --private-key='${http_ssl_verify_client_key}'"
                        fi
                else
                        http_protocol="http"
                fi
                [ -z "$http_path" ] || [ "${http_path:0:1}" != "/" ] && http_path="/${http_path}"
                [ -n "$http_port" ] && http_port=":${http_port}"
                http_url="${http_protocol}://${http_hostname}${http_port}${http_path}"
        fi
        http_cmd="wget '${http_url}?clientid=${http_id}&token=${http_token}' -O - ${http_subcmd_http_ssl} ${http_subcmd_http_ssl_verify_client}"
}
load_all_config_options "heartbeat" "$SECTION_ID"
[ "$logfile" ] && exec 1>/tmp/${logfile} 2>&1
[ -z "$enabled" ] && enabled=0 && echo "global message: enabled is missing, use 0, stop run." && exit 0
[ -z "$client_id" ] && client_id="`uname -n`" && echo "global message: client_id is missing, use hostname: ${client_id}."
[ -z "$update_interval" ] && update_interval=5 && echo "global message: update_interval is missing, use 5."
prase_mqtt
prase_http
[ "$mqtt_enabled" -eq 0 ] && [ "$http_enabled" -eq 0 ] && enabled=0 && echo "global message: mqtt and http are invalid, stop run." && exit 0
while : ; do
        if [ "$mqtt_enabled" -eq 1 ]; then
		echo "${mqtt_cmd}"
		eval "${mqtt_cmd}"
        fi
        if [ "$http_enabled" -eq 1 ]; then
		echo "${http_cmd}"
		eval "${http_cmd}"
        fi
        sleep $update_interval
done
