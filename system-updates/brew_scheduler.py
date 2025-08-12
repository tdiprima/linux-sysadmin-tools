#!/usr/bin/env python3
"""
Scheduler for running Mac Homebrew updates weekly on Monday at 11:30 PM.
Uses APScheduler to schedule the update_mac_brew script.
"""

import os
import sys
from datetime import datetime
from pathlib import Path

import sh
from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
from loguru import logger

# Configure logging with loguru
logger.remove()  # Remove default handler
logger.add("brew_scheduler.log", rotation="1 MB", retention="10 days", level="INFO")
logger.add(sys.stdout, level="INFO")

# Path to the update script
SCRIPT_DIR = Path(__file__).parent
UPDATE_SCRIPT = SCRIPT_DIR / "update_mac_brew"


def run_brew_update():
    """Execute the update_mac_brew script."""
    try:
        logger.info("Starting scheduled Homebrew update...")
        
        # Make sure the script exists and is executable
        if not UPDATE_SCRIPT.exists():
            logger.error(f"Update script not found: {UPDATE_SCRIPT}")
            return
        
        if not os.access(UPDATE_SCRIPT, os.X_OK):
            logger.warning(f"Making script executable: {UPDATE_SCRIPT}")
            os.chmod(UPDATE_SCRIPT, 0o755)
        
        # Run the update script using sh
        result = sh.bash(str(UPDATE_SCRIPT), _out=logger.info, _err=logger.error)
        logger.info("Homebrew update completed successfully!")
        
    except Exception as e:
        logger.error(f"Error running Homebrew update: {e}")


def main():
    """Main function to set up and start the scheduler."""
    logger.info("Starting Homebrew update scheduler...")
    logger.info(f"Script will run every Monday at 11:30 PM")
    logger.info(f"Update script location: {UPDATE_SCRIPT}")
    
    # Create scheduler
    scheduler = BlockingScheduler()
    
    # Schedule the job to run every Monday at 11:30 PM
    scheduler.add_job(
        run_brew_update,
        trigger=CronTrigger(day_of_week=0, hour=23, minute=30),  # Monday = 0
        id='homebrew_update',
        name='Weekly Homebrew Update',
        misfire_grace_time=3600  # Allow 1 hour grace period if system was asleep
    )
    
    # Alternative: Schedule the job to run every night at 11:30 PM (commented out)
    # scheduler.add_job(
    #     run_brew_update,
    #     trigger=CronTrigger(hour=23, minute=30),
    #     id='homebrew_update',
    #     name='Nightly Homebrew Update',
    #     misfire_grace_time=3600  # Allow 1 hour grace period if system was asleep
    # )
    
    try:
        logger.info("Scheduler started. Press Ctrl+C to exit.")
        scheduler.start()
    except KeyboardInterrupt:
        logger.info("Scheduler stopped by user.")
    except Exception as e:
        logger.error(f"Scheduler error: {e}")


if __name__ == "__main__":
    main()
