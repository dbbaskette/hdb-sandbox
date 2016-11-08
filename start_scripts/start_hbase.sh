#!/bin/bash

chkconfig hbase-starter on
service hbase-starter start

echo "===================================="
echo
echo "HBase autostart enabled"
echo "To disable auto-start of HBase do"
echo "  # chkconfig hbase-starter off"
echo
echo "===================================="