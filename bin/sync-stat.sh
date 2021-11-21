#!/bin/bash
# ###############################################
# sync-stat.sh:
# This script checks the sync status of a cardano
# node. It uses the node to get the latest tip,
# and matches it against the expected slot number
# based on the cardano epoch and slot lengths.
#
# Example run:
# pi@lp-ms02:~$ cardano/relay/bin/sync-stat.sh
# Node sync: 99.9999% slot 45896211/45896223 slot-diff -12
#
# I run it through .bashrc at login time for quick status.
# .bashrc code block:
# -------------------
# export CARDANO_NODE_SOCKET_PATH=/home/pi/cardano/relay/node.sock
# 
# PID1=`pidof /home/pi/cardano/producer/bin/cardano-node`
# if [ $? == 1 ]; then
#   echo "Cardano producer not running!"
# else
#   echo "Cardano producer running with PID $PID1."
# fi
# PID2=`pidof /home/pi/cardano/relay/bin/cardano-node`
# if [ $? == 1 ]; then
#   echo "Cardano relay not running!"
# else
#   echo "Cardano relay running with PID $PID2."
#   /home/pi/cardano/relay/bin/sync-stat.sh
# fi
# ###############################################

HOME=/home/pi/cardano/relay
GENESIS=$HOME/etc/mainnet-shelley-genesis.json
BYRON_GENESIS=$HOME/etc/mainnet-byron-genesis.json
CLI=$HOME/bin/cardano-cli
HARDFORK_EPOCH=208
NETWORK="--mainnet"

epoch_length=$(jq -r .epochLength $GENESIS)
slot_length=$(jq -r .slotLength $GENESIS)
byron_slot_length=$(( $(jq -r .blockVersionData.slotDuration $BYRON_GENESIS) / 1000 ))
byron_epoch_length=$(( $(jq -r .protocolConsts.k $BYRON_GENESIS) * 10 ))

byron_start=$(jq -r .startTime $BYRON_GENESIS)
byron_end=$((byron_start + HARDFORK_EPOCH * byron_epoch_length * byron_slot_length))
byron_slots=$(($HARDFORK_EPOCH * byron_epoch_length))
now=$(date +'%s')

expected_slot=$((byron_slots + (now - byron_end) / slot_length))
current_slot=$($CLI query tip $NETWORK | jq -r '.slot')

if [[ $current_slot == *"<socket: 11>: does not exist"* ]]; then
  echo "No network socket found, is relay starting up?"
  exit
fi

percent=$(echo "scale=4; $current_slot * 100 / $expected_slot" | bc)
offset=$((expected_slot-current_slot))
echo "Node sync: ${percent}% slot ${current_slot}/${expected_slot} slot-diff -$offset"
