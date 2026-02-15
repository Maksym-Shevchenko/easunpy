# Zabbix Quick Setup Guide - Easun Inverter

**Quick Reference**: Step-by-step checklist for adding inverter monitoring to Zabbix

> **Note**: Replace `AGENT_HOST_IP` with your agent host IP address throughout this guide.

---

## ☑️ Pre-Setup Checklist

### On Agent Host

```bash
# 1. Verify monitor is running
sudo systemctl status easun-zabbix.service
# Status: active (running) ✅

# 2. Check data is being collected
cat /tmp/easun_data.json | grep timestamp
# Should show recent timestamp ✅

# 3. Test query script
~/easunpy/easun_query.sh battery.soc
# Should return a number (e.g., 100.0) ✅
```

### Install Zabbix Agent (if not installed)

```bash
# Install agent
sudo apt-get update && sudo apt-get install -y zabbix-agent

# Configure server connection
sudo nano /etc/zabbix/zabbix_agentd.conf
```

Edit these lines:
```ini
Server=YOUR_ZABBIX_SERVER_IP
ServerActive=YOUR_ZABBIX_SERVER_IP
Hostname=Easun-Inverter
```

### Configure UserParameter

```bash
# Create config file
sudo nano /etc/zabbix/zabbix_agentd.d/easun.conf
```

Add:
```ini
UserParameter=easun[*],/home/pi/easunpy/easun_query.sh $1
```

### Restart Agent

```bash
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
```

### Test from Zabbix Server

```bash
zabbix_get -s AGENT_HOST_IP -k easun[battery.soc]
# Expected: 100.0 (or current value)
```

---

## 📋 Zabbix Web Interface Setup

### Step 1: Create Host (5 min)

**Navigate**: Configuration → Hosts → Create host

**Settings**:
- Host name: `Easun-Inverter`
- Groups: `Energy/Inverters` (create if needed)
- Interface: Agent, IP: `AGENT_HOST_IP`, Port: `10050`

**Click**: Add

---

### Step 2: Create Items (15 min)

**Navigate**: Configuration → Hosts → Easun-Inverter → Items → Create item

**Essential Items** (create these first):

#### 1. Battery SOC ⚡
- Name: `Battery State of Charge`
- Key: `easun[battery.soc]`
- Type: Numeric (float)
- Units: `%`
- Interval: `30s`

#### 2. Output Power 🔌
- Name: `Output Power`
- Key: `easun[output.power]`
- Type: Numeric (float)
- Units: `W`
- Interval: `30s`

#### 3. PV Power ☀️
- Name: `PV Total Power`
- Key: `easun[pv.total_power]`
- Type: Numeric (unsigned)
- Units: `W`
- Interval: `30s`

#### 4. Grid Voltage ⚡
- Name: `Grid Voltage`
- Key: `easun[grid.voltage]`
- Type: Numeric (float)
- Units: `V`
- Interval: `30s`

#### 5. Output Load 📊
- Name: `Output Load Percentage`
- Key: `easun[output.load_percentage]`
- Type: Numeric (float)
- Units: `%`
- Interval: `30s`

**See full guide for all 20+ items**

---

### Step 3: Create Triggers (10 min)

**Navigate**: Configuration → Hosts → Easun-Inverter → Triggers → Create trigger

#### 🔴 Critical: Battery Low
- Name: `Battery low (SOC < 20%)`
- Severity: High
- Expression: `{Easun-Inverter:easun[battery.soc].last()}<20`

#### 🔴 Critical: Monitor Down
- Name: `Inverter monitor service is down`
- Severity: High
- Expression: `{Easun-Inverter:easun[status].last()}=0`

#### 🟡 Warning: Overload
- Name: `Output overload (>90%)`
- Severity: Average
- Expression: `{Easun-Inverter:easun[output.load_percentage].last()}>90`

#### 🟡 Warning: Grid Voltage
- Name: `Grid voltage abnormal`
- Severity: Warning
- Expression: Complex (see full guide)

---

### Step 4: Create Graphs (10 min)

**Navigate**: Configuration → Hosts → Easun-Inverter → Graphs → Create graph

#### Graph 1: Power Flow
- Name: `Power Flow`
- Items: PV Power (gold), Grid Power (blue), Output Power (red), Battery Power (green)

#### Graph 2: Battery Status
- Name: `Battery Status`
- Items: Battery SOC (green), Battery Temperature (orange)

#### Graph 3: Voltage
- Name: `Voltage Status`
- Items: Battery, Grid, Output, PV1 voltages

---

### Step 5: Create Dashboard (10 min)

**Navigate**: Monitoring → Dashboards → Create dashboard

**Name**: `Easun Inverter Overview`

**Widgets to add**:
1. **Item value** - Current Status (SOC, Power, Voltage)
2. **Graph** - Power Flow (24h)
3. **Graph** - Battery Status (12h)
4. **Problems** - Active alerts
5. **Plain text** - System info

---

## 🧪 Testing Checklist

### Verify Items
```
Monitoring → Latest data → Host: Easun-Inverter
✅ All items show values
✅ Values update every 30s
✅ No "Not supported" errors
```

### Verify Triggers
```
Monitoring → Problems
✅ No false alerts
✅ Can manually test by modifying values
```

### Verify Graphs
```
Monitoring → Graphs → Easun-Inverter
✅ Graphs display correctly
✅ Data points visible
```

### Verify Dashboard
```
Monitoring → Dashboards → Easun Inverter Overview
✅ All widgets load
✅ Data is current
```

---

## 📊 Item Quick Reference

Copy/paste values for quick item creation:

| Key | Name | Type | Units |
|-----|------|------|-------|
| `easun[battery.soc]` | Battery State of Charge | Float | % |
| `easun[battery.voltage]` | Battery Voltage | Float | V |
| `easun[battery.current]` | Battery Current | Float | A |
| `easun[battery.power]` | Battery Power | Float | W |
| `easun[battery.temperature]` | Battery Temperature | Float | °C |
| `easun[pv.total_power]` | PV Total Power | Unsigned | W |
| `easun[pv.charging_power]` | PV Charging Power | Unsigned | W |
| `easun[pv.charging_current]` | PV Charging Current | Float | A |
| `easun[pv1.voltage]` | PV1 Voltage | Float | V |
| `easun[pv1.current]` | PV1 Current | Float | A |
| `easun[pv1.power]` | PV1 Power | Unsigned | W |
| `easun[pv2.voltage]` | PV2 Voltage | Float | V |
| `easun[pv2.current]` | PV2 Current | Unsigned | A |
| `easun[pv2.power]` | PV2 Power | Unsigned | W |
| `easun[pv.energy_today]` | PV Energy Today | Float | kWh |
| `easun[pv.energy_total]` | PV Energy Total | Float | kWh |
| `easun[grid.voltage]` | Grid Voltage | Float | V |
| `easun[grid.power]` | Grid Power | Float | W |
| `easun[grid.frequency]` | Grid Frequency | Float | Hz |
| `easun[output.voltage]` | Output Voltage | Float | V |
| `easun[output.current]` | Output Current | Float | A |
| `easun[output.power]` | Output Power | Float | W |
| `easun[output.load_percentage]` | Output Load % | Float | % |
| `easun[output.frequency]` | Output Frequency | Float | Hz |
| `easun[system.mode]` | Operating Mode | Text | - |
| `easun[system.mode_code]` | Operating Mode Code | Unsigned | - |
| `easun[status]` | Monitor Status | Unsigned | - |

**All items**: Update interval `30s`, History `90d`, Trends `365d`

---

## 🔧 Troubleshooting

### Items show "Not supported"

```bash
# Test from server
zabbix_get -s AGENT_HOST_IP -k easun[battery.soc]

# Test on agent
sudo zabbix_agentd -t easun[battery.soc]

# Check agent logs
sudo tail -f /var/log/zabbix/zabbix_agentd.log
```

### No data appearing

```bash
# 1. Check monitor service
sudo systemctl status easun-zabbix.service

# 2. Check data file
cat /tmp/easun_data.json

# 3. Check agent connectivity
zabbix_get -s AGENT_HOST_IP -k agent.ping
```

### Agent not connecting

```bash
# Check agent is running
sudo systemctl status zabbix-agent

# Check firewall
sudo ufw status
sudo ufw allow from ZABBIX_SERVER_IP to any port 10050

# Check port is listening
sudo netstat -tulpn | grep 10050
```

---

## ⏱️ Time Estimate

- **Prerequisites**: 10 minutes
- **Host creation**: 5 minutes
- **Items (20+)**: 20-30 minutes
- **Triggers (8+)**: 15 minutes
- **Graphs (3+)**: 15 minutes
- **Dashboard**: 10 minutes
- **Testing**: 10 minutes

**Total**: ~90 minutes for complete setup

---

## 📖 Full Documentation

For detailed information, see:
- **ZABBIX_WEB_INTERFACE_GUIDE.md** - Complete step-by-step guide
- **ZABBIX_INTEGRATION.md** - Integration details
- **README.md** - System overview

---

## ✅ Final Checklist

After setup, verify:

- [ ] Host shows ZBX icon (green)
- [ ] All items collecting data
- [ ] No "Not supported" items
- [ ] Triggers configured and enabled
- [ ] Graphs displaying correctly
- [ ] Dashboard widgets working
- [ ] Test notifications (optional)

**Status**: Ready for production monitoring! 🎉

---

**Created**: 2026-02-15
**System**: Easun ISOLAR SMG II 4K
**Platform**: Linux with Zabbix agent
