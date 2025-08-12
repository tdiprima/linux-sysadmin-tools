#!/usr/bin/env python3
"""
Enhanced scheduler for running Mac Homebrew updates with authentication handling.
Uses APScheduler to schedule updates and pexpect to handle password prompts.
"""

import os
import sys
import subprocess
from datetime import datetime
from pathlib import Path
import getpass

import pexpect
from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger
from loguru import logger

# Configure logging
logger.remove()
logger.add("brew_scheduler.log", rotation="1 MB", retention="10 days", level="INFO")
logger.add(sys.stdout, level="INFO")

# Path to the update script
SCRIPT_DIR = Path(__file__).parent
UPDATE_SCRIPT = SCRIPT_DIR / "update_mac_brew"

# Store password securely (consider using keyring for production)
# You'll need to set this once when starting the scheduler
PASSWORD = None


def run_brew_update_with_auth():
    """Execute the update_mac_brew script with automatic password handling."""
    try:
        logger.info("Starting scheduled Homebrew update with auth handling...")
        
        # Make sure the script exists and is executable
        if not UPDATE_SCRIPT.exists():
            logger.error(f"Update script not found: {UPDATE_SCRIPT}")
            return
        
        if not os.access(UPDATE_SCRIPT, os.X_OK):
            logger.warning(f"Making script executable: {UPDATE_SCRIPT}")
            os.chmod(UPDATE_SCRIPT, 0o755)
        
        # Use pexpect to handle password prompts
        child = pexpect.spawn(f'/bin/bash {UPDATE_SCRIPT}', encoding='utf-8')
        child.logfile_read = sys.stdout
        
        while True:
            try:
                index = child.expect([
                    'Password:',
                    'password for',
                    pexpect.EOF,
                    pexpect.TIMEOUT
                ], timeout=300)  # 5 minute timeout for long operations
                
                if index in [0, 1]:  # Password prompt detected
                    if PASSWORD:
                        child.sendline(PASSWORD)
                        logger.info("Password provided for sudo operation")
                    else:
                        logger.error("Password required but not available")
                        child.terminate()
                        return
                elif index == 2:  # EOF - process completed
                    logger.info("Homebrew update completed successfully!")
                    break
                elif index == 3:  # Timeout
                    logger.warning("Operation timed out, continuing...")
                    
            except Exception as e:
                logger.error(f"Error during update: {e}")
                break
        
        child.close()
        
    except Exception as e:
        logger.error(f"Error running Homebrew update: {e}")


def run_brew_update_simple():
    """Execute brew update/upgrade directly without the wrapper script."""
    try:
        logger.info("Starting direct Homebrew update...")
        
        # Run brew update
        logger.info("Running: brew update")
        result = subprocess.run(
            ['brew', 'update'],
            capture_output=True,
            text=True,
            check=False
        )
        logger.info(f"brew update output: {result.stdout}")
        if result.stderr:
            logger.warning(f"brew update stderr: {result.stderr}")
        
        # Run brew upgrade
        logger.info("Running: brew upgrade")
        result = subprocess.run(
            ['brew', 'upgrade'],
            capture_output=True,
            text=True,
            check=False
        )
        logger.info(f"brew upgrade output: {result.stdout}")
        if result.stderr:
            logger.warning(f"brew upgrade stderr: {result.stderr}")
        
        # Run brew cleanup
        logger.info("Running: brew cleanup")
        result = subprocess.run(
            ['brew', 'cleanup', '-s'],
            capture_output=True,
            text=True,
            check=False
        )
        logger.info(f"brew cleanup output: {result.stdout}")
        
        logger.info("Homebrew update completed!")
        
    except Exception as e:
        logger.error(f"Error running Homebrew update: {e}")


def setup_password_from_keyring():
    """Set up password from macOS keychain (optional, more secure)."""
    try:
        import keyring
        service_name = "homebrew_scheduler"
        account_name = os.environ.get('USER')
        
        # Try to get existing password
        password = keyring.get_password(service_name, account_name)
        
        if not password:
            # Prompt for password and store it
            password = getpass.getpass("Enter your sudo password (will be stored in keychain): ")
            keyring.set_password(service_name, account_name, password)
            logger.info("Password stored in keychain")
        
        return password
    except ImportError:
        logger.warning("keyring module not available. Install with: pip install keyring")
        return None


def main():
    """Main function to set up and start the scheduler."""
    global PASSWORD
    
    logger.info("Starting Homebrew update scheduler...")
    
    # Choose authentication method
    print("\nChoose authentication method:")
    print("1. Run without sudo (may fail for some packages)")
    print("2. Store password in memory (less secure, works for session)")
    print("3. Use macOS keychain (secure, requires 'keyring' module)")
    print("4. Configure sudoers file (most secure, requires one-time setup)")
    
    choice = input("\nEnter choice (1-4): ").strip()
    
    if choice == '2':
        PASSWORD = getpass.getpass("Enter your sudo password: ")
        update_function = run_brew_update_with_auth
    elif choice == '3':
        PASSWORD = setup_password_from_keyring()
        update_function = run_brew_update_with_auth
    elif choice == '4':
        print("\nTo configure sudoers:")
        print("1. Run: sudo visudo")
        print(f"2. Add: {os.environ.get('USER')} ALL=(ALL) NOPASSWD: /usr/local/bin/brew *")
        print(f"3. Add: {os.environ.get('USER')} ALL=(ALL) NOPASSWD: /opt/homebrew/bin/brew *")
        print("4. Save and restart this script\n")
        return
    else:
        update_function = run_brew_update_simple
    
    logger.info(f"Script will run every Monday at 11:30 PM")
    
    # Create scheduler
    scheduler = BlockingScheduler()
    
    # Schedule the job to run every Monday at 11:30 PM
    # scheduler.add_job(
    #     update_function,
    #     trigger=CronTrigger(day_of_week=0, hour=23, minute=30),  # Monday = 0
    #     id='homebrew_update',
    #     name='Weekly Homebrew Update',
    #     misfire_grace_time=3600  # Allow 1 hour grace period if system was asleep
    # )
    
    # Alternative: Schedule the job to run every day at 3:00 PM
    scheduler.add_job(
        run_brew_update,
        trigger=CronTrigger(hour=15, minute=00),
        id='homebrew_update',
        name='Daily Homebrew Update',
        misfire_grace_time=3600  # Allow 1 hour grace period if system was asleep
    )
    
    # Optional: Run once immediately for testing
    if input("\nRun update once now for testing? (y/n): ").lower() == 'y':
        update_function()

    try:
        logger.info("Scheduler started. Press Ctrl+C to exit.")
        scheduler.start()
    except KeyboardInterrupt:
        logger.info("Scheduler stopped by user.")
    except Exception as e:
        logger.error(f"Scheduler error: {e}")


if __name__ == "__main__":
    main()
