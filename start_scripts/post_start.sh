#!/bin/bash

# script starts synchronously on tty1

LOG="/var/log/startup_script.log"

(
 nohup sudo -u hue bash /usr/lib/tutorials/tutorials_app/run/run.sh
)  >> $LOG 2>&1 & 

python /usr/lib/hue/tools/start_scripts/splash.py
