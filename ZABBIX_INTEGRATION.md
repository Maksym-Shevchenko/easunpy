# Easun Inverter - Zabbix Integration

## Overview

The `zabbix_monitor.py` script maintains a persistent connection to the Easun inverter and periodically updates a JSON file with the latest data. This allows Zabbix to query inverter metrics efficiently without reconnecting each time.

## Features

- **Persistent Connection**: Reuses the same TCP connection to the inverter
- **Automatic Reconnection**: Handles connection failures gracefully
- **JSON Data Store**: Stores data in `/tmp/easun_data.json`
- **Query Interface**: Simple query mode for Zabbix UserParameters
- **Systemd Service**: Can run as a background service

## Installation

### 1. Copy Files

Files are already copied to `~/easunpy/`:
- `zabbix_monitor.py` - Main monitoring script
- `easun_query.sh` - Helper script for Zabbix queries

### 2. Install as Systemd Service

```bash
# Copy service file
sudo cp easun-zabbix.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable easun-zabbix.service
sudo systemctl start easun-zabbix.service

# Check status
sudo systemctl status easun-zabbix.service

# View logs
sudo journalctl -u easun-zabbix.service -f
```

### 3. Test the Script

```bash
# Run manually (for testing)
cd ~/easunpy
./zabbix_monitor.py --inverter-ip 10.1.31.9 --model ISOLAR_SMG_II_6K --interval 30

# Query a value
./zabbix_monitor.py --query battery.soc
./zabbix_monitor.py --query pv.total_power
./zabbix_monitor.py --query output.power
```

## Available Metrics

### Battery Metrics
- `battery.voltage` - Battery voltage (V)
- `battery.current` - Battery current (A)
- `battery.power` - Battery power (W)
- `battery.soc` - State of charge (%)
- `battery.temperature` - Battery temperature (°C)

### PV (Solar) Metrics
- `pv.total_power` - Total PV power (W)
- `pv.charging_power` - PV charging power (W)
- `pv.charging_current` - PV charging current (A)
- `pv1.voltage` - PV1 voltage (V)
- `pv1.current` - PV1 current (A)
- `pv1.power` - PV1 power (W)
- `pv2.voltage` - PV2 voltage (V)
- `pv2.current` - PV2 current (A)
- `pv2.power` - PV2 power (W)
- `pv.energy_today` - Energy generated today (kWh)
- `pv.energy_total` - Total energy generated (kWh)

### Grid Metrics
- `grid.voltage` - Grid voltage (V)
- `grid.power` - Grid power (W)
- `grid.frequency` - Grid frequency (Hz)

### Output Metrics
- `output.voltage` - Output voltage (V)
- `output.current` - Output current (A)
- `output.power` - Output power (W)
- `output.load_percentage` - Load percentage (%)
- `output.frequency` - Output frequency (Hz)

### System Metrics
- `system.mode` - Operating mode name
- `system.mode_code` - Operating mode code
- `system.inverter_time` - Inverter internal time
- `status` - Overall status (1=OK, 0=Error)
- `timestamp` - Last update timestamp

## Zabbix Configuration (Future)

### Option 1: UserParameter Method

Add to `/etc/zabbix/zabbix_agentd.conf` (or a file in `/etc/zabbix/zabbix_agentd.d/`):

```ini
# Easun Inverter Monitoring
UserParameter=easun[*],/home/pi/easunpy/easun_query.sh $1
```

Then restart Zabbix agent:
```bash
sudo systemctl restart zabbix-agent
```

Test from Zabbix server:
```bash
zabbix_get -s 10.0.0.111 -k easun[battery.soc]
zabbix_get -s 10.0.0.111 -k easun[pv.total_power]
```

### Option 2: Zabbix Sender (Active Push)

Modify the script to use `zabbix_sender` to push data actively to Zabbix server.

### Option 3: HTTP Endpoint

Add a simple HTTP server to the script to expose metrics via HTTP for Zabbix HTTP checks.

## Monitoring the Service

```bash
# Check if service is running
sudo systemctl status easun-zabbix.service

# View real-time logs
sudo journalctl -u easun-zabbix.service -f

# Check the data file
cat /tmp/easun_data.json

# View monitor logs
tail -f /tmp/easun_zabbix.log
```

## Troubleshooting

### Service won't start
```bash
# Check logs
sudo journalctl -u easun-zabbix.service -n 50

# Test script manually
cd ~/easunpy
./zabbix_monitor.py --inverter-ip 10.1.31.9 --model ISOLAR_SMG_II_6K --interval 30
```

### No data in JSON file
- Check if the service is running: `sudo systemctl status easun-zabbix.service`
- Check logs: `tail -f /tmp/easun_zabbix.log`
- Verify inverter is reachable: `ping 10.1.31.9`

### Old data (timestamp > 5 minutes)
- Service might have crashed - check with `systemctl status`
- Connection to inverter might be lost - check logs

## Configuration Options

The script accepts these command-line arguments:

- `--inverter-ip` - IP address of the inverter (required)
- `--local-ip` - Local IP address (auto-detected if not specified)
- `--model` - Inverter model (default: ISOLAR_SMG_II_6K)
- `--interval` - Update interval in seconds (default: 30)
- `--data-file` - Path to JSON data file (default: /tmp/easun_data.json)
- `--query` - Query mode: get a specific value and exit
- `--discover` - Auto-discover inverter IP

## Performance

- **Connection overhead**: Only on startup (UDP discovery + TCP handshake)
- **Per-update overhead**: Minimal - reuses existing connection
- **Memory usage**: ~50-100MB (Python + asyncio)
- **CPU usage**: <1% between updates
- **Network traffic**: ~2-3 KB per update

## Data Freshness

- Data is updated every 30 seconds (configurable)
- Queries return cached data from the JSON file
- Data older than 5 minutes is rejected with `ZBX_NOTSUPPORTED`
