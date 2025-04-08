"""
Python Network Monitor Script
Author: Tammy DiPrima
"""
import time
import socket
from datetime import datetime
from ping3 import ping

# CONFIGURATION
TARGET = "192.168.1.1"        # Change to your target IP/domain
PORT = 22                     # Optional: Set to None to skip port check
INTERVAL = 5                  # Seconds between checks
LOG_FILE = "network_monitor.log"

def check_tcp_port(host, port, timeout=2):
    try:
        with socket.create_connection((host, port), timeout):
            return True
    except Exception:
        return False

def log_status(status):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] {status}\n")
    print(f"[{timestamp}] {status}")

print(f"📡 Monitoring {TARGET} every {INTERVAL}s... (Logging to {LOG_FILE})")

while True:
    try:
        response_time = ping(TARGET, timeout=2)
        if response_time is not None:
            log_status(f"✅ Ping successful ({round(response_time * 1000)} ms)")
        else:
            status = "❌ Ping timeout"
            if PORT:
                port_up = check_tcp_port(TARGET, PORT)
                if port_up:
                    status += f" but ✅ Port {PORT} is open"
                else:
                    status += f" and ❌ Port {PORT} is closed"
            log_status(status)
    except Exception as e:
        log_status(f"❌ Ping error: {e}")
    except KeyboardInterrupt:
        print("\n🔚 Stopping monitor.")
        break
    time.sleep(INTERVAL)
