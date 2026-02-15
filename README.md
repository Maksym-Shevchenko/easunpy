# Easun Inverter Monitoring System

Complete monitoring solution for Easun ISOLAR inverters with Zabbix integration.

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[EASUN_ZABBIX_DOCUMENTATION.md](EASUN_ZABBIX_DOCUMENTATION.md)** - Complete technical documentation
- **[ZABBIX_INTEGRATION.md](ZABBIX_INTEGRATION.md)** - Zabbix integration guide

## 🎯 What's This?

A high-performance monitoring daemon that:
- Maintains a **persistent connection** to your Easun inverter
- Collects **30+ metrics** every 30 seconds
- Stores data in JSON format for easy access
- Provides **Zabbix-ready** query interface
- Runs as a systemd service with auto-restart

## ⚡ Key Features

| Feature | Details |
|---------|---------|
| **Performance** | 35x faster than naive implementation |
| **Connection** | Persistent TCP, auto-reconnect on failure |
| **Metrics** | Battery, PV, Grid, Output, System status |
| **Query Speed** | 0.05s per metric, 0.28s for all 30+ metrics |
| **Resource Usage** | ~50MB RAM, <1% CPU |
| **Reliability** | Systemd service with automatic restart |

## 🚀 Quick Start

```bash
cd ~/easunpy
./easun-zabbix-ctl.sh install
./easun-zabbix-ctl.sh start
./show_metrics.sh
```

See [QUICKSTART.md](QUICKSTART.md) for details.

## 📦 What's Included

### Core Scripts
- **`zabbix_monitor.py`** - Main monitoring daemon (persistent connection)
- **`easun_query.sh`** - Query wrapper for Zabbix UserParameters
- **`show_metrics.sh`** - Display all metrics in human-readable format (optimized, 0.28s)

### Management Tools
- **`easun-zabbix-ctl.sh`** - Service control script (start/stop/status/logs)
- **`easun-zabbix.service`** - Systemd service definition

### Additional Tools
- **`monitor.sh`** - Original monitoring script (continuous display mode)

### Documentation
- **`README.md`** - This file
- **`QUICKSTART.md`** - Quick start guide
- **`EASUN_ZABBIX_DOCUMENTATION.md`** - Complete documentation
- **`ZABBIX_INTEGRATION.md`** - Zabbix integration guide

## 📊 Available Metrics

30+ metrics across 5 categories:

### Battery (5 metrics)
- Voltage, Current, Power, SOC, Temperature

### Solar/PV (11 metrics)
- Total power, PV1/PV2 voltage/current/power, daily/total generation

### Grid (3 metrics)
- Voltage, Power, Frequency

### Output (5 metrics)
- Voltage, Current, Power, Load %, Frequency

### System (5 metrics)
- Operating mode, Status, Timestamps

## 🔧 Common Commands

```bash
# Service management
./easun-zabbix-ctl.sh start|stop|restart|status|logs|metrics

# View all metrics (fast!)
./show_metrics.sh

# Query specific metric
./easun_query.sh battery.soc
./easun_query.sh output.power
```

## 📈 Performance

```
Metric Collection:    Every 30s (configurable)
Connection Overhead:  ~2-3s (only on startup)
Per-Poll Time:        ~100-200ms (reuses connection)
Single Query:         0.05s
All Metrics Display:  0.28s
Memory Usage:         ~50MB
CPU Usage:            <1% (idle)
```

**35x performance improvement** over naive implementation!

## 🏗️ Architecture

```
┌─────────────────────┐
│  Easun Inverter     │  10.1.31.9:8899
│  ISOLAR SMG II 6K   │
└──────────┬──────────┘
           │ Persistent TCP Connection
           │ (auto-reconnect on failure)
           ↓
┌─────────────────────┐
│ zabbix_monitor.py   │  Python daemon
│ (Runs as service)   │  Updates every 30s
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ /tmp/easun_data.json│  Cached metrics
│ (atomic writes)     │  Timestamp validation
└──────────┬──────────┘
           │
      ┌────┴────┐
      ↓         ↓
┌──────────┐ ┌──────────┐
│ Zabbix   │ │  Human   │
│ Queries  │ │  Display │
└──────────┘ └──────────┘
```

## 🔌 Zabbix Integration

### UserParameter Method (Recommended)

**1. Configure Zabbix Agent:**
```ini
# /etc/zabbix/zabbix_agentd.conf or zabbix_agentd.d/easun.conf
UserParameter=easun[*],/home/pi/easunpy/easun_query.sh $1
```

**2. Restart Agent:**
```bash
sudo systemctl restart zabbix-agent
```

**3. Test:**
```bash
zabbix_get -s 10.0.0.111 -k easun[battery.soc]
```

**4. Create Zabbix Items:**
- Key: `easun[battery.soc]`
- Type: Numeric (float)
- Interval: 30s

See [ZABBIX_INTEGRATION.md](ZABBIX_INTEGRATION.md) for complete setup.

## 🛠️ Configuration

Edit service file to customize:

```bash
sudo nano /etc/systemd/system/easun-zabbix.service
```

Available options:
- `--inverter-ip` - Inverter IP address (required)
- `--model` - Inverter model (default: ISOLAR_SMG_II_6K)
- `--interval` - Update interval in seconds (default: 30)
- `--data-file` - JSON cache location (default: /tmp/easun_data.json)
- `--local-ip` - Local interface IP (auto-detected)

After changes:
```bash
sudo systemctl daemon-reload
sudo systemctl restart easun-zabbix.service
```

## 🐛 Troubleshooting

### Service Not Running
```bash
sudo systemctl status easun-zabbix.service
sudo journalctl -u easun-zabbix.service -n 50
```

### Old or Missing Data
```bash
cat /tmp/easun_data.json
./easun-zabbix-ctl.sh restart
```

### Connection Issues
```bash
ping 10.1.31.9
./easun-zabbix-ctl.sh logs
```

See [EASUN_ZABBIX_DOCUMENTATION.md](EASUN_ZABBIX_DOCUMENTATION.md) for detailed troubleshooting.

## 📁 File Locations

| File | Path |
|------|------|
| Scripts | `~/easunpy/` |
| Data cache | `/tmp/easun_data.json` |
| Application log | `/tmp/easun_zabbix.log` |
| Service file | `/etc/systemd/system/easun-zabbix.service` |
| Systemd logs | `journalctl -u easun-zabbix.service` |

## 🔄 Updates and Maintenance

### Check Service Health
```bash
./easun-zabbix-ctl.sh status
```

### View Logs
```bash
./easun-zabbix-ctl.sh logs
```

### Update Configuration
```bash
sudo nano /etc/systemd/system/easun-zabbix.service
sudo systemctl daemon-reload
./easun-zabbix-ctl.sh restart
```

## 📊 Example Output

### show_metrics.sh
```
=== Easun Inverter Metrics ===

System Status:
Status                        : 1 (1=OK, 0=Error)
Operating Mode                : SUB
Last Update                   : 2026-02-15T21:27:22.103987

Battery:
Voltage                       : 29.2 V
Current                       : 0.0 A
Power                         : 0.0 W
State of Charge               : 100.0 %
Temperature                   : 18.0 °C

Solar (PV):
Total Power                   : 0 W
...

real    0m0.281s
```

### easun_query.sh
```bash
$ ./easun_query.sh battery.soc
100.0

$ ./easun_query.sh output.power
1945.0
```

## 🎯 Use Cases

1. **Zabbix Monitoring** - Track inverter performance over time
2. **Alerting** - Get notified of battery low, grid failures, etc.
3. **Energy Analytics** - Analyze solar generation patterns
4. **System Integration** - JSON API for custom applications
5. **Dashboard Display** - Real-time inverter status

## ⚠️ Important Notes

- **Persistent Connection**: Connects once, reuses connection for efficiency
- **Auto-Reconnect**: Handles network issues and inverter restarts
- **Data Freshness**: Queries reject data older than 5 minutes
- **Atomic Writes**: JSON file updated atomically (no partial reads)
- **Resource Efficient**: Minimal CPU and memory usage

## 🔐 Security

- Runs as user `pi` (not root)
- Local network communication only
- No authentication required (local subnet trust)
- Systemd service isolation

For production deployments, consider:
- Firewall rules
- VPN/tunnel for remote access
- Zabbix encryption

## 📜 Version History

- **v1.0** (2026-02-15)
  - Initial release
  - Persistent connection implementation
  - Zabbix UserParameter support
  - 35x performance optimization
  - Complete documentation

## 🤝 Support

1. Read documentation (QUICKSTART.md, EASUN_ZABBIX_DOCUMENTATION.md)
2. Check logs: `./easun-zabbix-ctl.sh logs`
3. Test manually: `./easun-zabbix-ctl.sh test`
4. Verify network: `ping 10.1.31.9`

## 📄 License

This monitoring system integrates with the EasunPy library for communication with Easun inverters.

---

**System Information:**
- **Inverter**: Easun ISOLAR SMG II 6K
- **Location**: pi@10.0.0.111
- **Platform**: Raspberry Pi (Debian/Raspbian)
- **Python**: 3.10+
- **Installation Date**: 2026-02-15

**Quick Links:**
- [Get Started](QUICKSTART.md) - 5 minute setup
- [Full Documentation](EASUN_ZABBIX_DOCUMENTATION.md) - Complete guide
- [Zabbix Setup](ZABBIX_INTEGRATION.md) - Integration instructions
