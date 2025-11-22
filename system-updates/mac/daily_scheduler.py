import os
import subprocess
import time

import schedule
from loguru import logger

logger.add("scheduler.log", rotation="5 MB", retention=3, level="DEBUG")


def my_daily_task():
    password = os.getenv("BREW_PASSWORD")
    logger.info("🍺 Updating Homebrew...")
    subprocess.run(["brew", "update"])
    subprocess.run(["brew", "upgrade"], input=password, text=True)
    subprocess.run(["brew", "cleanup", "-s"])
    subprocess.run(["brew", "doctor"])
    logger.info("✅ Homebrew updated.")


try:
    schedule.every().day.at("15:00").do(my_daily_task)

    logger.info("Scheduler started. Waiting for 3:00 PM each day...")
    while True:
        schedule.run_pending()
        time.sleep(1)
except Exception as e:
    logger.error(e)
except KeyboardInterrupt:
    logger.info("\n🎬 Stopping.")
