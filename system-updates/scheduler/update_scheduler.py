#!/usr/bin/env python3

import subprocess
import sys
import time

import schedule
from loguru import logger

logger.add("system_updates.log", rotation="10 MB", retention="30 days", level="INFO")
logger.add(
    "system_updates_debug.log", rotation="10 MB", retention="7 days", level="DEBUG"
)


def run_update_script(script_name):
    logger.info(f"Starting {script_name} update process")

    try:
        result = subprocess.run([f"./{script_name}"], capture_output=True, text=True)

        output = result.stdout
        error = result.stderr
        exit_code = result.returncode

        logger.info(f"Update command completed with exit code: {exit_code}")

        if output:
            logger.info("Update output:")
            for line in output.strip().split("\n"):
                logger.info(f"  {line}")

        if error:
            logger.warning("Update stderr:")
            for line in error.strip().split("\n"):
                logger.warning(f"  {line}")

        if "reboot" in output.lower() or "restart" in output.lower():
            logger.critical("REBOOT REQUIRED - Check update output above")

        if exit_code != 0:
            logger.error(f"Update failed with exit code {exit_code}")
        else:
            logger.info("Update completed successfully")

    except FileNotFoundError:
        logger.error(f"{script_name} script not found in current directory")
    except Exception as e:
        logger.error(f"Error running {script_name}: {str(e)}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python update_scheduler.py <script_name>")
        print("Example: python update_scheduler.py update_rhel")
        sys.exit(1)

    script_name = sys.argv[1]
    schedule.every().day.at("23:30").do(run_update_script, script_name)
    logger.info("Update Scheduler started")

    while True:
        schedule.run_pending()
        time.sleep(60)
