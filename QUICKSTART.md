# Easun Inverter Zabbix Monitor - Quick Start Guide

## 🚀 Quick Start (5 Minutes)

```bash
# 1. SSH to Raspberry Pi
ssh pi@10.0.0.111

# 2. Navigate to installation
cd ~/easunpy

# 3. Install and start service
./easun-zabbix-ctl.sh install
./easun-zabbix-ctl.sh start

# 4. Verify it's working
./easun-zabbix-ctl.sh status
./show_metrics.sh
```

## 📊 Common Commands

### Service Management
```bash
./easun-zabbix-ctl.sh start     # Start monitoring
./easun-zabbix-ctl.sh stop      # Stop monitoring
./easun-zabbix-ctl.sh restart   # Restart service
./easun-zabbix-ctl.sh status    # Check status
./easun-zabbix-ctl.sh logs      # View logs
./easun-zabbix-ctl.sh metrics   # Show all metrics
```

### Query Individual Metrics
```bash
./easun_query.sh battery.soc           # Battery state of charge
./easun_query.sh output.power          # Output power
./easun_query.sh pv.total_power        # Solar power
./easun_query.sh grid.voltage          # Grid voltage
```

## 🔍 Quick Diagnostics

### Check if Running
```bash
sudo systemctl status easun-zabbix.service
```

### View Recent Logs
```bash
sudo journalctl -u easun-zabbix.service -n 20
```

### Check Data File
```bash
cat /tmp/easun_data.json
```

### Test Connection
```bash
ping 10.1.31.9
```

## 📈 Key Metrics Categories

### Battery
- `battery.soc` - State of charge (%)
- `battery.voltage` - Voltage (V)
- `battery.power` - Power (W)
- `battery.temperature` - Temperature (°C)

### Solar (PV)
- `pv.total_power` - Total power (W)
- `pv1.power` - PV1 power (W)
- `pv.energy_today` - Today's generation (kWh)
- `pv.energy_total` - Total generation (kWh)

### Grid
- `grid.voltage` - Voltage (V)
- `grid.power` - Power (W)
- `grid.frequency` - Frequency (Hz)

### Output
- `output.power` - Output power (W)
- `output.load_percentage` - Load (%)
- `output.voltage` - Voltage (V)

## 🔧 Common Issues

### Service Not Running
```bash
./easun-zabbix-ctl.sh restart
./easun-zabbix-ctl.sh logs
```

### Old Data
```bash
# Check timestamp
cat /tmp/easun_data.json | grep timestamp

# Restart service
./easun-zabbix-ctl.sh restart
```

### Connection Issues
```bash
# Test network
ping 10.1.31.9

# Check if port is available
sudo netstat -tulpn | grep 8899

# Restart service
./easun-zabbix-ctl.sh restart
```

## 🎯 Performance Benchmarks

- **Connection**: Persistent (established once, reused)
- **Update Interval**: 30 seconds
- **Query Time**: 0.05s (single metric)
- **Display All**: 0.28s (30+ metrics)
- **Memory**: ~50MB
- **CPU**: <1% idle

## 📝 Zabbix Integration (Quick)

### 1. Add UserParameter
Edit `/etc/zabbix/zabbix_agentd.conf`:
```ini
UserParameter=easun[*],/home/pi/easunpy/easun_query.sh $1
```

### 2. Restart Agent
```bash
sudo systemctl restart zabbix-agent
```

### 3. Test from Zabbix Server
```bash
zabbix_get -s 10.0.0.111 -k easun[battery.soc]
```

### 4. Create Items in Zabbix
- Key: `easun[battery.soc]`
- Type: Numeric (float)
- Interval: 30s

## 📂 Important Files

| File | Location |
|------|----------|
| Data file | `/tmp/easun_data.json` |
| Log file | `/tmp/easun_zabbix.log` |
| Service file | `/etc/systemd/system/easun-zabbix.service` |

## 🆘 Need Help?

1. Check logs: `./easun-zabbix-ctl.sh logs`
2. Review full documentation: `cat EASUN_ZABBIX_DOCUMENTATION.md`
3. Test manually: `./easun-zabbix-ctl.sh test`

## ⚡ System Architecture

```
Inverter (10.1.31.9)
    ↓ [Persistent TCP Connection]
Monitor Daemon (zabbix_monitor.py)
    ↓ [Updates every 30s]
JSON Cache (/tmp/easun_data.json)
    ↓ [Read on demand]
Queries (easun_query.sh) → Zabbix
```

## ✅ Success Indicators

- ✓ Service status: `active (running)`
- ✓ Data file exists and updates every 30s
- ✓ Logs show "Updated data: Battery X%, PV XW, Output XW"
- ✓ Queries return numeric values (not ZBX_NOTSUPPORTED)
- ✓ `show_metrics.sh` displays current values

---

**For detailed information, see: EASUN_ZABBIX_DOCUMENTATION.md**
