#!/bin/bash

HUE_HOME_DIR=/usr/lib/hue

/etc/init.d/hue status &> /dev/null || exit 1

$HUE_HOME_DIR/build/env/bin/hue smoke_test
exit 0;
