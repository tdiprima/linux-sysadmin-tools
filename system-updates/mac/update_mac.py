# Updates Rust and Homebrew, upgrades installed packages, cleans up, and 
# checks system health, handling exceptions and keyboard interrupts.
import os
import subprocess

try:
    subprocess.run(["rustup", "update"])
    password = os.getenv("BREW_PASSWORD")
    print("🍺 Updating Homebrew...")
    subprocess.run(["brew", "update"])
    subprocess.run(["brew", "upgrade"], input=password, text=True)
    subprocess.run(["brew", "cleanup", "-s"])
    subprocess.run(["brew", "doctor"])
except Exception as e:
    print(e)
except KeyboardInterrupt:
    print("\n🎬 Stopping.")
