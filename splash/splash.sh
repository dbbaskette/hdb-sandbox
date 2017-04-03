#!/bin/bash


start() {
    sleep 8
    chvt 2
    python /var/splash/splash.py
}

stop() {
    chvt 1
}

case $1 in
  start|stop) "$1" ;;
esac