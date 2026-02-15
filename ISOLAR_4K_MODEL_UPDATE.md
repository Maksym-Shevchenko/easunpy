# ISOLAR_SMG_II_4K Model Creation - Update Summary

**Date**: 2026-02-15
**Issue**: Output load percentage showing incorrectly (0.18% instead of 18%)
**Solution**: Created new ISOLAR_SMG_II_4K model with corrected scaling

---

## Problem Description

The ISOLAR_SMG_II_6K model had incorrect scaling for `output_load_percentage`:
- **Register**: 225
- **Incorrect scaling**: 0.01 (divides by 100)
- **Result**: 18% was displayed as 0.18%

### Example of Issue
```json
"output.load_percentage": 0.19  // Wrong - should be 19%
```

---

## Solution

Created a new model `ISOLAR_SMG_II_4K` based on the 6K model with corrected load percentage scaling.

### Changes Made

#### 1. Added New Model to `models.py`

**File**: `~/easunpy/easunpy/models.py`

**Change**: Added ISOLAR_SMG_II_4K configuration with corrected scaling:

```python
ISOLAR_SMG_II_4K = ModelConfig(
    name="ISOLAR_SMG_II_4K",
    register_map={
        # ... same as 6K except:
        "output_load_percentage": RegisterConfig(225),  # Fixed: removed 0.01 scaling
        # (uses default scale_factor of 1.0)
    }
)
```

**Key Difference**:
- **6K Model**: `RegisterConfig(225, 0.01)` → multiplies by 0.01
- **4K Model**: `RegisterConfig(225)` → uses default 1.0 (no scaling)

#### 2. Updated MODEL_CONFIGS Dictionary

```python
MODEL_CONFIGS = {
    "ISOLAR_SMG_II_11K": ISOLAR_SMG_II_11K,
    "ISOLAR_SMG_II_6K": ISOLAR_SMG_II_6K,
    "ISOLAR_SMG_II_4K": ISOLAR_SMG_II_4K,  # Added
}
```

#### 3. Updated Service Configuration

**File**: `~/easunpy/easun-zabbix.service`

**Changed**:
```ini
# Before
ExecStart=... --model ISOLAR_SMG_II_6K ...

# After
ExecStart=... --model ISOLAR_SMG_II_4K ...
```

#### 4. Updated Default Models in Scripts

**Files Updated**:
- `~/easunpy/zabbix_monitor.py`
- `~/easunpy/easunpy/__main__.py`

**Changed**:
```python
# Before
parser.add_argument('--model', default='ISOLAR_SMG_II_6K', ...)

# After
parser.add_argument('--model', default='ISOLAR_SMG_II_4K', ...)
```

#### 5. Restarted Service

```bash
sudo cp ~/easunpy/easun-zabbix.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart easun-zabbix.service
```

---

## Verification

### Before Fix
```json
{
  "output.load_percentage": 0.19,  // Incorrect
  "output.power": 817.0
}
```

### After Fix
```json
{
  "output.load_percentage": 18.0,  // Correct! ✅
  "output.power": 767.0
}
```

### Display Output

**Before**:
```
Load                          : 0.19 %  ❌
```

**After**:
```
Load                          : 18.0 %  ✅
```

---

## Model Comparison

| Feature | ISOLAR_SMG_II_6K | ISOLAR_SMG_II_4K |
|---------|------------------|------------------|
| Base Configuration | Same registers | Same registers |
| Battery Monitoring | ✅ | ✅ |
| PV1 Monitoring | ✅ | ✅ |
| PV2 Support | ❌ (not supported) | ❌ (not supported) |
| Grid Monitoring | ✅ | ✅ |
| Output Monitoring | ✅ | ✅ |
| **Load % Scaling** | **0.01 (WRONG)** | **1.0 (CORRECT)** ✅ |
| Energy Counters | ❌ (not supported) | ❌ (not supported) |

---

## Technical Details

### Register Configuration

The RegisterConfig class supports a `scale_factor` parameter:

```python
@dataclass
class RegisterConfig:
    address: int
    scale_factor: float = 1.0  # Default: no scaling
    processor: Optional[Callable[[int], Any]] = None
```

### How Scaling Works

```python
def process_value(self, register_name: str, value: int) -> Any:
    config = self.register_map.get(register_name)
    if config.processor:
        return config.processor(value)
    return value * config.scale_factor
```

### Example Calculation

**With 0.01 scaling (6K model)**:
```
Raw register value: 19
Scaled value: 19 × 0.01 = 0.19
Display: 0.19%  ❌ WRONG
```

**With 1.0 scaling (4K model)**:
```
Raw register value: 19
Scaled value: 19 × 1.0 = 19
Display: 19.0%  ✅ CORRECT
```

---

## Files Modified

1. **`~/easunpy/easunpy/models.py`**
   - Added ISOLAR_SMG_II_4K model definition
   - Updated MODEL_CONFIGS dictionary

2. **`~/easunpy/easun-zabbix.service`**
   - Changed model from 6K to 4K

3. **`~/easunpy/zabbix_monitor.py`**
   - Changed default model from 6K to 4K

4. **`~/easunpy/easunpy/__main__.py`**
   - Changed default model to 4K

5. **`/etc/systemd/system/easun-zabbix.service`**
   - Updated and reloaded

---

## Service Status

```bash
● easun-zabbix.service - Easun Inverter Zabbix Monitor
   Active: active (running)
   Model: ISOLAR_SMG_II_4K  ✅
   Status: Updated data: Battery 100.0%, PV 0W, Output 767.0W
```

---

## Testing Commands

### Verify Model is Active
```bash
sudo systemctl status easun-zabbix.service | grep ISOLAR_SMG_II_4K
```

### Check Load Percentage
```bash
./easun_query.sh output.load_percentage
# Expected: ~18-20 (not 0.18-0.20)
```

### View All Metrics
```bash
./show_metrics.sh
# Load should show as 18.0% not 0.18%
```

### View Raw Data
```bash
cat /tmp/easun_data.json | grep load_percentage
# Expected: "output.load_percentage": 18.0
```

---

## Migration Guide

If you want to switch an existing installation:

### Option 1: Update Service (Recommended)
```bash
cd ~/easunpy
# Edit service file
nano easun-zabbix.service
# Change: --model ISOLAR_SMG_II_6K
# To:     --model ISOLAR_SMG_II_4K

# Update and restart
sudo cp easun-zabbix.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart easun-zabbix.service
```

### Option 2: Manual Run
```bash
cd ~/easunpy
./zabbix_monitor.py --inverter-ip 10.1.31.9 --model ISOLAR_SMG_II_4K --interval 30
```

---

## Zabbix Impact

### No Changes Required

The Zabbix integration continues to work without any changes:
- ✅ Same metric key: `easun[output.load_percentage]`
- ✅ Same data type: Numeric (float)
- ✅ Same units: Percentage
- ✅ Values now correct: 18.0 instead of 0.18

### Graphs and Triggers

**Important**: If you have existing graphs or triggers using load percentage:
- Old data will show 0.x% (incorrect historical data)
- New data will show x% (correct current data)
- You may see a sudden 100x jump when the fix was applied
- This is expected and reflects the correction

**Recommendation**: Add annotation in Zabbix noting when the fix was applied (2026-02-15).

---

## Supported Models Summary

After this update, three models are available:

### 1. ISOLAR_SMG_II_11K
- Larger inverter (11 kW)
- PV2 support: ✅
- Energy counters: ✅
- Load % scaling: Correct (1.0)

### 2. ISOLAR_SMG_II_6K
- Medium inverter (6 kW)
- PV2 support: ❌
- Energy counters: ❌
- Load % scaling: **Incorrect (0.01)** ⚠️

### 3. ISOLAR_SMG_II_4K (NEW)
- Based on 6K register map
- PV2 support: ❌
- Energy counters: ❌
- Load % scaling: **Correct (1.0)** ✅

---

## Recommendations

1. **Use ISOLAR_SMG_II_4K** for 4K and 6K inverters with single PV input
2. **Use ISOLAR_SMG_II_11K** for 11K inverters with dual PV inputs
3. **Avoid ISOLAR_SMG_II_6K** due to incorrect load percentage scaling

---

## Future Improvements

### Option 1: Fix 6K Model
Instead of creating a new model, fix the 6K model directly:
```python
"output_load_percentage": RegisterConfig(225),  # Remove 0.01
```

**Impact**: Would fix all existing 6K installations but break compatibility.

### Option 2: Keep Both Models
Current approach - maintains backward compatibility:
- 6K model: For existing installations (incorrect but stable)
- 4K model: For new installations (correct)

**Chosen**: Option 2 (current implementation)

---

## Summary

✅ **Created**: ISOLAR_SMG_II_4K model
✅ **Fixed**: Output load percentage now shows correctly (18% not 0.18%)
✅ **Updated**: Service configuration to use new model
✅ **Tested**: Verified metrics are displaying correctly
✅ **Compatible**: No Zabbix configuration changes needed

**Result**: Output load percentage now displays correctly! 🎉

---

**Author**: System Update
**Date**: 2026-02-15
**Version**: 1.0
**Status**: Complete ✅
