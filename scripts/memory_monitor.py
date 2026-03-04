# On Linux, free -h shows RAM and swap usage in human-readable units.
# On macOS there's no free command, but there are equivalents.
# Python is actually the cleaner cross-platform choice here.
#
# What to look for:
#   - Usage consistently near total RAM capacity (swapping likely)
#   - Sudden spikes compared to a known baseline
#   - Gradual growth over time suggesting a memory leak

import psutil

print(f"RAM usage: {psutil.virtual_memory().used / 1e9:.2f} GB")
