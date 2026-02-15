#!/bin/bash
# Control script for Easun Zabbix Monitor

SCRIPT_DIR="/home/pi/easunpy"
SERVICE_NAME="easun-zabbix.service"
DATA_FILE="/tmp/easun_data.json"

case "$1" in
    start)
        echo "Starting Easun Zabbix Monitor as systemd service..."
        sudo systemctl start $SERVICE_NAME
        sleep 2
        sudo systemctl status $SERVICE_NAME --no-pager
        ;;

    stop)
        echo "Stopping Easun Zabbix Monitor..."
        sudo systemctl stop $SERVICE_NAME
        ;;

    restart)
        echo "Restarting Easun Zabbix Monitor..."
        sudo systemctl restart $SERVICE_NAME
        sleep 2
        sudo systemctl status $SERVICE_NAME --no-pager
        ;;

    status)
        sudo systemctl status $SERVICE_NAME --no-pager
        echo ""
        if [ -f "$DATA_FILE" ]; then
            echo "Last update: $(jq -r .timestamp $DATA_FILE 2>/dev/null || echo 'Unknown')"
            echo "Status: $(jq -r .status $DATA_FILE 2>/dev/null || echo 'Unknown')"
        else
            echo "Data file not found"
        fi
        ;;

    logs)
        echo "Showing logs (Ctrl+C to exit)..."
        sudo journalctl -u $SERVICE_NAME -f
        ;;

    metrics)
        ${SCRIPT_DIR}/show_metrics.sh
        ;;

    install)
        echo "Installing systemd service..."
        sudo cp ${SCRIPT_DIR}/easun-zabbix.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        echo "Service installed and enabled"
        echo "Use '$0 start' to start the service"
        ;;

    uninstall)
        echo "Uninstalling systemd service..."
        sudo systemctl stop $SERVICE_NAME
        sudo systemctl disable $SERVICE_NAME
        sudo rm /etc/systemd/system/$SERVICE_NAME
        sudo systemctl daemon-reload
        echo "Service uninstalled"
        ;;

    test)
        echo "Testing monitor script (60 seconds)..."
        cd ${SCRIPT_DIR}
        timeout 60 python3.10 zabbix_monitor.py --inverter-ip 10.1.31.9 --model ISOLAR_SMG_II_6K --interval 10
        ;;

    *)
        echo "Easun Zabbix Monitor Control Script"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs|metrics|install|uninstall|test}"
        echo ""
        echo "Commands:"
        echo "  start      - Start the monitor service"
        echo "  stop       - Stop the monitor service"
        echo "  restart    - Restart the monitor service"
        echo "  status     - Show service status and last update"
        echo "  logs       - Show real-time logs"
        echo "  metrics    - Display all current metrics"
        echo "  install    - Install as systemd service"
        echo "  uninstall  - Remove systemd service"
        echo "  test       - Test the monitor script manually"
        exit 1
        ;;
esac
