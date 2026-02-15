#!/bin/bash
# Helper script for Zabbix UserParameter queries
# Usage: easun_query.sh <key>
# Example: easun_query.sh battery.soc

DATA_FILE="/tmp/easun_data.json"
SCRIPT_DIR="/home/pi/easunpy"

/usr/bin/python3.10 "${SCRIPT_DIR}/zabbix_monitor.py" --query "$1" --data-file "${DATA_FILE}"
