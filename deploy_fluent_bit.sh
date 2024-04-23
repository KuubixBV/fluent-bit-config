#!/bin/bash
# This script will do 3 things:
# => Create configuration directory for fluent-bit
# => Copy specified configuration files to there
# => Setup system daemon service file to point to correct config
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

if [ $# -eq 0 ]; then
	echo "No configurations specified, use the 'get_services' to see available configs."
	exit 1
fi

# Source .env
. .env

# Fluent bit configuration directory
CONFIG_DIR="/etc/fluent-bit/configs"
mkdir -p $CONFIG_DIR
mkdir -p "$CONFIG_DIR/inputs"

# FLuent-bit daemon
FLUENT_BIT_SERVICE_PATH=${SYSTEMD_SERVICE_PATH}

# Base config and parsers
cp -r ./global-config/. $CONFIG_DIR
# Env
cp ./.env $CONFIG_DIR

# Service config
SERVICE_DIR="./service-configs/"

# Remove old service configs
rm -f $CONFIG_DIR/inputs/service_*.conf

for service in "$@"
do
	if [ -f "$SERVICE_DIR/${service}.conf" ]; then
		echo "Deploying configuration for $service"
		cp "$SERVICE_DIR/${service}.conf" $CONFIG_DIR/inputs
	else
		echo "Warning: No configuration found for $service"
	fi
done

# Swap out service file
if [ -f "$FLUENT_BIT_SERVICE_PATH" ]; then
	echo "Updating Fluent Bit daemon service to use new config.."
	sed -i "s|ExecStart=.*|ExecStart=$FLUENT_BIT_EXECUTABLE -c $CONFIG_DIR/fluent-bit.conf|g" $FLUENT_BIT_SERVICE_PATH
	systemctl daemon-reload
	systemctl restart fluent-bit
else
	echo "Error: Fluent Bit daemon service does not exist at $FLUENT_BIT_SERVICE_PATH"
fi

