#!/bin/bash

chkconfig ambari on
service ambari start

echo "===================================="
echo
echo "Ambari autostart enabled"
echo "To disable auto-start of Ambari do"
echo "  # chkconfig ambari off"
echo
echo "===================================="