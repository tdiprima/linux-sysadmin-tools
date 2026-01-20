#!/usr/bin/env python3
# Updates Rust and Homebrew, upgrades installed packages, cleans up, and 
# checks system health, handling exceptions and keyboard interrupts.
import os
import subprocess

try:
    print("📦 Updating Cargo...")
    subprocess.run(["rustup", "update"])
    print("✅ Cargo updated.")
    password = os.getenv("BREW_PASSWORD")
    print("🍺 Updating Homebrew...")
    subprocess.run(["brew", "update"])
    subprocess.run(["brew", "upgrade"], input=password, text=True)
    subprocess.run(["brew", "cleanup", "-s"])
    subprocess.run(["brew", "doctor"])
    print("✅ Homebrew updated.")
except Exception as e:
    print(e)
except KeyboardInterrupt:
    print("\n🎬 Stopping.")
