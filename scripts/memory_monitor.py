import psutil

print(f"RAM usage: {psutil.virtual_memory().used / 1e9:.2f} GB")
