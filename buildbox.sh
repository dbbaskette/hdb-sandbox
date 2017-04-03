#!/usr/bin/env bash


PIVNETRC=.pivnetrc

if [ -f "$PIVNETRC" ]; then
  chmod 400 $PIVNETRC
  source $PIVNETRC 2>/dev/null
fi

set -e

usage_and_exit() {
  cat <<EOF
Usage: buildbox <command> [options]
Examples:
  buildbox token SAMPLEaJimQVTq2zWBYZ
  buildbox vmware
  buildbox vbox
EOF
  exit 1
}


build_sandbox(){

    echo "Building a $1 based HDB Sandbox"
    packer build -force -only=$1 hdb-sandbox.json


}

error_and_exit() {
  echo "$1" && exit 1
}

set_token() {
  [ -f "$PIVNETRC" ] && chmod 600 $PIVNETRC
  echo "export PIVNET_APIKEY=$1" > .pivnetrc
  chmod 400 $PIVNETRC
  echo "Updated Pivotal Network API Token"
}


CMD=$1 ARG=$2

if [ "token" = "$CMD" ]; then
  set_token $ARG
elif [ "vmware" = "$CMD" ]; then
  build_sandbox $CMD
elif [ "vbox" = "$CMD" ]; then
  build_sandbox $CMD
else
  usage_and_exit
fi