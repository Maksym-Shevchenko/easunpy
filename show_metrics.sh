#!/bin/bash
# Display all available Easun inverter metrics (ultra-fast version)

echo "=== Easun Inverter Metrics ==="
echo ""

DATA_FILE="/tmp/easun_data.json"

# Check if data file exists
if [ ! -f "$DATA_FILE" ]; then
    echo "Error: Data file not found. Is the monitor running?"
    exit 1
fi

# Read all values at once using jq (if available) or Python
if command -v jq &> /dev/null; then
    # Use jq to format everything in one call
    jq -r '
    "System Status:",
    "Status                        : \(.status // "N/A") (1=OK, 0=Error)",
    "Operating Mode                : \(.["system.mode"] // "N/A")",
    "Last Update                   : \(.timestamp // "N/A")",
    "",
    "Battery:",
    "Voltage                       : \(.["battery.voltage"] // "N/A") V",
    "Current                       : \(.["battery.current"] // "N/A") A",
    "Power                         : \(.["battery.power"] // "N/A") W",
    "State of Charge               : \(.["battery.soc"] // "N/A") %",
    "Temperature                   : \(.["battery.temperature"] // "N/A") °C",
    "",
    "Solar (PV):",
    "Total Power                   : \(.["pv.total_power"] // "N/A") W",
    "Charging Power                : \(.["pv.charging_power"] // "N/A") W",
    "Charging Current              : \(.["pv.charging_current"] // "N/A") A",
    "PV1 Voltage                   : \(.["pv1.voltage"] // "N/A") V",
    "PV1 Current                   : \(.["pv1.current"] // "N/A") A",
    "PV1 Power                     : \(.["pv1.power"] // "N/A") W",
    "PV2 Voltage                   : \(.["pv2.voltage"] // "N/A") V",
    "PV2 Current                   : \(.["pv2.current"] // "N/A") A",
    "PV2 Power                     : \(.["pv2.power"] // "N/A") W",
    "Generated Today               : \(.["pv.energy_today"] // "N/A") kWh",
    "Generated Total               : \(.["pv.energy_total"] // "N/A") kWh",
    "",
    "Grid:",
    "Voltage                       : \(.["grid.voltage"] // "N/A") V",
    "Power                         : \(.["grid.power"] // "N/A") W",
    "Frequency                     : \(.["grid.frequency"] // "N/A") Hz",
    "",
    "Output:",
    "Voltage                       : \(.["output.voltage"] // "N/A") V",
    "Current                       : \(.["output.current"] // "N/A") A",
    "Power                         : \(.["output.power"] // "N/A") W",
    "Load                          : \(.["output.load_percentage"] // "N/A") %",
    "Frequency                     : \(.["output.frequency"] // "N/A") Hz",
    ""
    ' "$DATA_FILE"
else
    # Fallback to Python if jq not available
    python3 -c "
import json
import sys

try:
    with open('$DATA_FILE') as f:
        data = json.load(f)

    def get(key, default='N/A'):
        return data.get(key, default)

    print('System Status:')
    print(f'Status                        : {get(\"status\")} (1=OK, 0=Error)')
    print(f'Operating Mode                : {get(\"system.mode\")}')
    print(f'Last Update                   : {get(\"timestamp\")}')
    print()
    print('Battery:')
    print(f'Voltage                       : {get(\"battery.voltage\")} V')
    print(f'Current                       : {get(\"battery.current\")} A')
    print(f'Power                         : {get(\"battery.power\")} W')
    print(f'State of Charge               : {get(\"battery.soc\")} %')
    print(f'Temperature                   : {get(\"battery.temperature\")} °C')
    print()
    print('Solar (PV):')
    print(f'Total Power                   : {get(\"pv.total_power\")} W')
    print(f'Charging Power                : {get(\"pv.charging_power\")} W')
    print(f'Charging Current              : {get(\"pv.charging_current\")} A')
    print(f'PV1 Voltage                   : {get(\"pv1.voltage\")} V')
    print(f'PV1 Current                   : {get(\"pv1.current\")} A')
    print(f'PV1 Power                     : {get(\"pv1.power\")} W')
    print(f'PV2 Voltage                   : {get(\"pv2.voltage\")} V')
    print(f'PV2 Current                   : {get(\"pv2.current\")} A')
    print(f'PV2 Power                     : {get(\"pv2.power\")} W')
    print(f'Generated Today               : {get(\"pv.energy_today\")} kWh')
    print(f'Generated Total               : {get(\"pv.energy_total\")} kWh')
    print()
    print('Grid:')
    print(f'Voltage                       : {get(\"grid.voltage\")} V')
    print(f'Power                         : {get(\"grid.power\")} W')
    print(f'Frequency                     : {get(\"grid.frequency\")} Hz')
    print()
    print('Output:')
    print(f'Voltage                       : {get(\"output.voltage\")} V')
    print(f'Current                       : {get(\"output.current\")} A')
    print(f'Power                         : {get(\"output.power\")} W')
    print(f'Load                          : {get(\"output.load_percentage\")} %')
    print(f'Frequency                     : {get(\"output.frequency\")} Hz')
    print()
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
fi
