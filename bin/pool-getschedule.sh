#!/bin/bash
# ###############################################
# get-stake-schedule.sh:
# This script checks if the pool got any blocks
# assigned to our pool for minting in next epoch.
# Minting schedule for the next epoch is created,
# which can be queried the last day of an epoch.
#
# If the epoch was given a the first argument, it
# will be used instead of using the next epoch:
# ./get-stake-schedule.sh 258
#
# Output: This script generates a notification
# email before epoch rollover.
#
# Requires: leaderLogs.py
#
# Leader election documentation:
# Slot leaders are elected from all active pools.
# The nodes executing the election are from the top 2% stake holders.
# Election is a lottery that favors pools with the biggest stake.
# A pool can be elected for more than one slot in the next epoch.
#
# Leader election timing:
# Slot leaders are elected during the current epoch N for the next epoch N+1.
#
# Example run:
# pi@lp-ms03:~/cardano/stake-schedule$ ./get-stake-schedule.sh
# EpochStartStr: 2017-09-23T21:44:51Z
# EpochStart-TS: 1506203091
# currentDateTS: 1616645294
# Slots / Epoch: 432000
# elapsedTimeTS: 110442203
# current Epoch: 255
# elapsed Epoch: 282203
# Days of Epoch: 4
# Only at day 4 in epoch 255, exit
# On day 5 it runs the check, and we get instead this:
# Lookup result: No slots found for current epoch... :(
#
# Run through /etc/crontab
# # Check for Stakepool block assignments
# 0  8    * * * pi      /home/pi/cardano/stake-schedule/get-stake-schedule.sh > /dev/null 2>&1
#
# TODO: integrate this script with leaderLogs.py
# ###############################################
POOLID="120164*******************************************4238dc7"
VRF_SKEY="/home/pi/cardano/producer/etc/vrf.skey"
OUTFILE="/home/pi/cardano/stake-schedule/leader.log"
TIMEZONE="Asia/Tokyo"
# Notification e-mail details
RECIPIENT="public@maildomain.com"
SENDER="'blockchecker' <no-reply@maildomain.com>"

# ###############################################
# get the genesis start date of the mainnet
# and convert it into a UNIX timestamp
# ###############################################
epochStartStr=$(cat /home/pi/cardano/producer/etc/mainnet-shelley-genesis.json | jq -r '.systemStart')
echo "EpochStartStr: $epochStartStr"
epochStartTS=$(date -d $epochStartStr "+%s")
echo "EpochStart-TS: $epochStartTS"
# ###############################################
# get the current date as a UNIX timestamp
# ###############################################
currentDateTS=$(date "+%s")
echo "currentDateTS: $currentDateTS"
# ###############################################
# how many slots are in the epoch?
# In mainnet 432,000 slots/epoch (one per second)
# ###############################################
epochLength=$(cat /home/pi/cardano/producer/etc/mainnet-shelley-genesis.json | jq -r '.epochLength')
echo "Slots / Epoch: $epochLength"
# ###############################################
# calculate the elapsed time since genesis in sec
# ###############################################
elapsedTimeTS=`expr $currentDateTS - $epochStartTS`
echo "elapsedTimeTS: $elapsedTimeTS"
# ###############################################
# get current epoch elapsedTimeTS / $epochLength
# ###############################################
currentEpoch=`expr $elapsedTimeTS / $epochLength`
echo "current Epoch: $currentEpoch"
# ###############################################
# get day of current epoch elapsedEpoch / 86400
# ###############################################
elapsedEpoch=`expr $elapsedTimeTS % $epochLength`
echo "elapsed Epoch: $elapsedEpoch"
daysofEpoch=`expr $elapsedEpoch / 86400`
echo "Days of Epoch: $(expr $daysofEpoch + 1)"
# ###############################################
# Check if today is the last day of the epoch
# Exit if its not yet the last day
# ###############################################
if  [ -z "$1" ] && [ $(expr $daysofEpoch + 1) -ne 5  ]; then
    echo "Only at day $(expr $daysofEpoch + 1) in epoch $currentEpoch, exit"
    exit
fi

# ###############################################
# Check if epoch was given as the 1st argument
# ###############################################
if [ -n "$1" ]; then
   checkEpoch=$1
else
   checkEpoch=$(expr $currentEpoch + 1)
fi
echo "Run for Epoch: $checkEpoch"
# ###############################################
# query for current epoch block schedule to
# https://api.crypto2099.io/v1/sigma/[pool]/[epoch]
# ###############################################
EXECUTE="/home/pi/cardano/stake-schedule/leaderLogs.py \
--pool-id $POOLID \
--tz $TIMEZONE \
--vrf-skey $VRF_SKEY\
--epoch $checkEpoch"
echo "leaderLogs.py: $EXECUTE"
${EXECUTE} > $OUTFILE
# ###############################################
# Check Lookup result from logfile
# ###############################################
#FILECHECK="ls -l $OUTFILE"
#print "Response File:" ${FILECHECK}
CONTENTS=$(cat ${OUTFILE})
echo "$CONTENTS" | grep 'Lookup result: '
# ###############################################
# Send notification email
# ###############################################
SUBJECT="Pool Block Check for Epoch $checkEpoch"

/usr/sbin/ssmtp -t << EOF
To: $RECIPIENT
From: $SENDER
Subject: $SUBJECT

$CONTENTS
EOF
