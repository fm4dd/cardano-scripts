#!/bin/bash
# ##########################################################
# withdraw-rewards-tx.sh
# Creates a signed transaction to withdraw all rewards from
# the stake rewards address into the payment address.
# The output file is named withdraw-rewards-tx.signed
# 
# requires the wallet keys extracted, and the target
# payment address has enough balance to pay for the
# transaction fee.
#
# Connects to a synced cardano node over SSH for
# balance checks and transaction fee calculation.
#
# Usage:
# ./withdraw-rewards-tx.sh ~/h2-wallet
# ##########################################################
# ATTENTION: Manual transaction generation is dangerous !!!!
# !! Unintented key access may cause loss of funds !!!!!!!!!
# !! Wrong execution, typos etc may cause loss of funds !!!!
# ##########################################################

# Synced Cardano node CLI connect info, remote host
SSHTARGET="pi@192.168.1.22"
ONLINECLI="/home/pi/cardano/relay/bin/cardano-cli"
SOCK="CARDANO_NODE_SOCKET_PATH=/home/pi/cardano/relay/node.sock"
# Synced Cardano node CLI connect info, local Daedalus
#export CARDANO_NODE_SOCKET_PATH="~/.local/share/Daedalus/mainnet/cardano-node.socket"
#ONLINECLI="~/cardano-wallet-linux64/cardano-cli"
# for CLI commands that don't need blockchain lookup
CCLI="~/bin/cardano-cli"
OUTFILE="withdraw-rewards-tx.signed"

# ####################################################
# Check cmdline args: wallet dir stake-stop.cert file
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
# Prerequisites - Exit if we miss any files
# ###############################################
[[ ! -f "$WALLET"/payment.addr ]] && { echo "missing payment.addr, exit"; exit; }
[[ ! -f "$WALLET"/stake.addr ]] && { echo "missing stake.addr, exit"; exit; }
[[ ! -f "$WALLET"/stake.skey ]] && { echo "missing stake.skey, exit"; exit; }
[[ ! -f "$WALLET"/payment.skey ]] && { echo "missing payment.skey, exit"; exit; }

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
currentSlot=$(ssh ${SSHTARGET}  "export $SOCK && $ONLINECLI query tip --mainnet" | jq -r '.slot')
echo "Current Slot: $currentSlot"

# ###############################################
# Get the stake address rewards output
# ###############################################
stakeAddr=$(cat "$WALLET"/stake.addr)
echo "Rewards Addr: $stakeAddr"
RewardsOut=$(ssh ${SSHTARGET}  "export $SOCK && $ONLINECLI query stake-address-info --address ${stakeAddr} --mainnet")
echo "Rewards output"
echo "$RewardsOut"

# ###############################################
# Check if stake address returned any rewards,
# e.g.    "rewardAccountBalance": 5395880,
# ###############################################
if [[ $RewardsOut != *"rewardAccountBalance"* ]] ; then
    echo "Error: No balance for address $stakeAddr, exiting..."
    exit 127
fi
echo "Got balance of $stakeAddr"
rewards=$(echo "$RewardsOut" | grep "rewardAccountBalance" | awk '{ print $2 }' | tr -d ,)
echo "Rewards Balance: $rewards"

# ###############################################
# Get the payment address transactions
# ###############################################
payAddr=$(cat "$WALLET"/payment.addr)
echo "Payment Addr: $payAddr"
BalanceOut=$(ssh ${SSHTARGET}  "export $SOCK && $ONLINECLI query utxo --address $payAddr --mainnet" | tail -n +3 | sort -k3 -nr)

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
$CCLI transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"0"  \
    --withdrawal "$stakeAddr"+"0" \
    --fee 0 \
    --invalid-hereafter $((${currentSlot} + ${exp_sec})) \
    --mary-era \
    --out-file tx.tmp
echo "TX inputfile: `ls -l tx.tmp`"

# ###############################################
# Get params file
# ###############################################
ssh ${SSHTARGET}  "export $SOCK && $ONLINECLI query protocol-parameters --mainnet" > params.json

# ###############################################
# Calculate the minimum fee
# ###############################################
fee=$("$CCLI" transaction calculate-min-fee \
    --tx-body-file tx.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --mainnet \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file params.json | awk '{ print $1 }')
echo "Transact Fee: $fee"

# ###############################################
# Calculate the remaining balance
# ###############################################
txOut=$((${total_balance}-${fee}+${rewards}))
echo "ADA after TX: ${txOut}"

# ###############################################
# Build the final transaction
# ###############################################
"$CCLI" transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"$txOut"  \
    --withdrawal "$stakeAddr"+"$rewards" \
    --fee ${fee} \
    --invalid-hereafter $((${currentSlot} + ${exp_sec})) \
    --mary-era \
    --out-file tx.raw
echo "TX inputfile: `ls -l tx.raw`"

# ###############################################
# Sign transaction with payment.skey & stake.skey
# ###############################################
"$CCLI" transaction sign \
    --tx-body-file tx.raw \
    --signing-key-file "$WALLET"/payment.skey \
    --signing-key-file "$WALLET"/stake.skey \
    --mainnet \
    --out-file "$OUTFILE"
[[ -f "$OUTFILE" ]] && echo "Created signed transaction file $OUTFILE"
echo
echo "executing temp file cleanup: rm params.json tx.raw tx.tmp"
rm params.json tx.raw tx.tmp
echo "Copy the transaction to the synced cardano node, and submit: "
echo "scp $OUTFILE $SSHTARGET:~/cardano"
echo "$ONLINECLI transaction submit --tx-file $OUTFILE --mainnet"
