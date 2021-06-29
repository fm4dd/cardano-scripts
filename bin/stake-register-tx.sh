#!/bin/bash
# ##########################################################
# stake-register-tx.sh
# Takes a stake-address registration cert and builds a
# signed transaction to submit to the Cardano blockchain
# The output file is named stake-register-tx.signed
# 
# Requires the wallet keys extracted, and the payment
# address with enough balance to pay the transaction fee.
#
# Connects to a synced cardano node (using Dadalus wallet
# node of the local system with ENV CARDANO_NODE_SOCKET_PATH
# ="~/.local/share/Daedalus/mainnet/cardano-node.socket")
# for balance checks and transaction fee calculation.
#
# Usage:
# ./stake-register-tx.sh ~/my-wallet
# ##########################################################
# ATTENTION: Manual transaction generation is dangerous !!!!
# !! Unintented key access may cause loss of funds !!!!!!!!!
# !! Wrong execution, typos etc may cause loss of funds !!!!
# ##########################################################

# Synced Cardano node CLI connect info
SOCK="CARDANO_NODE_SOCKET_PATH=$HOME/.local/share/Daedalus/mainnet/cardano-node.socket"
export "$SOCK"
ONLINECLI="$HOME/bin/cardano-cli"
OUTFILE="stake-register-tx.signed"
CERT="key-registration.cert"

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
[[ ! -f "$WALLET"/stake.vkey ]] && { echo "missing node.vkey, exit"; exit; }
[[ ! -f "$WALLET"/stake.skey ]] && { echo "missing node.skey, exit"; exit; }
[[ ! -f "$WALLET"/stake.addr ]] && { echo "missing stake.addr, exit"; exit; }
[[ ! -f "$WALLET"/payment.addr ]] && { echo "missing payment.addr, exit"; exit; }
[[ ! -f "$WALLET"/payment.skey ]] && { echo "missing payment.skey, exit"; exit; }

# ###############################################
# Create key registration file (certificate)
# ###############################################
$ONLINECLI stake-address registration-certificate \
--stake-verification-key-file "$WALLET"/stake.vkey \
--out-file $CERT
[[ ! -f "$CERT" ]] && { echo "Error creating registration file, exit"; exit; }
echo "Created stake key registration file: `ls -l $CERT`"

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
else
    echo "Got balance of $payAddr"
fi

# ###############################################
# Calculate the payment address balance
# ###############################################
tx_in=""
dst_balance=0
txcnt=0
while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    dst_balance=$((${dst_balance}+${utxo_balance}))
    echo "Incoming->Tx: ${in_addr}#${idx} ADA: ${utxo_balance}"
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
    let "txcnt=txcnt+1"
done <<< "$BalanceOut"
echo "Addr Balance: ${dst_balance} from UTXOs: ${txcnt}"

echo "DstAddr Balance: $dst_balance"
echo "Rewards Balance: $rewards_bal"

# ###############################################
# Build raw transaction file tx.tmp to get fee
# ###############################################
$ONLINECLI transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"0"  \
    --certificate-file "$CERT" \
    --fee 0 \
    --invalid-hereafter $((${currentSlot} + ${exp_sec})) \
    --mary-era \
    --out-file tx.tmp
[[ ! -f tx.tmp ]] && { echo "missing tx.tmp, exiting..."; exit; }
echo "TX inputfile: `ls -l tx.tmp`"

# ###############################################
# Get params file
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
deposit=2000000
txOut=$((${dst_balance}-${fee}-${deposit}))
echo "ADA after TX: ${txOut}"

# ###############################################
# Build the final transaction
# ###############################################
$ONLINECLI transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"$txOut"  \
    --invalid-hereafter $(( ${currentSlot} + ${exp_sec})) \
    --fee ${fee} \
    --certificate-file "$CERT" \
    --mary-era \
    --out-file tx.raw
[[ ! -f tx.raw ]] && { echo "missing tx.raw, exiting..."; exit; }
echo "TX inputfile: `ls -l tx.raw`"

# ###############################################
# Sign transaction with payment.skey & stake.skey
# ###############################################
$ONLINECLI transaction sign \
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
echo "$ONLINECLI transaction submit --tx-file $OUTFILE --mainnet"
