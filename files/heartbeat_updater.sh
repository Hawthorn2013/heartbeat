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
[ "$logfile" ] && exec 1>/tmp/${logfile} 2>&1
client_id="`uname -n`"
[ -z "$enabled" ] && enabled=0
[ -z "$mqtt_hostname" ] && enabled=0
[ -z "$mqtt_port" ] && server_port=1883
[ -z "$update_interval" ] && update_interval=5
[ -z "$mqtt_topic" ] && mqtt_topic="heartbeat"
[ -z "$mqtt_message" ] && mqtt_message="heartbeat"
[ -z "$mqtt_id" ] && mqtt_id="$client_id"
[ -z "$mqtt_use_password" ] && mqtt_use_password=0
[ -z "$mqtt_username" ] && mqtt_use_password=0
[ -z "$mqtt_password" ] && mqtt_use_password=0
[ -z "$mqtt_use_tls" ] && mqtt_use_tls=0
[ -n "$mqtt_cafile" ] && [ -f "$mqtt_cafile" ] && cafile_availible=1
[ -n "$mqtt_capath" ] && [ -d "$mqtt_capath" ] && capath_availible=1
[ -z "$cafile_availible" ] && [ -z "$capath_availible" ] && mqtt_use_tls=0
[ -z "$mqtt_insecure" ] && mqtt_insecure=0
[ -z "$http_enabled" ] && http_enabled=0
[ -z "$http_hostname" ] && http_enabled=0
[ -z "$http_id" ] && http_id="$client_id"
[ -z "$http_ssl_enabled" ] && http_ssl_enabled=0
[ -n "$http_ssl_cafile" ] && [ -f "$http_ssl_cafile" ] && http_ssl_cafile_availible=1
[ -n "$http_ssl_capath" ] && [ -d "$http_ssl_capath" ] && http_ssl_capath_availible=1
[ -z "$http_ssl_cafile_availible" ] && [ -z "$http_ssl_capath_availible" ] && http_ssl_enabled=0
[ -z "$http_ssl_verify_client_enabled" ] && http_ssl_verify_client_enabled=0
[ -n "$http_ssl_verify_client_cert" ] && [ -f "$http_ssl_verify_client_cert" ] && http_ssl_verify_client_cert_availible=1
[ -n "$http_ssl_verify_client_key" ] && [ -d "$http_ssl_verify_client_key" ] && http_ssl_verify_client_key_availible=1
[ -z "$http_ssl_verify_client_cert_availible" ] && [ -z "$http_ssl_verify_client_key_availible" ] && http_ssl_verify_client_enabled=0
if [ "$enabled" -eq 0 ]; then
	exit 0
fi
[ "$mqtt_use_password" -eq 1 ] && subcmd_password="-u $mqtt_username -P $mqtt_password"
if [ "$mqtt_use_tls" -eq 1 ]; then
	if [ -n "$cafile_availible" ]; then
		subcmd_tls="--cafile $mqtt_cafile"
	elif [ -n "$capath_availible" ]; then
		subcmd_tls="--capath $mqtt_capath"
	fi
	if [ "$mqtt_insecure" -eq 1 ]; then
		subcmd_tls="$subcmd_tls --insecure"
	fi
fi
if [ "$http_enabled" -eq 1 ]; then
	if [ "$http_ssl_enabled" -eq 1 ]; then
		http_protocol="https"
		if [ -n "$http_ssl_cafile_availible" ]; then
			subcmd_http_ssl="--certificate='${http_ssl_cafile}'"
		elif [ -n "$http_ssl_capath_availible" ]; then
			subcmd_http_ssl="--ca-directory='${http_ssl_capath}'"
		fi
		if [ "$http_ssl_verify_client_enabled" -eq 1 ]; then
			if [ -n "$http_ssl_verify_client_cert_availible" ]; then
				subcmd_http_ssl_verify_client="--certificate='${http_ssl_verify_client_cert}' --private-key='${http_ssl_verify_client_key}'"
			fi
		fi
	else
		http_protocol="http"
	fi
	[ -n "$http_path" ] || [ "${http_path:0:1}" -eq "/" ] && http_path="/${http_path}"
	[ -n "$http_port" ] && http_port=":${http_port}"
	http_url="${http_protocol}://${http_hostname}${http_port}${http_path}"
fi
while : ; do
	eval mosquitto_pub -h $mqtt_hostname -p $mqtt_port -q 1 -t "$mqtt_topic" -m "$mqtt_message" -i "$mqtt_id" "$subcmd_password" "$subcmd_tls"
	if [ "$http_enabled" -eq 1 ]; then
		eval wget "'${http_url}?clientid=${client_id}&token=${http_token}'" -O - "${subcmd_http_ssl}" "${subcmd_http_ssl_verify_client}"
	fi
	sleep $update_interval
done
