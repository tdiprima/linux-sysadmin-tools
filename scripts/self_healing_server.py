"""
Monitors CPU & memory at set intervals.
Logs high-usage processes.
Kills rogue processes (or just logs them in dry-run mode).
Can restart services (extendable via restart_service).
Command-line configurable (thresholds, interval, dry-run mode).

python self_healing_server.py --cpu 85 --mem 85 --interval 5 --dry-run
"""

import argparse
import logging
import subprocess
import time

import psutil

# Configure logging
logging.basicConfig(
    filename="self_healing.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def get_high_usage_processes(cpu_threshold=90, mem_threshold=90):
    """Returns a list of processes exceeding CPU or memory thresholds."""
    high_usage = []
    for proc in psutil.process_iter(
        attrs=["pid", "name", "cpu_percent", "memory_percent"]
    ):
        try:
            if (
                proc.info["cpu_percent"] > cpu_threshold
                or proc.info["memory_percent"] > mem_threshold
            ):
                high_usage.append(proc.info)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    return high_usage


def take_action(process, dry_run=False):
    """Logs or kills a high-usage process based on the mode."""
    pid = process["pid"]
    name = process["name"]
    action_msg = f"High resource usage detected - PID: {pid}, Name: {name}, CPU: {process['cpu_percent']}%, Memory: {process['memory_percent']}%"

    if dry_run:
        logging.info(f"[Dry Run] Would have killed process: {action_msg}")
    else:
        try:
            logging.warning(f"Killing process: {action_msg}")
            psutil.Process(pid).terminate()
        except Exception as e:
            logging.error(f"Failed to kill process {pid}: {e}")


def restart_service(service_name, dry_run=False):
    """Restarts a given service."""
    if dry_run:
        logging.info(f"[Dry Run] Would have restarted service: {service_name}")
    else:
        try:
            logging.warning(f"Restarting service: {service_name}")
            subprocess.run(["systemctl", "restart", service_name], check=True)
        except Exception as e:
            logging.error(f"Failed to restart service {service_name}: {e}")


def monitor_system(cpu_threshold, mem_threshold, interval, dry_run):
    """Main monitoring loop."""
    logging.info("Starting Self-Healing Server Monitor...")
    while True:
        high_usage_processes = get_high_usage_processes(cpu_threshold, mem_threshold)
        if high_usage_processes:
            for process in high_usage_processes:
                take_action(process, dry_run)

        time.sleep(interval)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Self-Healing Server Monitor")
    parser.add_argument("--cpu", type=int, default=90, help="CPU usage threshold (%)")
    parser.add_argument(
        "--mem", type=int, default=90, help="Memory usage threshold (%)"
    )
    parser.add_argument(
        "--interval", type=int, default=10, help="Monitoring interval (seconds)"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Log actions instead of executing them"
    )
    args = parser.parse_args()

    monitor_system(args.cpu, args.mem, args.interval, args.dry_run)
