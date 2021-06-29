#!/bin/bash
# ##########################################################
# pool-update-tx.sh
# Creates a stake-pool update cert and builds the signed
# transaction to submit it to the Cardano blockchain.
# The output file is named update-pool-tx.signed
# 
# requires the wallet keys extracted, and payment address
# having enough balance to pay the transaction fee.
# This needs the node cold keys node.vkey and node.skey
# curl, and the URL for the pools metadata JSON file.
#
# Connects to a synced cardano node (using Dadalus wallet
# node of the local system with ENV CARDANO_NODE_SOCKET_PATH
# ="~/.local/share/Daedalus/mainnet/cardano-node.socket")
# for balance checks and transaction fee calculation.
#
# Note: The stake delegation cert may not be needed here,
#       delegation does not change. TODO - test without
#
# Usage:
# ./pool-update-tx.sh ~/my-wallet
# ##########################################################
# ATTENTION: Manual transaction generation is dangerous !!!!
# !! Unintented key access may cause loss of funds !!!!!!!!!
# !! Wrong execution, typos etc may cause loss of funds !!!!
# ##########################################################

# Synced Cardano node CLI connect info
SOCK="CARDANO_NODE_SOCKET_PATH=$HOME/.local/share/Daedalus/mainnet/cardano-node.socket"
export "$SOCK"
ONLINECLI="$HOME/bin/cardano-cli"
OUTFILE="update-pool-tx.signed"
POOLCERT="pool-update.cert"
DELECERT="stake-delegation.cert"

# ####################################################
# the relay data is set through editing this script...
# ####################################################
relay_data="--single-host-pool-relay relay.fm4dd.com \
--pool-relay-port 5513"

# Redundand relays are recommended, example setting two:
#relay_data="--single-host-pool-relay relay1.fm4dd.com \
#--pool-relay-port 5513 \
#--single-host-pool-relay relay2.fm4dd.com \
#--pool-relay-port 5512"

# ####################################################
# Check cmdline args: wallet dir, e.g. "~/my-wallet"
# ####################################################
[[ "$#" -ne 1 ]] && {
       echo "usage: `basename $0` <wallet-dir>" >&2
       exit 127
}

# ####################################################
# Assign the 1st parameter as the wallet directory
# ####################################################
#WALLET="/home/pi/wallet-keys"
WALLET="$1"
[[ ! -d "$WALLET"  ]] && {
    echo "Error: \"$WALLET\" folder not found, exiting..." >&2
    exit 127
}

# ###############################################
# Prerequisites - Exit if we miss any keys
# ###############################################
[[ ! -f "$WALLET"/node.vkey ]] && { echo "missing node.vkey, exit"; exit; }
[[ ! -f "$WALLET"/node.skey ]] && { echo "missing node.skey, exit"; exit; }
[[ ! -f "$WALLET"/stake.vkey ]] && { echo "missing stake.vkey, exit"; exit; }
[[ ! -f "$WALLET"/stake.skey ]] && { echo "missing stake.skey, exit"; exit; }
[[ ! -f "$WALLET"/payment.addr ]] && { echo "missing payment.addr, exit"; exit; }
[[ ! -f "$WALLET"/payment.skey ]] && { echo "missing payment.skey, exit"; exit; }

# ####################################################
# Get the latest version of the metadata JSON file
# and save it into local temp file poolMetaData.json
# Ask for the URL to download the latest version:
# ####################################################
echo "Download the latest poolMetaData.json file."
read -p "Enter URL (e.g. http://tama.fm4dd.com/meta.json): " meta_json_url
if [ -z "$meta_json_url" ]; then
    echo "Error getting poolMetaData.json URL, exit"
    exit
fi

/usr/bin/curl -s -L -o poolMetaData.json $meta_json_url
[[ ! -f poolMetaData.json ]] && ( echo "Error downloading poolMetaData.json file, exit"; exit; )

# ####################################################
# Create the file hash from poolMetaDataHash.txt, and
# save it into local temp file poolMetaDataHash.txt
# ####################################################
$ONLINECLI stake-pool metadata-hash \
--pool-metadata-file poolMetaData.json > poolMetaDataHash.txt

[[ ! -f poolMetaDataHash.txt ]] && { echo "Error creating poolMetaDataHash file, exit"; exit; }
echo "Created poolMetaData hash: `cat poolMetaDataHash.txt`"

# ####################################################
# Query for the pool operation paramters: pool cost
# ####################################################
echo "Enter the pool cost amount in ADA (e.g. 340)."
read -p "Enter ADA, or return for default 340 : " pool_cost_ada
if [ -z "$pool_cost_ada" ]; then
    pool_cost=$(( 340 * 1000000 ))
else
    pool_cost=$(( ${pool_cost_ada} * 1000000 ))
fi
echo "Set pool cost value: $pool_cost"

# ####################################################
# Query for the pool operation paramters: pool pledge
# ####################################################
echo "Enter the pool pedge amount in ADA (e.g. 2000)."
read -p "Enter ADA, or return for default 1000 : " pool_pledge_ada
if [ -z "$pool_pledge_ada" ]; then
    pool_pledge=$(( 1000 * 1000000 ))
else
    pool_pledge=$(( ${pool_pledge_ada} * 1000000 ))
fi
echo "Set pool pledge value: $pool_pledge"

# ####################################################
# Query for the pool operation paramters: pool margin
# ####################################################
echo "Enter the pool margin 0..1 (e.g. 0.01 = 1%)."
read -p "Enter value, or return for default 0.01 : " pool_margin
if [ -z "$pool_margin" ]; then
    pool_margin="0.01"
fi
echo "Set pool margin value: $pool_margin"

echo "Using relay parameter: $relay_data"
# ####################################################
# Create the pool update file (pool certificate)
# ####################################################
$ONLINECLI stake-pool registration-certificate \
--cold-verification-key-file "$WALLET"/node.vkey \
--vrf-verification-key-file "$WALLET"/vrf.vkey \
--pool-reward-account-verification-key-file "$WALLET"/stake.vkey \
--pool-owner-stake-verification-key-file "$WALLET"/stake.vkey \
--pool-cost $pool_cost \
--pool-pledge $pool_pledge \
--pool-margin $pool_margin \
--metadata-url $meta_json_url \
--metadata-hash $(cat poolMetaDataHash.txt) \
$relay_data \
--mainnet \
--out-file $POOLCERT

[[ ! -f "$POOLCERT" ]] && { echo "Error creating pool update file, exit"; exit; }
echo "Created pool update file: `ls -l $POOLCERT`"

# ###############################################
# Create the stake delegation file (certificate)
# ###############################################
$ONLINECLI stake-address delegation-certificate \
--stake-verification-key-file "$WALLET"/stake.vkey \
--cold-verification-key-file "$WALLET"/node.vkey \
--out-file $DELECERT
[[ ! -f "$DELECERT" ]] && { echo "Error creating stake delegation file, exit"; exit; }
echo "Created stake delegation file: `ls -l $DELECERT`"

# ###############################################
# How long should the transaction be valid?
# ###############################################
echo "Define a expiration for this transaction."
read -p 'Choose expiry time in seconds (default=10800 - 3hrs): ' exp_sec
if [ -z "$exp_sec" ]; then
    exp_sec=10800
fi
echo "Using transaction expiration time: $exp_sec"

# ###############################################
# Find the current slot of the blockchain to use
# for calculation of the invalid-thereafter value
# ###############################################
currentSlot=$($ONLINECLI query tip --mainnet | jq -r '.slot')
echo "Current Slot: $currentSlot"

# ###############################################
# Get the payment address transactions
# ###############################################
payAddr=$(cat "$WALLET"/payment.addr)
echo "Payment Addr: $payAddr"
BalanceOut=$($ONLINECLI query utxo --address $payAddr --mainnet | tail -n +3 | sort -k3 -nr)

# ###############################################
# Check if payment address returned any balance
# ###############################################
if [[ $BalanceOut != *"lovelace"* ]] ; then
    echo "Error: No balance for address $payAddr, exiting..."
    exit 127
fi
echo "Got balance of $payAddr"

# ###############################################
# Calculate the payment address balance
# ###############################################
tx_in=""
total_balance=0
txcnt=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    echo "Incoming->Tx: ${in_addr}#${idx} ADA: ${utxo_balance}"
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
    let "txcnt=txcnt+1"
done <<< "$BalanceOut"
echo "Addr Balance: ${total_balance} from UTXOs: ${txcnt}"

# ###############################################
# Build raw transaction file tx.tmp to get fee
# ###############################################
$ONLINECLI transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"0"  \
    --certificate-file "$POOLCERT" \
    --certificate-file "$DELECERT" \
    --fee 0 \
    --invalid-hereafter $((${currentSlot} + ${exp_sec})) \
    --mary-era \
    --out-file tx.tmp
[[ ! -f tx.tmp ]] && { echo "missing tx.tmp, exiting..."; exit; }
echo "TX inputfile: `ls -l tx.tmp`"

# ###############################################
# Get the protocol parameter file
# ###############################################
$ONLINECLI query protocol-parameters --mainnet > params.json

# ###############################################
# Calculate the minimum fee
# ###############################################
fee=$($ONLINECLI transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo "Transact Fee: $fee"

# ###############################################
# Calculate the balance after transaction fee
# ###############################################
txOut=$((${total_balance}-${fee}))
echo "ADA after TX: ${txOut}"

# ###############################################
# Build the final transaction with two certs
# ###############################################
 $ONLINECLI transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"$txOut"  \
    --invalid-hereafter $(( ${currentSlot} + ${exp_sec})) \
    --fee ${fee} \
    --certificate-file "$POOLCERT" \
    --certificate-file "$DELECERT" \
    --mary-era \
    --out-file tx.raw
[[ ! -f tx.raw ]] && { echo "missing tx.raw, exiting..."; exit; }
echo "TX inputfile: `ls -l tx.raw`"

# ###############################################
# Sign transaction with payment, node, stake.skey
# ###############################################
$ONLINECLI transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file "$WALLET"/payment.skey \
    --signing-key-file "$WALLET"/node.skey \
    --signing-key-file "$WALLET"/stake.skey \
    --mainnet \
    --out-file "$OUTFILE"
[[ -f "$OUTFILE" ]] && echo "Created signed transaction $OUTFILE"
echo
echo "executing temp file cleanup: rm params.json poolMetaData.json poolMetaDataHash.txt tx.raw tx.tmp"
rm params.json poolMetaData.json poolMetaDataHash.txt tx.raw tx.tmp
echo "To submit, type: "
echo "$ONLINECLI transaction submit --tx-file $OUTFILE --mainnet"
