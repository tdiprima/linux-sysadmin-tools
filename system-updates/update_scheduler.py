#!/usr/bin/env python3

import schedule
import time
import sh
import sys
from loguru import logger

logger.add("system_updates.log", rotation="10 MB", retention="30 days", level="INFO")
logger.add("system_updates_debug.log", rotation="10 MB", retention="7 days", level="DEBUG")


def run_update_script(script_name):
    logger.info(f"Starting {script_name} update process")
    
    try:
        result = sh.Command(f"./{script_name}")(_out=str, _err=str, _return_cmd=True)
        
        output = result.stdout.decode('utf-8')
        error = result.stderr.decode('utf-8') if result.stderr else ""
        
        logger.info(f"Update command completed with exit code: {result.exit_code}")
        
        if output:
            logger.info("Update output:")
            for line in output.strip().split('\n'):
                logger.info(f"  {line}")
        
        if error:
            logger.warning("Update stderr:")
            for line in error.strip().split('\n'):
                logger.warning(f"  {line}")
        
        if "reboot" in output.lower() or "restart" in output.lower():
            logger.critical("REBOOT REQUIRED - Check update output above")
        
        if result.exit_code != 0:
            logger.error(f"Update failed with exit code {result.exit_code}")
        else:
            logger.info("Update completed successfully")
            
    except sh.CommandNotFound:
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
