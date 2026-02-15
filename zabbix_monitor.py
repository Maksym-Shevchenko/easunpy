#!/usr/bin/env python3
"""
Zabbix monitor for Easun Inverter
Maintains persistent connection and stores data for Zabbix consumption
"""

import asyncio
import json
import logging
import argparse
import signal
import sys
from pathlib import Path
from datetime import datetime
from easunpy.async_isolar import AsyncISolar
from easunpy.utils import get_local_ip
from easunpy.discover import discover_device

class ZabbixMonitor:
    def __init__(self, inverter_ip: str, local_ip: str, model: str,
                 interval: int = 30, data_file: str = '/tmp/easun_data.json'):
        self.inverter_ip = inverter_ip
        self.local_ip = local_ip
        self.model = model
        self.interval = interval
        self.data_file = Path(data_file)
        self.running = False
        self.inverter = None

        # Set up logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/tmp/easun_zabbix.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

    def flatten_data(self, battery, pv, grid, output, status) -> dict:
        """Flatten inverter data into Zabbix-friendly format."""
        data = {
            'timestamp': datetime.now().isoformat(),
            'status': 1,  # 1 = OK, 0 = Error
        }

        # Battery data
        if battery:
            data['battery.voltage'] = battery.voltage
            data['battery.current'] = battery.current
            data['battery.power'] = battery.power
            data['battery.soc'] = battery.soc
            data['battery.temperature'] = battery.temperature

        # PV data
        if pv:
            data['pv.total_power'] = pv.total_power or 0
            data['pv.charging_power'] = pv.charging_power or 0
            data['pv.charging_current'] = pv.charging_current or 0
            data['pv1.voltage'] = pv.pv1_voltage or 0
            data['pv1.current'] = pv.pv1_current or 0
            data['pv1.power'] = pv.pv1_power or 0
            data['pv2.voltage'] = pv.pv2_voltage or 0
            data['pv2.current'] = pv.pv2_current or 0
            data['pv2.power'] = pv.pv2_power or 0
            data['pv.energy_today'] = pv.pv_generated_today or 0
            data['pv.energy_total'] = pv.pv_generated_total or 0

        # Grid data
        if grid:
            data['grid.voltage'] = grid.voltage or 0
            data['grid.power'] = grid.power or 0
            data['grid.frequency'] = (grid.frequency / 100) if grid.frequency else 0

        # Output data
        if output:
            data['output.voltage'] = output.voltage or 0
            data['output.current'] = output.current or 0
            data['output.power'] = output.power or 0
            data['output.load_percentage'] = output.load_percentage or 0
            data['output.frequency'] = (output.frequency / 100) if output.frequency else 0

        # System status
        if status:
            data['system.mode'] = status.mode_name
            data['system.mode_code'] = status.operating_mode.value
            if status.inverter_time:
                data['system.inverter_time'] = status.inverter_time.isoformat()

        return data

    async def update_data(self):
        """Fetch data from inverter and update JSON file."""
        try:
            battery, pv, grid, output, status = await self.inverter.get_all_data()

            if status is None:
                self.logger.error("Failed to get data from inverter")
                data = {'timestamp': datetime.now().isoformat(), 'status': 0}
            else:
                data = self.flatten_data(battery, pv, grid, output, status)

            # Write to JSON file atomically
            temp_file = self.data_file.with_suffix('.tmp')
            with open(temp_file, 'w') as f:
                json.dump(data, f, indent=2)
            temp_file.replace(self.data_file)

            self.logger.info(f"Updated data: Battery {data.get('battery.soc', 'N/A')}%, "
                           f"PV {data.get('pv.total_power', 'N/A')}W, "
                           f"Output {data.get('output.power', 'N/A')}W")

        except Exception as e:
            self.logger.error(f"Error updating data: {e}", exc_info=True)
            # Write error status
            error_data = {
                'timestamp': datetime.now().isoformat(),
                'status': 0,
                'error': str(e)
            }
            try:
                with open(self.data_file, 'w') as f:
                    json.dump(error_data, f, indent=2)
            except:
                pass

    async def run(self):
        """Main monitoring loop."""
        self.logger.info(f"Starting Zabbix monitor for {self.inverter_ip}")
        self.logger.info(f"Model: {self.model}, Interval: {self.interval}s")
        self.logger.info(f"Data file: {self.data_file}")

        self.inverter = AsyncISolar(self.inverter_ip, self.local_ip, model=self.model)
        self.running = True

        while self.running:
            await self.update_data()

            # Sleep with ability to interrupt
            for _ in range(self.interval):
                if not self.running:
                    break
                await asyncio.sleep(1)

        self.logger.info("Monitor stopped")

    def stop(self):
        """Stop the monitor."""
        self.logger.info("Stopping monitor...")
        self.running = False

def query_value(data_file: str, key: str):
    """Query a specific value from the data file (for Zabbix UserParameter)."""
    try:
        with open(data_file, 'r') as f:
            data = json.load(f)

        # Check if data is too old (more than 5 minutes)
        timestamp = datetime.fromisoformat(data['timestamp'])
        age = (datetime.now() - timestamp).total_seconds()
        if age > 300:
            print("ZBX_NOTSUPPORTED")
            return 1

        # Get the value
        if key in data:
            value = data[key]
            # Handle None values
            if value is None:
                print(0)
            else:
                print(value)
            return 0
        else:
            print("ZBX_NOTSUPPORTED")
            return 1

    except FileNotFoundError:
        print("ZBX_NOTSUPPORTED")
        return 1
    except Exception as e:
        print("ZBX_NOTSUPPORTED")
        return 1

def main():
    parser = argparse.ArgumentParser(description='Zabbix Monitor for Easun Inverter')
    parser.add_argument('--inverter-ip', help='IP address of the inverter')
    parser.add_argument('--local-ip', help='Local IP address')
    parser.add_argument('--model', default='ISOLAR_SMG_II_4K', help='Inverter model')
    parser.add_argument('--interval', type=int, default=30, help='Update interval in seconds')
    parser.add_argument('--data-file', default='/tmp/easun_data.json', help='Data file path')
    parser.add_argument('--query', help='Query a specific value (for Zabbix UserParameter)')
    parser.add_argument('--discover', action='store_true', help='Auto-discover inverter IP')

    args = parser.parse_args()

    # Query mode - just return a value and exit
    if args.query:
        sys.exit(query_value(args.data_file, args.query))

    # Monitor mode - run as daemon
    inverter_ip = args.inverter_ip
    if not inverter_ip:
        if args.discover:
            print("Discovering inverter IP...")
            inverter_ip = discover_device()
            if inverter_ip:
                print(f"Found inverter at: {inverter_ip}")
            else:
                print("Error: Could not discover inverter IP")
                return 1
        else:
            print("Error: --inverter-ip required (or use --discover)")
            return 1

    local_ip = args.local_ip or get_local_ip()
    if not local_ip:
        print("Error: Could not determine local IP address")
        return 1

    monitor = ZabbixMonitor(
        inverter_ip=inverter_ip,
        local_ip=local_ip,
        model=args.model,
        interval=args.interval,
        data_file=args.data_file
    )

    # Set up signal handlers
    def signal_handler(signum, frame):
        monitor.stop()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    try:
        asyncio.run(monitor.run())
    except KeyboardInterrupt:
        pass

    return 0

if __name__ == "__main__":
    sys.exit(main())
