#!/bin/bash
# Author: tdiprima
# Create a virtual environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Now install psutil
pip install psutil
