#!/bin/bash
# ##########################################################
# stake-deregister-tx.sh
# Takes a stake-address deregistration cert and builds a
# signed transaction to submit to the Cardano blockchain
# The output file is named stake-stop-tx.signed
# 
# requires the wallet keys extracted, the cert file
# created with cardano-cli stake-address \
# deregistration-certificate, and the payment address
# with enough balance to pay the transaction fee.
#
# Connects to a synced cardano node over SSH for
# balance checks and transaction fee calculation.
#
# Usage:
# ./create_stake_dereg_tx.sh ~/h2-wallet stake-stop.cert
# ##########################################################
# ATTENTION: Manual transaction generation is dangerous !!!!
# !! Unintented key access may cause loss of funds !!!!!!!!!
# !! Wrong execution, typos etc may cause loss of funds !!!!
# ##########################################################

# Synced Cardano node CLI connect info, remote host
SSHTARGET="pi@192.168.1.22"
SOCK="CARDANO_NODE_SOCKET_PATH=/home/pi/cardano/relay/node.sock"
ONLINECLI="/home/pi/cardano/relay/bin/cardano-cli"
# for CLI commands that don't need blockchain lookup
CCLI="~/bin/cardano-cli"
OUTFILE="stake-stop-tx.signed"

# ####################################################
# Check cmdline args: wallet dir stake-stop.cert file
# ####################################################
[[ "$#" -ne 2 ]] && {
       echo "usage: `basename $0` <wallet-dir> <stake-stop.cert>" >&2
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

# ####################################################
# Assign the 2nd parameter as the deregistration cert
# ####################################################
CERT="$2"
[[ ! -f "$CERT" ]] && {
    echo "Error: Stake address deregistration cert file not found, exiting..." >&2
    exit 127
}

# ###############################################
# Prerequisites - Exit if we miss any keys
# ###############################################
[[ ! -f "$WALLET"/payment.addr ]] && { echo "missing payment.addr, exit"; exit; }
[[ ! -f "$WALLET"/stake.vkey ]] && { echo "missing stake.vkey, exit"; exit; }
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
    --certificate-file "$CERT" \
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
# Calculate the balance after transaction fee
# ###############################################
deposit=2000000
#txOut=$((${total_balance}-${fee}))
txOut=$((${total_balance}-${fee}+${deposit}))
echo "ADA after TX: ${txOut}"

# ###############################################
# Build the final transaction
# ###############################################
"$CCLI" transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"$txOut"  \
    --invalid-hereafter $(( ${currentSlot} + ${exp_sec})) \
    --fee ${fee} \
    --certificate-file "$CERT" \
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
[[ -f "$OUTFILE" ]] && echo "Created signed transaction $OUTFILE"
echo
echo "executing temp file cleanup: rm params.json tx.raw tx.tmp"
rm params.json tx.raw tx.tmp
echo "To submit, type: "
echo "scp $OUTFILE $SSHTARGET:~/cardano"
echo "$ONLINECLI transaction submit --tx-file $OUTFILE --mainnet"
