# Zabbix Web Interface Configuration Guide
## Easun Inverter Monitoring Setup

**Version**: 1.0
**Date**: 2026-02-15
**Inverter**: Easun ISOLAR SMG II 4K
**Target Platform**: Any Linux host with Zabbix agent

> **Note**: Throughout this guide, replace `AGENT_HOST_IP` with your actual agent host IP address (e.g., 192.168.1.100).

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Step 1: Configure Zabbix Agent](#step-1-configure-zabbix-agent)
3. [Step 2: Create Host](#step-2-create-host)
4. [Step 3: Create Items](#step-3-create-items)
5. [Step 4: Create Triggers](#step-4-create-triggers)
6. [Step 5: Create Graphs](#step-5-create-graphs)
7. [Step 6: Create Dashboard](#step-6-create-dashboard)
8. [Step 7: Testing](#step-7-testing)
9. [Appendix: All Items Reference](#appendix-all-items-reference)

---

## Prerequisites

### On Agent Host (Already Completed)

✅ Monitor service running:
```bash
sudo systemctl status easun-zabbix.service
```

✅ Data being collected:
```bash
cat /tmp/easun_data.json
```

✅ Query script working:
```bash
~/easunpy/easun_query.sh battery.soc
```

### On Agent Host (To Be Done)

#### Install Zabbix Agent

```bash
# Install Zabbix agent
sudo apt-get update
sudo apt-get install zabbix-agent

# Configure agent
sudo nano /etc/zabbix/zabbix_agentd.conf
```

#### Configure Zabbix Agent

Edit `/etc/zabbix/zabbix_agentd.conf`:

```ini
# Server configuration
Server=YOUR_ZABBIX_SERVER_IP
ServerActive=YOUR_ZABBIX_SERVER_IP

# Agent hostname (must match Zabbix web interface)
Hostname=Easun-Inverter

# Enable UserParameters
Include=/etc/zabbix/zabbix_agentd.d/*.conf
```

#### Create UserParameter Configuration

Create file `/etc/zabbix/zabbix_agentd.d/easun.conf`:

```bash
sudo nano /etc/zabbix/zabbix_agentd.d/easun.conf
```

Add this content:

```ini
# Easun Inverter Monitoring
# Query individual metrics from cached JSON data
UserParameter=easun[*],/home/pi/easunpy/easun_query.sh $1

# Discovery rule for all available metrics (optional)
UserParameter=easun.discovery,/home/pi/easunpy/easun_discovery.sh
```

#### Restart Zabbix Agent

```bash
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
sudo systemctl status zabbix-agent
```

#### Test from Zabbix Server

From your Zabbix server, test the connection:

```bash
zabbix_get -s AGENT_HOST_IP -k easun[battery.soc]
# Expected output: 100.0

zabbix_get -s AGENT_HOST_IP -k easun[output.power]
# Expected output: 767.0
```

---

## Step 1: Configure Zabbix Agent

### 1.1 Verify Agent Configuration

On Zabbix agent host:

```bash
# Check agent is running
sudo systemctl status zabbix-agent

# Check configuration
sudo zabbix_agentd -t easun[battery.soc]
# Expected: easun[battery.soc] [t|100.0]
```

### 1.2 Check Firewall

Ensure port 10050 (Zabbix agent) is open:

```bash
# Check if port is listening
sudo netstat -tulpn | grep 10050

# If using firewall, allow Zabbix server
sudo ufw allow from YOUR_ZABBIX_SERVER_IP to any port 10050
```

---

## Step 2: Create Host

### 2.1 Navigate to Hosts

1. Log in to Zabbix web interface
2. Go to **Configuration** → **Hosts**
3. Click **Create host** button (top right)

### 2.2 Host Configuration

#### Host Tab

Fill in the following fields:

| Field | Value | Notes |
|-------|-------|-------|
| **Host name** | `Easun-Inverter` | Must match agent's Hostname setting |
| **Visible name** | `Easun Inverter (ISOLAR 4K)` | Display name in UI |
| **Groups** | `Energy/Inverters` | Create new group if needed |
| **Interfaces** | Agent: `AGENT_HOST_IP:10050` | Add Agent interface |
| **Description** | `Easun ISOLAR SMG II 4K inverter monitoring` | Optional |
| **Monitored by proxy** | (no proxy) | Leave empty |
| **Enabled** | ✅ Checked | Enable monitoring |

#### Interfaces Section

Click **Add** and configure Agent interface:

| Field | Value |
|-------|-------|
| Type | Agent |
| IP address | AGENT_HOST_IP |
| DNS name | (leave empty) |
| Connect to | IP |
| Port | 10050 |
| Default | ✅ Checked |

### 2.3 Save Host

Click **Add** button at the bottom to create the host.

**Result**: Host "Easun-Inverter" appears in the host list with ZBX icon (green = connected, red = not connected).

---

## Step 3: Create Items

Items are individual metrics collected from the inverter.

### 3.1 Navigate to Items

1. Go to **Configuration** → **Hosts**
2. Find **Easun-Inverter** host
3. Click **Items** (in the row)
4. Click **Create item** button

### 3.2 Create Battery SOC Item (Example)

This is a detailed example. For other items, see the [Items Reference](#appendix-all-items-reference).

#### Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Name** | `Battery State of Charge` | Display name |
| **Type** | `Zabbix agent` | Agent-based check |
| **Key** | `easun[battery.soc]` | UserParameter key |
| **Type of information** | `Numeric (float)` | Data type |
| **Units** | `%` | Percentage |
| **Update interval** | `30s` | Match monitor interval |
| **History storage period** | `90d` | Keep 90 days of history |
| **Trend storage period** | `365d` | Keep 1 year of trends |
| **Applications** | `Battery` | Create new application |
| **Description** | `Battery state of charge percentage (0-100%)` | Optional |
| **Enabled** | ✅ Checked | Enable item |

#### Click **Add** to create the item.

### 3.3 Create All Items

Repeat the process for all metrics. Here's a quick reference:

#### Battery Items (Application: "Battery")

1. **Battery State of Charge**
   - Key: `easun[battery.soc]`
   - Type: Numeric (float)
   - Units: `%`

2. **Battery Voltage**
   - Key: `easun[battery.voltage]`
   - Type: Numeric (float)
   - Units: `V`

3. **Battery Current**
   - Key: `easun[battery.current]`
   - Type: Numeric (float)
   - Units: `A`

4. **Battery Power**
   - Key: `easun[battery.power]`
   - Type: Numeric (float)
   - Units: `W`

5. **Battery Temperature**
   - Key: `easun[battery.temperature]`
   - Type: Numeric (float)
   - Units: `°C`

#### Solar/PV Items (Application: "Solar")

6. **PV Total Power**
   - Key: `easun[pv.total_power]`
   - Type: Numeric (unsigned)
   - Units: `W`

7. **PV Charging Power**
   - Key: `easun[pv.charging_power]`
   - Type: Numeric (unsigned)
   - Units: `W`

8. **PV1 Voltage**
   - Key: `easun[pv1.voltage]`
   - Type: Numeric (float)
   - Units: `V`

9. **PV1 Current**
   - Key: `easun[pv1.current]`
   - Type: Numeric (float)
   - Units: `A`

10. **PV1 Power**
    - Key: `easun[pv1.power]`
    - Type: Numeric (unsigned)
    - Units: `W`

#### Grid Items (Application: "Grid")

11. **Grid Voltage**
    - Key: `easun[grid.voltage]`
    - Type: Numeric (float)
    - Units: `V`

12. **Grid Power**
    - Key: `easun[grid.power]`
    - Type: Numeric (float)
    - Units: `W`

13. **Grid Frequency**
    - Key: `easun[grid.frequency]`
    - Type: Numeric (float)
    - Units: `Hz`

#### Output Items (Application: "Output")

14. **Output Voltage**
    - Key: `easun[output.voltage]`
    - Type: Numeric (float)
    - Units: `V`

15. **Output Current**
    - Key: `easun[output.current]`
    - Type: Numeric (float)
    - Units: `A`

16. **Output Power**
    - Key: `easun[output.power]`
    - Type: Numeric (float)
    - Units: `W`

17. **Output Load Percentage**
    - Key: `easun[output.load_percentage]`
    - Type: Numeric (float)
    - Units: `%`

18. **Output Frequency**
    - Key: `easun[output.frequency]`
    - Type: Numeric (float)
    - Units: `Hz`

#### System Items (Application: "System")

19. **Operating Mode**
    - Key: `easun[system.mode]`
    - Type: Text
    - Units: (none)

20. **Monitor Status**
    - Key: `easun[status]`
    - Type: Numeric (unsigned)
    - Units: (none)
    - Description: 1=OK, 0=Error

### 3.4 Verify Items

1. Go to **Monitoring** → **Latest data**
2. Select host: **Easun-Inverter**
3. All items should show values (not "No data")
4. Values should update every 30 seconds

---

## Step 4: Create Triggers

Triggers generate alerts when conditions are met.

### 4.1 Navigate to Triggers

1. Go to **Configuration** → **Hosts**
2. Find **Easun-Inverter** host
3. Click **Triggers**
4. Click **Create trigger**

### 4.2 Critical Triggers

#### 4.2.1 Battery Low (Critical)

| Field | Value |
|-------|-------|
| **Name** | `Battery low (SOC < 20%)` |
| **Severity** | High |
| **Expression** | Click **Add** → **Select** next to Expression |

**Expression Builder**:
- Item: `Easun-Inverter: Battery State of Charge`
- Function: `last()`
- Result: `< 20`

**Full expression**:
```
{Easun-Inverter:easun[battery.soc].last()}<20
```

| Field | Value |
|-------|-------|
| **OK event generation** | Expression |
| **Recovery expression** | `{Easun-Inverter:easun[battery.soc].last()}>25` |
| **Description** | `Battery SOC is below 20%. Current: {ITEM.LASTVALUE}` |
| **Enabled** | ✅ Checked |

#### 4.2.2 Monitor Service Down (Critical)

| Field | Value |
|-------|-------|
| **Name** | `Inverter monitor service is down` |
| **Severity** | High |
| **Expression** | `{Easun-Inverter:easun[status].last()}=0` |
| **Description** | `Monitor service stopped or failed` |

#### 4.2.3 Grid Power Failure (High)

| Field | Value |
|-------|-------|
| **Name** | `Grid power failure` |
| **Severity** | High |
| **Expression** | `{Easun-Inverter:easun[grid.voltage].last()}<100` |
| **Description** | `Grid voltage dropped below 100V. Current: {ITEM.LASTVALUE}V` |

#### 4.2.4 Overload Warning (Average)

| Field | Value |
|-------|-------|
| **Name** | `Output overload (>90%)` |
| **Severity** | Average |
| **Expression** | `{Easun-Inverter:easun[output.load_percentage].last()}>90` |
| **Recovery expression** | `{Easun-Inverter:easun[output.load_percentage].last()}<80` |
| **Description** | `Inverter load is above 90%. Current: {ITEM.LASTVALUE}%` |

### 4.3 Warning Triggers

#### 4.3.1 Battery Low Warning

| Field | Value |
|-------|-------|
| **Name** | `Battery low warning (SOC < 50%)` |
| **Severity** | Warning |
| **Expression** | `{Easun-Inverter:easun[battery.soc].last()}<50` |
| **Recovery expression** | `{Easun-Inverter:easun[battery.soc].last()}>55` |

#### 4.3.2 High Battery Temperature

| Field | Value |
|-------|-------|
| **Name** | `Battery temperature high (>40°C)` |
| **Severity** | Warning |
| **Expression** | `{Easun-Inverter:easun[battery.temperature].last()}>40` |
| **Recovery expression** | `{Easun-Inverter:easun[battery.temperature].last()}<35` |

#### 4.3.3 Grid Voltage Abnormal

| Field | Value |
|-------|-------|
| **Name** | `Grid voltage abnormal` |
| **Severity** | Warning |
| **Expression** | `{Easun-Inverter:easun[grid.voltage].last()}<200 or {Easun-Inverter:easun[grid.voltage].last()}>250` |

#### 4.3.4 Grid Frequency Abnormal

| Field | Value |
|-------|-------|
| **Name** | `Grid frequency abnormal` |
| **Severity** | Warning |
| **Expression** | `{Easun-Inverter:easun[grid.frequency].last()}<49.5 or {Easun-Inverter:easun[grid.frequency].last()}>50.5` |

### 4.4 Information Triggers

#### 4.4.1 Solar Production Started

| Field | Value |
|-------|-------|
| **Name** | `Solar production started` |
| **Severity** | Information |
| **Expression** | `{Easun-Inverter:easun[pv.total_power].last()}>50` |
| **Recovery expression** | `{Easun-Inverter:easun[pv.total_power].last()}<10` |

---

## Step 5: Create Graphs

Graphs visualize metric trends over time.

### 5.1 Navigate to Graphs

1. Go to **Configuration** → **Hosts**
2. Find **Easun-Inverter** host
3. Click **Graphs**
4. Click **Create graph**

### 5.2 Battery Status Graph

| Field | Value |
|-------|-------|
| **Name** | `Battery Status` |
| **Width** | `900` |
| **Height** | `200` |
| **Graph type** | Normal |
| **Show legend** | ✅ Checked |

**Items** (click **Add**):

1. **Battery SOC**
   - Item: `Easun-Inverter: Battery State of Charge`
   - Color: `00AA00` (green)
   - Y axis side: Left
   - Draw style: Line

2. **Battery Temperature**
   - Item: `Easun-Inverter: Battery Temperature`
   - Color: `FF6600` (orange)
   - Y axis side: Right
   - Draw style: Line

Click **Add** to create graph.

### 5.3 Power Flow Graph

| Field | Value |
|-------|-------|
| **Name** | `Power Flow` |
| **Width** | `900` |
| **Height** | `300` |

**Items**:

1. **PV Power**
   - Item: `Easun-Inverter: PV Total Power`
   - Color: `FFD700` (gold)
   - Draw style: Filled region

2. **Grid Power**
   - Item: `Easun-Inverter: Grid Power`
   - Color: `0000FF` (blue)
   - Draw style: Line

3. **Output Power**
   - Item: `Easun-Inverter: Output Power`
   - Color: `FF0000` (red)
   - Draw style: Line

4. **Battery Power**
   - Item: `Easun-Inverter: Battery Power`
   - Color: `00AA00` (green)
   - Draw style: Line

### 5.4 Voltage Graph

| Field | Value |
|-------|-------|
| **Name** | `Voltage Status` |
| **Width** | `900` |
| **Height** | `200` |

**Items**:

1. **Battery Voltage**
   - Item: `Easun-Inverter: Battery Voltage`
   - Color: `00AA00` (green)

2. **Grid Voltage**
   - Item: `Easun-Inverter: Grid Voltage`
   - Color: `0000FF` (blue)

3. **Output Voltage**
   - Item: `Easun-Inverter: Output Voltage`
   - Color: `FF0000` (red)

4. **PV1 Voltage**
   - Item: `Easun-Inverter: PV1 Voltage`
   - Color: `FFD700` (gold)

### 5.5 Load Graph

| Field | Value |
|-------|-------|
| **Name** | `Output Load` |
| **Width** | `900` |
| **Height** | `200` |

**Items**:

1. **Load Percentage**
   - Item: `Easun-Inverter: Output Load Percentage`
   - Color: `FF6600` (orange)
   - Draw style: Filled region

2. **Output Power**
   - Item: `Easun-Inverter: Output Power`
   - Color: `FF0000` (red)
   - Y axis side: Right
   - Draw style: Line

---

## Step 6: Create Dashboard

Dashboards provide a unified view of all metrics.

### 6.1 Create New Dashboard

1. Go to **Monitoring** → **Dashboards**
2. Click **Create dashboard** (top right)
3. Name: `Easun Inverter Overview`
4. Click **Save**

### 6.2 Add Widgets

Click **Edit dashboard**, then **Add widget** for each:

#### Widget 1: Current Status

- **Type**: Item value
- **Name**: `Inverter Status`
- **Refresh interval**: `30 seconds`
- **Items to show**: `20`
- **Items**:
  - Battery State of Charge
  - Battery Voltage
  - Output Power
  - Output Load Percentage
  - Grid Voltage
  - PV Total Power
  - Operating Mode

#### Widget 2: Power Flow Graph

- **Type**: Graph (classic)
- **Name**: `Power Flow`
- **Refresh interval**: `1 minute`
- **Graph**: `Easun-Inverter: Power Flow`
- **Time period**: `Last 24 hours`

#### Widget 3: Battery Graph

- **Type**: Graph (classic)
- **Name**: `Battery Status`
- **Graph**: `Easun-Inverter: Battery Status`
- **Time period**: `Last 12 hours`

#### Widget 4: Problems

- **Type**: Problems
- **Name**: `Active Problems`
- **Show**: `Recent problems`
- **Host groups**: `Energy/Inverters`
- **Hosts**: `Easun-Inverter`

#### Widget 5: System Info

- **Type**: Plain text
- **Name**: `System Information`
- **Items**:
  - Operating Mode
  - Monitor Status
  - Grid Frequency
  - Output Frequency

#### Widget 6: Voltage Graph

- **Type**: Graph (classic)
- **Name**: `Voltage Status`
- **Graph**: `Easun-Inverter: Voltage Status`
- **Time period**: `Last 6 hours`

### 6.3 Arrange Widgets

Drag and resize widgets to create a nice layout:

```
┌─────────────────────┬─────────────────────┐
│   Current Status    │   Active Problems   │
├─────────────────────┴─────────────────────┤
│         Power Flow Graph (24h)            │
├─────────────────────┬─────────────────────┤
│  Battery Graph      │  Voltage Graph      │
├─────────────────────┴─────────────────────┤
│          System Information               │
└───────────────────────────────────────────┘
```

Click **Save changes**.

---

## Step 7: Testing

### 7.1 Verify Data Collection

1. Go to **Monitoring** → **Latest data**
2. Select host: **Easun-Inverter**
3. Verify all items show recent values
4. Click **Graph** next to any item to see trend

### 7.2 Test Triggers

#### Simulate Low Battery

On Zabbix agent host, temporarily modify the data:

```bash
# Stop monitor
sudo systemctl stop easun-zabbix.service

# Manually edit JSON (for testing only)
nano /tmp/easun_data.json
# Change "battery.soc": 100.0 to "battery.soc": 15.0

# Wait 30 seconds, check Zabbix for trigger
```

**Expected**: "Battery low (SOC < 20%)" trigger fires in Zabbix.

**Restore**:
```bash
sudo systemctl start easun-zabbix.service
```

### 7.3 Check Graphs

1. Go to **Monitoring** → **Graphs**
2. Select host: **Easun-Inverter**
3. Select graph: **Power Flow**
4. Verify graph displays correctly

### 7.4 View Dashboard

1. Go to **Monitoring** → **Dashboards**
2. Select: **Easun Inverter Overview**
3. Verify all widgets display data

---

## Appendix: All Items Reference

Complete list of all items to create:

### Template for Quick Item Creation

Use this as a reference when creating items:

| # | Name | Key | Type | Units | Application |
|---|------|-----|------|-------|-------------|
| 1 | Battery State of Charge | easun[battery.soc] | Float | % | Battery |
| 2 | Battery Voltage | easun[battery.voltage] | Float | V | Battery |
| 3 | Battery Current | easun[battery.current] | Float | A | Battery |
| 4 | Battery Power | easun[battery.power] | Float | W | Battery |
| 5 | Battery Temperature | easun[battery.temperature] | Float | °C | Battery |
| 6 | PV Total Power | easun[pv.total_power] | Unsigned | W | Solar |
| 7 | PV Charging Power | easun[pv.charging_power] | Unsigned | W | Solar |
| 8 | PV Charging Current | easun[pv.charging_current] | Float | A | Solar |
| 9 | PV1 Voltage | easun[pv1.voltage] | Float | V | Solar |
| 10 | PV1 Current | easun[pv1.current] | Float | A | Solar |
| 11 | PV1 Power | easun[pv1.power] | Unsigned | W | Solar |
| 12 | PV2 Voltage | easun[pv2.voltage] | Float | V | Solar |
| 13 | PV2 Current | easun[pv2.current] | Unsigned | A | Solar |
| 14 | PV2 Power | easun[pv2.power] | Unsigned | W | Solar |
| 15 | PV Energy Today | easun[pv.energy_today] | Float | kWh | Solar |
| 16 | PV Energy Total | easun[pv.energy_total] | Float | kWh | Solar |
| 17 | Grid Voltage | easun[grid.voltage] | Float | V | Grid |
| 18 | Grid Power | easun[grid.power] | Float | W | Grid |
| 19 | Grid Frequency | easun[grid.frequency] | Float | Hz | Grid |
| 20 | Output Voltage | easun[output.voltage] | Float | V | Output |
| 21 | Output Current | easun[output.current] | Float | A | Output |
| 22 | Output Power | easun[output.power] | Float | W | Output |
| 23 | Output Load Percentage | easun[output.load_percentage] | Float | % | Output |
| 24 | Output Frequency | easun[output.frequency] | Float | Hz | Output |
| 25 | Operating Mode | easun[system.mode] | Text | - | System |
| 26 | Operating Mode Code | easun[system.mode_code] | Unsigned | - | System |
| 27 | Monitor Status | easun[status] | Unsigned | - | System |

### Common Settings for All Items

| Setting | Value |
|---------|-------|
| Type | Zabbix agent |
| Update interval | 30s |
| History storage | 90d |
| Trend storage | 365d |
| Show value | As is |
| Enabled | ✅ |

---

## Troubleshooting

### Items Show "Not supported"

**Check**:
```bash
# On Zabbix server
zabbix_get -s AGENT_HOST_IP -k easun[battery.soc]

# On agent
sudo zabbix_agentd -t easun[battery.soc]
```

**Fix**:
- Verify UserParameter is configured
- Restart zabbix-agent
- Check script permissions

### No Data in Items

**Check**:
1. Monitor service is running: `sudo systemctl status easun-zabbix.service`
2. Data file is fresh: `cat /tmp/easun_data.json`
3. Agent is reachable: `zabbix_get -s AGENT_HOST_IP -k agent.ping`

### Triggers Not Firing

**Check**:
1. Item is collecting data
2. Expression syntax is correct
3. Trigger is enabled
4. Severity is not filtered

### Graphs Show No Data

**Check**:
1. Items have history
2. Time range is correct
3. Graph configuration includes items
4. Items are enabled and collecting

---

## Advanced Configuration

### Create Template

To reuse configuration for multiple inverters:

1. Go to **Configuration** → **Templates**
2. Click **Create template**
3. Name: `Template Easun Inverter`
4. Groups: `Templates/Energy`
5. Add all items, triggers, and graphs
6. Link template to hosts

### Discovery Rules (Optional)

Create LLD rule to auto-discover metrics:

**File**: `/home/pi/easunpy/easun_discovery.sh`

```bash
#!/bin/bash
# Return JSON for Zabbix LLD

echo '{'
echo '  "data": ['
echo '    {"{#METRIC}": "battery.soc", "{#NAME}": "Battery SOC", "{#UNIT}": "%"},'
echo '    {"{#METRIC}": "battery.voltage", "{#NAME}": "Battery Voltage", "{#UNIT}": "V"},'
echo '    {"{#METRIC}": "output.power", "{#NAME}": "Output Power", "{#UNIT}": "W"}'
echo '  ]'
echo '}'
```

### Email Notifications

1. Go to **Administration** → **Media types**
2. Configure Email media type
3. Go to **Administration** → **Users**
4. Add media (email) to user
5. Create **Actions** for trigger events

---

## Summary

You've now configured:

✅ **Host**: Easun-Inverter
✅ **Items**: 20+ metrics
✅ **Triggers**: Critical, Warning, Info alerts
✅ **Graphs**: Battery, Power, Voltage, Load
✅ **Dashboard**: Complete overview

### Next Steps

1. **Monitor** for 24-48 hours to verify stability
2. **Adjust** trigger thresholds based on usage
3. **Create** email/SMS notifications
4. **Export** configuration as template
5. **Add** more graphs as needed

---

**Document Version**: 1.0
**Last Updated**: 2026-02-15
**Status**: Complete
