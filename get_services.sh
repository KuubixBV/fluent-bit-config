#!/bin/bash

SERVICE_DIR="./service-configs/"

if [ ! -d "$SERVICE_DIR" ]; then
	echo "Service configuration directory does not exist: $SERVICE_DIR"
	exit 1
fi

echo "Available service configurations:"
ls $SERVICE_DIR | sed 's/\.conf$//' | sort
