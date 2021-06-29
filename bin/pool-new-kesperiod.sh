#!/bin/bash
# ##########################################################
# pool-new-kesperiod.sh
# Creates a new operational cert with updated expiration.
# Current validity, specified in the protocol, is 93 days.
# Existing KES keys can be re-used if the node system is 
# not compromised. Each new cert gets new issuer # (serial)
# and start date measured in KES periods. The output file
# is named pool-producer-ops.cert
# 
# Its possible to create invalid certs, e.g. with a empty
# period. A invalid cert prevents the producer node from
# starting up. Errors are "TraceForgeStateUpdateError" or
# "KESKeyAlreadyPoisoned" "startPeriod" Number 0.0.
#
# Requires the pool node cold keys and kes key files in
# inside a pool key directory, and a genesis file
#
# Connects to a synced cardano node (using Dadalus wallet
# node of the local system with ENV CARDANO_NODE_SOCKET_PATH
# ="~/.local/share/Daedalus/mainnet/cardano-node.socket")
# for balance checks and transaction fee calculation.
#
# Usage:
# ./pool-new-kesperiod.sh ~/pool-key-dir
# ##########################################################

# Synced Cardano node CLI connect info
SOCK="CARDANO_NODE_SOCKET_PATH=$HOME/.local/share/Daedalus/mainnet/cardano-node.socket"
export "$SOCK"
ONLINECLI="$HOME/bin/cardano-cli"
CERT="pool-producer-ops.cert"
# The path for the genesis file to calculate KES periods
genesisfile="$HOME/cardano/conf/shelley-genesis.json"

# ####################################################
# Check cmdline args: pool dir, e.g. "~/pool-key-dir"
# ####################################################
[[ "$#" -ne 1 ]] && {
       echo "usage: `basename $0` <pool-key-dir>" >&2
       exit 127
}

# ####################################################
# Assign the 1st parameter as the wallet directory
# ####################################################
COLDDIR="$1"
[[ ! -d "$COLDDIR"  ]] && {
    echo "Error: \"$COLDDIR\" folder not found, exiting..." >&2
    exit 127
}

# ###############################################
# Prerequisites - Exit if we miss any keys or cli
# ###############################################
[[ ! -f "$ONLINECLI" ]] && { echo "missing $ONLINECLI binary, exit"; exit; }
[[ ! -f "$COLDDIR"/node.counter ]] && { echo "missing $COLDDIR/node.counter, exit"; exit; }
[[ ! -f "$COLDDIR"/node.skey ]] && { echo "missing $COLDDIR/node.skey, exit"; exit; }
[[ ! -f "$COLDDIR"/kes.vkey ]] && { echo "missing $COLDDIR/kes.vkey, exit"; exit; }
[[ ! -f "$genesisfile" ]] && { echo "missing $genesisfile, exit"; exit; }

# #######################################################
# Get the next certs issue number from the counter file
# #######################################################
nextKESnumber=$(cat $COLDDIR/node.counter | awk 'match($0,/Next certificate issue number: [0-9]+/) {print substr($0, RSTART+31,RLENGTH-31)}')
echo "Create ops cert number: $nextKESnumber"

# #######################################################
# If we find a previous cert, archive it
# #######################################################
if [ -f "$COLDDIR/$CERT" ]; then
  oldKESnumber="$(($nextKESnumber-1))"
  oldCertname="producer-$oldKESnumber.cert"
  mv $COLDDIR/producer.cert $COLDDIR/$oldCertname
  echo "Archived old cert file: $COLDDIR/$oldCertname"
fi

# #######################################################
# 1. Determine # slots per KES period from genesis file
# cat shelley-genesis.json | jq -r .slotsPerKESPeriod
# --> 129600
# #######################################################
slotsPerKESPeriod=$(cat ${genesisfile} | jq -r .slotsPerKESPeriod)
echo "#Slots/KESPeriod Value: $slotsPerKESPeriod"

# #######################################################
# 2. Get latest Slot-# from a fully synced online node
# #######################################################
# cat shelley-genesis.json | jq -r .slotLength --> 1
# debug:
#echo "ssh ${SSHTARGET}  "export $SOCK && /home/pi/cardano/relay/bin/cardano-cli query tip --mainnet" | jq -r '.slot'
slot=$($ONLINECLI query tip --mainnet | jq -r '.slot')
echo "Found the latest Slot#: $slot"

 #######################################################
# 3. Calculate the latest kesPeriod
# #######################################################
currentKESperiod=$((${slot} / ${slotsPerKESPeriod}))
# Get current time in seconds since epoch (UTC)
currentTimeSec=$(date -u +%s)
currentDate=$(date --date=@${currentTimeSec})
echo "The current KES period: $currentKESperiod ($currentDate)"

# #######################################################
# Calculate the expiration KES Period and Date/Time
# cat shelley-genesis.json | jq -r .maxKESEvolutions
# --> 62
# #######################################################
maxKESEvolutions=$(cat ${genesisfile} | jq -r .maxKESEvolutions)
# Calculate expiration KES period: current period + maxKESEvolutions
expireKESperiod=$(( ${currentKESperiod} + ${maxKESEvolutions} ))

# Calculate expiration date as seconds from epoch
slotLength=$(cat ${genesisfile} | jq -r .slotLength)
# ExpireTimeSec: timestamp now plus 1 * 129600 * 62
expireTimeSec=$(( ${currentTimeSec} + ( ${slotLength} * ${slotsPerKESPeriod} * ${maxKESEvolutions} ) ))
# convert seconds from epoch timestamp to date string
expireDate=$(date --date=@${expireTimeSec})

echo "Valid until KES period: $expireKESperiod ($expireDate)"

# #######################################################
# Call the cardano-cli command for certificate creation
# outputs the certificate producer.cert into the cold dir
# #######################################################
$ONLINECLI node issue-op-cert \
--hot-kes-verification-key-file $COLDDIR/kes.vkey \
--cold-signing-key-file $COLDDIR/node.skey \
--operational-certificate-issue-counter $COLDDIR/node.counter \
--kes-period ${currentKESperiod} --out-file $COLDDIR/$CERT

if [ ! -f "$COLDDIR/$CERT" ]; then echo "Failed to create $COLDDIR/$CERT"; exit; fi
PRODUCER="pool@192.168.11.23"
echo "Successfully created $COLDDIR/$CERT"
echo "Now copy the new cert to the producer node, e.g.:"
echo "scp $COLDDIR/$CERT $PRODUCER:~/cardano/producer/etc/producer.cert.new"
echo "ssh $PRODUCER mv ~/cardano/producer/etc/producer.cert ~/cardano/producer/etc/producer.cert.orig"
echo "ssh $PRODUCER mv ~/cardano/producer/etc/producer.cert.new ~/cardano/producer/etc/producer.cert"
