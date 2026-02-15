# Easun Inverter - Zabbix Monitoring System

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Performance](#performance)
6. [Zabbix Integration](#zabbix-integration)
7. [Available Metrics](#available-metrics)
8. [Troubleshooting](#troubleshooting)
9. [Technical Details](#technical-details)

---

## Overview

This monitoring system provides **persistent connection-based** data collection from Easun inverters for Zabbix monitoring. Unlike traditional polling methods that reconnect for each request, this system maintains a single TCP connection to the inverter, dramatically reducing overhead and improving reliability.

### Key Features

- ✅ **Persistent Connection**: Connects once, reuses connection for all subsequent polls
- ✅ **High Performance**: Sub-second metric retrieval (0.28s for all 30+ metrics)
- ✅ **Auto-Reconnect**: Handles connection failures gracefully with automatic reconnection
- ✅ **Low Resource Usage**: ~50MB RAM, <1% CPU between updates
- ✅ **Production Ready**: Systemd service with automatic restart
- ✅ **Zabbix Ready**: Simple UserParameter integration
- ✅ **35x Performance Improvement**: Over naive implementation

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────┐
│                   Easun Inverter                     │
│                    10.1.31.9:8899                    │
└───────────────────┬─────────────────────────────────┘
                    │ TCP Connection (persistent)
                    │ 30s timeout, auto-reconnect
                    │
┌───────────────────▼─────────────────────────────────┐
│          zabbix_monitor.py (daemon)                  │
│  - Maintains persistent connection                   │
│  - Polls every 30s (configurable)                    │
│  - Writes to /tmp/easun_data.json                    │
└───────────────────┬─────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│          /tmp/easun_data.json (cache)                │
│  - Updated every 30s                                 │
│  - Contains all metrics + timestamp                  │
│  - Atomic writes (via temp file)                     │
└───────────────────┬─────────────────────────────────┘
                    │
          ┌─────────┴──────────┐
          │                    │
          ▼                    ▼
┌──────────────────┐  ┌──────────────────┐
│ show_metrics.sh  │  │  easun_query.sh  │
│ (human display)  │  │ (Zabbix queries) │
└──────────────────┘  └──────────────────┘
```

### Connection Lifecycle

1. **Initialization**
   - UDP discovery broadcast to inverter
   - Inverter responds with ACK
   - TCP server starts on local machine
   - Inverter connects back
   - Connection marked as established

2. **Data Polling** (every 30s)
   - Check if connection is still valid
   - If valid: reuse existing connection
   - If stale (>30s idle): reconnect
   - Send bulk register read requests
   - Parse and store data in JSON

3. **Query Mode** (on demand)
   - Read cached data from JSON file
   - Validate freshness (reject if >5 min old)
   - Return requested metric

---

## Installation

### Files Installed

All files are located in `~/easunpy/` on pi@10.0.0.111:

| File | Purpose |
|------|---------|
| `zabbix_monitor.py` | Main monitoring daemon |
| `easun_query.sh` | Query wrapper for Zabbix |
| `show_metrics.sh` | Display all metrics (human-readable) |
| `easun-zabbix-ctl.sh` | Service control script |
| `easun-zabbix.service` | Systemd service definition |
| `ZABBIX_INTEGRATION.md` | Integration guide |

### Quick Installation

```bash
# SSH to the Raspberry Pi
ssh pi@10.0.0.111

# Navigate to the installation directory
cd ~/easunpy

# Install as systemd service
./easun-zabbix-ctl.sh install

# Start the service
./easun-zabbix-ctl.sh start

# Verify it's running
./easun-zabbix-ctl.sh status
```

### Manual Installation

```bash
# Copy service file to systemd
sudo cp ~/easunpy/easun-zabbix.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable easun-zabbix.service

# Start service
sudo systemctl start easun-zabbix.service
```

---

## Usage

### Control Script Commands

The `easun-zabbix-ctl.sh` script provides easy service management:

```bash
# Start the monitor
./easun-zabbix-ctl.sh start

# Stop the monitor
./easun-zabbix-ctl.sh stop

# Restart the monitor
./easun-zabbix-ctl.sh restart

# Check status and last update
./easun-zabbix-ctl.sh status

# View real-time logs
./easun-zabbix-ctl.sh logs

# Display all current metrics
./easun-zabbix-ctl.sh metrics

# Test monitor script manually
./easun-zabbix-ctl.sh test

# Install systemd service
./easun-zabbix-ctl.sh install

# Remove systemd service
./easun-zabbix-ctl.sh uninstall
```

### Direct Script Usage

#### Running the Monitor

```bash
# Run with default settings (30s interval)
./zabbix_monitor.py --inverter-ip 10.1.31.9 --model ISOLAR_SMG_II_6K

# Run with custom interval (60s)
./zabbix_monitor.py --inverter-ip 10.1.31.9 --model ISOLAR_SMG_II_6K --interval 60

# Run with custom data file location
./zabbix_monitor.py --inverter-ip 10.1.31.9 --model ISOLAR_SMG_II_6K --data-file /var/lib/easun/data.json

# Auto-discover inverter IP
./zabbix_monitor.py --discover --model ISOLAR_SMG_II_6K
```

#### Querying Metrics

```bash
# Query a specific metric
./easun_query.sh battery.soc
# Output: 100.0

./easun_query.sh output.power
# Output: 1945.0

./easun_query.sh grid.voltage
# Output: 209.5
```

#### Viewing All Metrics

```bash
# Display all metrics in human-readable format
./show_metrics.sh

# Performance: 0.28 seconds for all 30+ metrics
time ./show_metrics.sh
```

### Systemd Service Management

```bash
# Start service
sudo systemctl start easun-zabbix.service

# Stop service
sudo systemctl stop easun-zabbix.service

# Restart service
sudo systemctl restart easun-zabbix.service

# Check status
sudo systemctl status easun-zabbix.service

# Enable auto-start on boot
sudo systemctl enable easun-zabbix.service

# Disable auto-start
sudo systemctl disable easun-zabbix.service

# View logs
sudo journalctl -u easun-zabbix.service -f
```

---

## Performance

### Benchmark Results

| Metric | Value | Notes |
|--------|-------|-------|
| **Connection Establishment** | ~2-3s | Only on startup or reconnect |
| **Per-Poll Overhead** | ~100-200ms | Reuses existing connection |
| **Query Single Metric** | ~50ms | Reads from cached JSON |
| **Query All Metrics** | **0.28s** | Single Python call |
| **Memory Usage** | ~50-100MB | Python + asyncio overhead |
| **CPU Usage (polling)** | <1% | Between updates |
| **Network Traffic** | ~2-3KB | Per update |

### Performance Comparison

```
Method                          Time      Improvement
────────────────────────────────────────────────────
Original (30+ separate queries)  ~10s     Baseline
With connection reuse            0.28s    35x faster
Single metric query              0.05s    200x faster
```

### Optimization Techniques Used

1. **Persistent Connection Pooling**
   - Single TCP connection reused for all requests
   - 30-second idle timeout with auto-reconnect
   - No UDP discovery overhead after initial connection

2. **Bulk Register Reading**
   - Groups consecutive Modbus registers
   - Reduces number of round-trips
   - Optimized for ISOLAR_SMG_II_6K register map

3. **Atomic File Writes**
   - Write to temp file, then atomic rename
   - Prevents partial reads during updates
   - Ensures data consistency

4. **Efficient JSON Parsing**
   - Single Python process for all metrics
   - In-memory data structure
   - No repeated file I/O

---

## Zabbix Integration

### Method 1: UserParameter (Recommended)

This method allows Zabbix to query cached metrics without connecting to the inverter.

#### Step 1: Configure Zabbix Agent

Create `/etc/zabbix/zabbix_agentd.d/easun.conf`:

```ini
# Easun Inverter Monitoring
UserParameter=easun[*],/home/pi/easunpy/easun_query.sh $1
```

Or add to `/etc/zabbix/zabbix_agentd.conf`:

```ini
UserParameter=easun[*],/home/pi/easunpy/easun_query.sh $1
```

#### Step 2: Restart Zabbix Agent

```bash
sudo systemctl restart zabbix-agent
```

#### Step 3: Test from Zabbix Server

```bash
# Test from Zabbix server
zabbix_get -s 10.0.0.111 -k easun[battery.soc]
zabbix_get -s 10.0.0.111 -k easun[output.power]
zabbix_get -s 10.0.0.111 -k easun[pv.total_power]
```

#### Step 4: Create Zabbix Items

In Zabbix web interface, create items with:

- **Type**: Zabbix agent
- **Key**: `easun[battery.soc]`
- **Type of information**: Numeric (float)
- **Update interval**: 30s (or match monitor interval)

### Method 2: Zabbix Sender (Active Push)

For active pushing of data to Zabbix server.

#### Modify zabbix_monitor.py

Add after line where data is written to JSON:

```python
# Send to Zabbix
import subprocess
for key, value in data.items():
    if key not in ['timestamp', 'status']:
        subprocess.run([
            'zabbix_sender',
            '-z', 'zabbix-server.example.com',
            '-s', 'Easun-Inverter',
            '-k', f'easun.{key}',
            '-o', str(value)
        ])
```

### Method 3: HTTP Endpoint

Add a simple HTTP server to expose metrics (future enhancement).

---

## Available Metrics

### System Metrics

| Key | Description | Unit | Type |
|-----|-------------|------|------|
| `status` | Overall status | 1=OK, 0=Error | Integer |
| `system.mode` | Operating mode name | - | String |
| `system.mode_code` | Operating mode code | - | Integer |
| `system.inverter_time` | Inverter internal time | ISO 8601 | String |
| `timestamp` | Last update time | ISO 8601 | String |

### Battery Metrics

| Key | Description | Unit | Type |
|-----|-------------|------|------|
| `battery.voltage` | Battery voltage | V | Float |
| `battery.current` | Battery current | A | Float |
| `battery.power` | Battery power | W | Float |
| `battery.soc` | State of charge | % | Float |
| `battery.temperature` | Battery temperature | °C | Float |

### Solar (PV) Metrics

| Key | Description | Unit | Type |
|-----|-------------|------|------|
| `pv.total_power` | Total PV power | W | Integer |
| `pv.charging_power` | PV charging power | W | Integer |
| `pv.charging_current` | PV charging current | A | Float |
| `pv1.voltage` | PV1 input voltage | V | Float |
| `pv1.current` | PV1 input current | A | Integer |
| `pv1.power` | PV1 input power | W | Integer |
| `pv2.voltage` | PV2 input voltage | V | Float |
| `pv2.current` | PV2 input current | A | Integer |
| `pv2.power` | PV2 input power | W | Integer |
| `pv.energy_today` | Energy generated today | kWh | Float |
| `pv.energy_total` | Total energy generated | kWh | Float |

### Grid Metrics

| Key | Description | Unit | Type |
|-----|-------------|------|------|
| `grid.voltage` | Grid voltage | V | Float |
| `grid.power` | Grid power | W | Float |
| `grid.frequency` | Grid frequency | Hz | Float |

### Output Metrics

| Key | Description | Unit | Type |
|-----|-------------|------|------|
| `output.voltage` | Output voltage | V | Float |
| `output.current` | Output current | A | Float |
| `output.power` | Output power | W | Float |
| `output.load_percentage` | Load percentage | % | Float |
| `output.frequency` | Output frequency | Hz | Float |

### Example JSON Output

```json
{
  "timestamp": "2026-02-15T21:27:22.103987",
  "status": 1,
  "battery.voltage": 29.2,
  "battery.current": 0.0,
  "battery.power": 0.0,
  "battery.soc": 100.0,
  "battery.temperature": 18.0,
  "pv.total_power": 0,
  "pv.charging_power": 0,
  "pv.charging_current": 0,
  "pv1.voltage": 31.9,
  "pv1.current": 0,
  "pv1.power": 0,
  "pv2.voltage": 0,
  "pv2.current": 0,
  "pv2.power": 0,
  "pv.energy_today": 0,
  "pv.energy_total": 0,
  "grid.voltage": 209.5,
  "grid.power": 923.0,
  "grid.frequency": 50.0,
  "output.voltage": 210.1,
  "output.current": 3.9,
  "output.power": 817.0,
  "output.load_percentage": 0.19,
  "output.frequency": 49.99,
  "system.mode": "SUB",
  "system.mode_code": 2
}
```

---

## Troubleshooting

### Service Won't Start

**Symptoms**: Service fails to start, immediate exit

**Diagnosis**:
```bash
# Check service status
sudo systemctl status easun-zabbix.service

# View recent logs
sudo journalctl -u easun-zabbix.service -n 50
```

**Common Causes**:
1. **Inverter not reachable**
   ```bash
   ping 10.1.31.9
   ```

2. **Port already in use**
   ```bash
   # Check if port 8899 is in use
   sudo netstat -tulpn | grep 8899
   ```

3. **Python dependencies missing**
   ```bash
   python3.10 -c "import asyncio; from easunpy.async_isolar import AsyncISolar"
   ```

**Solutions**:
- Verify inverter IP and network connectivity
- Stop other services using port 8899
- Reinstall dependencies: `cd ~/easunpy && python3.10 -m pip install -e .`

### No Data in JSON File

**Symptoms**: `/tmp/easun_data.json` doesn't exist or is empty

**Diagnosis**:
```bash
# Check if file exists
ls -lh /tmp/easun_data.json

# Check service status
./easun-zabbix-ctl.sh status

# View logs
./easun-zabbix-ctl.sh logs
```

**Common Causes**:
1. Service not running
2. Connection to inverter failed
3. Permissions issue

**Solutions**:
```bash
# Restart service
./easun-zabbix-ctl.sh restart

# Test manually
./easun-zabbix-ctl.sh test

# Check file permissions
ls -la /tmp/easun_data.json
```

### Old Data (Timestamp > 5 Minutes)

**Symptoms**: Queries return `ZBX_NOTSUPPORTED`

**Diagnosis**:
```bash
# Check data freshness
cat /tmp/easun_data.json | grep timestamp

# Check service status
sudo systemctl status easun-zabbix.service
```

**Common Causes**:
1. Service crashed or stopped
2. Connection to inverter lost
3. Network issues

**Solutions**:
```bash
# Check logs for errors
sudo journalctl -u easun-zabbix.service -n 100

# Restart service
./easun-zabbix-ctl.sh restart

# Verify network connectivity
ping 10.1.31.9
```

### Connection Timeouts

**Symptoms**: Logs show repeated connection failures

**Diagnosis**:
```bash
# View logs
tail -f /tmp/easun_zabbix.log

# Check network
ping 10.1.31.9
traceroute 10.1.31.9
```

**Common Causes**:
1. Inverter powered off or disconnected
2. Network configuration changed
3. Firewall blocking UDP/TCP
4. Inverter already connected to another client

**Solutions**:
- Verify inverter is powered on and connected
- Check network configuration (subnet, gateway)
- Verify firewall rules allow UDP 58899 and TCP 8899
- Stop other monitoring tools that might hold the connection

### High Memory Usage

**Symptoms**: Process using >200MB RAM

**Diagnosis**:
```bash
# Check memory usage
ps aux | grep zabbix_monitor

# Check for memory leaks
sudo systemctl restart easun-zabbix.service
# Wait 1 hour and check again
```

**Solutions**:
- Increase update interval to reduce activity
- Monitor for memory leaks over time
- Restart service daily via cron if needed

### Slow Query Performance

**Symptoms**: `show_metrics.sh` takes >1 second

**Diagnosis**:
```bash
# Benchmark script
time ./show_metrics.sh

# Check if Python is used
head -1 $(which python3)
```

**Solutions**:
- Ensure Python 3 is installed
- Check for disk I/O issues
- Verify /tmp is not full

---

## Technical Details

### Connection Protocol

#### UDP Discovery (Port 58899)
```
Client → Inverter: "set>server=10.0.0.111:8899;"
Inverter → Client: ACK
```

#### TCP Connection (Port 8899)
```
Client: Start TCP server on 10.0.0.111:8899
Inverter: Connect to 10.0.0.111:8899
Client: Accept connection, mark as established
```

#### Modbus TCP Requests
```
Transaction ID: Auto-incrementing (0x0772 + N)
Protocol ID: 0x0001
Unit ID: 0x00
Function Code: 0x03 (Read Holding Registers)
```

### Register Groups

The monitor reads registers in optimized groups to minimize round-trips:

```python
# Example register groups for ISOLAR_SMG_II_6K
groups = [
    (15200, 25),  # Battery, Grid, Output
    (15230, 15),  # PV data
    (15300, 6),   # System time
    (15400, 1),   # Operating mode
]
```

### Data Flow

1. **Monitor Process**
   ```
   AsyncISolar.get_all_data()
     → AsyncModbusClient.send_bulk()
       → Check connection (_ensure_connection)
       → Send register read requests
       → Parse responses
       → Build data objects
     → Flatten to dictionary
     → Write to JSON atomically
   ```

2. **Query Process**
   ```
   easun_query.sh
     → Call zabbix_monitor.py --query
       → Read JSON file
       → Check timestamp freshness
       → Return value or ZBX_NOTSUPPORTED
   ```

### File Locations

| File | Path | Purpose |
|------|------|---------|
| Monitor script | `/home/pi/easunpy/zabbix_monitor.py` | Main daemon |
| Data file | `/tmp/easun_data.json` | Cached metrics |
| Log file | `/tmp/easun_zabbix.log` | Application logs |
| Service file | `/etc/systemd/system/easun-zabbix.service` | Systemd unit |
| PID file | Auto-managed by systemd | Process tracking |

### Systemd Service Configuration

```ini
[Unit]
Description=Easun Inverter Zabbix Monitor
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/easunpy
ExecStart=/usr/bin/python3.10 /home/pi/easunpy/zabbix_monitor.py \
          --inverter-ip 10.1.31.9 \
          --model ISOLAR_SMG_II_6K \
          --interval 30
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Configuration Options

All options can be customized in the service file or command line:

| Option | Default | Description |
|--------|---------|-------------|
| `--inverter-ip` | Required | Inverter IP address |
| `--local-ip` | Auto-detect | Local interface IP |
| `--model` | ISOLAR_SMG_II_6K | Inverter model |
| `--interval` | 30 | Update interval (seconds) |
| `--data-file` | /tmp/easun_data.json | Data file path |
| `--discover` | False | Auto-discover inverter |

---

## Maintenance

### Daily Tasks
- None required (automatic operation)

### Weekly Tasks
```bash
# Check service health
./easun-zabbix-ctl.sh status

# Verify data freshness
cat /tmp/easun_data.json | grep timestamp
```

### Monthly Tasks
```bash
# Review logs for errors
sudo journalctl -u easun-zabbix.service --since "1 month ago" | grep -i error

# Check disk space
df -h /tmp

# Review system performance
top -b -n 1 | grep zabbix_monitor
```

### Log Rotation

Logs are automatically managed by systemd journal. To adjust retention:

```bash
# Edit journald config
sudo nano /etc/systemd/journald.conf

# Set limits
SystemMaxUse=100M
MaxFileSec=1month

# Restart journald
sudo systemctl restart systemd-journald
```

### Backup and Restore

**Backup**:
```bash
# Backup all files
tar -czf easun-zabbix-backup.tar.gz \
    ~/easunpy/zabbix_monitor.py \
    ~/easunpy/easun_query.sh \
    ~/easunpy/show_metrics.sh \
    ~/easunpy/easun-zabbix-ctl.sh \
    ~/easunpy/easun-zabbix.service \
    ~/easunpy/*.md
```

**Restore**:
```bash
# Extract files
tar -xzf easun-zabbix-backup.tar.gz -C ~/

# Reinstall service
cd ~/easunpy
./easun-zabbix-ctl.sh install
./easun-zabbix-ctl.sh start
```

---

## Support

### Logs and Debugging

Enable debug mode by editing the service file:

```bash
sudo nano /etc/systemd/system/easun-zabbix.service
```

Add `--debug` flag:
```ini
ExecStart=/usr/bin/python3.10 /home/pi/easunpy/zabbix_monitor.py \
          --inverter-ip 10.1.31.9 \
          --model ISOLAR_SMG_II_6K \
          --interval 30 \
          --debug
```

Then restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart easun-zabbix.service
```

### Getting Help

1. Check logs: `./easun-zabbix-ctl.sh logs`
2. Test manually: `./easun-zabbix-ctl.sh test`
3. Review this documentation
4. Check network connectivity
5. Verify inverter is powered on

---

## License and Credits

- **EasunPy Library**: Original inverter communication library
- **Monitor Implementation**: Custom Zabbix integration
- **Python**: 3.10+
- **Platform**: Raspberry Pi OS (Debian-based)

---

**Document Version**: 1.0
**Last Updated**: 2026-02-15
**Inverter Model**: ISOLAR SMG II 6K
**System**: Raspberry Pi @ 10.0.0.111
