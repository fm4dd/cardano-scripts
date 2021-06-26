#!/bin/bash
# ##########################################################
# transfer-wallet-tx.sh
# Creates a signed transaction to withdraw all funds from
# all address in the wallet with a single transaction.
# Remaining wallet balance will be zero. This assumes that
# the rewards address is already 0.
#
# The output file is named transfer-wallet-tx.signed
# 
# Requires the wallet root keys extracted, and the wallet
# having one payment address with enough balance to pay for
# the transaction fee.
#
# Connects to a synced cardano node (using Dadalus wallet
# node of the local system with ENV CARDANO_NODE_SOCKET_PATH
# ="~/.local/share/Daedalus/mainnet/cardano-node.socket")
# for balance checks and transaction fee calculation.
#
# Needs cardano-wallet for key derivation commands
# see: https://github.com/input-output-hk/cardano-wallet
#
# Usage:
# ./transfer-wallet-tx.sh ~/my-wallet
# ##########################################################
# ATTENTION: Manual transaction generation is dangerous !!!!
# !! Unintented key access may cause loss of all funds !!!!!
# !! Wrong execution, typos bugs may cause loss of funds !!!
# !! Testing this script has not checked all eventualities !
# ##########################################################

# Synced Cardano node CLI connect info
SOCK="CARDANO_NODE_SOCKET_PATH=$HOME/.local/share/Daedalus/mainnet/cardano-node.socket"
export "$SOCK"
ONLINECLI="$HOME/bin/cardano-cli"
OUTFILE="transfer-wallet-tx.signed"

# ####################################################
# Set the path to the wallet binaries
# ####################################################
CADDR="$HOME/cardano-wallet-linux64/cardano-address"
BECH32="$HOME/cardano-wallet-linux64/bech32"
[[ -z "$CADDR" ]] && { echo "cardano-address cannot be found, exiting..." >&2 ; exit 127; }
[[ -z "$BECH32" ]] && { echo "bech32 cannot be found, exiting..." >&2 ; exit 127; }

# ####################################################
# Check cmdline args: wallet dir
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
[[ ! -f "$WALLET"/root.prv ]] && { echo "missing root.prv, exiting..."; exit; }

# ####################################################
# Derive wallet stake extended public key stake.xpub
# Needed to generate Daedalus-wallet delegation addr
# ####################################################
SXPUB=$(cat "$WALLET/root.prv" |\
"$CADDR" key child 1852H/1815H/0H/2/0 |\
"$CADDR" key public --with-chain-code)
if [ -z "$SXPUB" ]; then
    echo "Error: unable to generate stake extended public key, exiting..."
    exit
fi
echo "Stake pubkey: $SXPUB"

# ###############################################
# Derive wallet payment public keys, check funds
# Daedalus wallet shows by default 1st 30 address
# ###############################################
declare -a addrlist=("0/0" "1/0" "0/1" "1/1" "0/2" "1/2" "0/3" "1/3" "0/4" "1/4"
                     "0/5" "1/5" "0/6" "1/6" "0/7" "0/8" "0/9" "0/10" "0/11" "0/12"             
                     "0/13" "0/14" "0/15" "0/16" "0/17" "0/18" "0/19"
                     "0/20" "0/21" "0/22" "0/23" "0/24" "0/25" "0/26")

declare -i wallet_balance
declare -a wallet_addr
declare -a wallet_tx
declare -i wallet_bal
declare -a wallet_skeys

echo "checking Wallet balance:"
for SUB in "${addrlist[@]}"; do
   # create ext sigining key
   ADDR_XPRIV=$(cat "$WALLET/root.prv" |\
   "$CADDR" key child 1852H/1815H/0H/$SUB)
   # create ext verification key
   ADDR_XPUB=$(echo $ADDR_XPRIV |\
   "$CADDR" key public --with-chain-code)
   # create address (daedalus deleg format)
   ADDR=$(echo $ADDR_XPUB |\
   "$CADDR" address payment --network-tag mainnet |\
   "$CADDR" address delegation $SXPUB)
   echo -n "key child 1852H/1815H/0H/$SUB - $ADDR"

   ADDRBAL=$("$ONLINECLI" query utxo --address $ADDR --mainnet | tail -n +3 | sort -k3 -nr)
   
   # ############################################
   # Check if address has any balance
   # ############################################
   if [ "$ADDRBAL" != "" ]; then
      # Get the balance of the address
      VAL=$(echo $ADDRBAL| cut -c 68- |cut -d ' ' -f 1)
      echo " Balance [$VAL]"
      #echo "$ADDRBAL"
 
      # add the address to the non-empty address list  
      wallet_addr+=("$ADDR")
      # add the balance to the list of individual funds
      wallet_bal+=("$VAL")

      # write address signing key to temp skey files
      #echo "priv: $ADDR_XPRIV"
      #echo "pub:  $ADDR_XPUB"
      PESKEY=$(echo $ADDR_XPRIV  | "$BECH32" | cut -b -128 )$(echo $ADDR_XPUB | "$BECH32")
      skey_file="wallet-${#wallet_tx[@]}.skey"
      wallet_skeys+=("$skey_file")
      cat << EOF > $skey_file
{
    "type": "PaymentExtendedSigningKeyShelley_ed25519_bip32",
    "description": "Payment Signing Key",
    "cborHex": "5880$PESKEY"
}
EOF
      # get the transaction ID and transaction index
      addr_used_tx=$(awk '{ print $1 }' <<< "${ADDRBAL}")
      addr_used_idx=$(awk '{ print $2 }' <<< "${ADDRBAL}")
      wallet_tx+=("$addr_used_tx#$addr_used_idx")

      # count fund towards wallet balance
      let "wallet_balance = $wallet_balance + $VAL"
      let "addr_counter = $addr_counter + 1"
   else
      echo # if the address has no balance, send newline
   fi
done
echo

# ###############################################
# Exit if the wallet is completely empty
# ###############################################
if [ ${#wallet_addr[@]} -eq 0 ]; then
    echo "Error: No balance found to transfer, ...exiting"
    exit
fi
echo "Wallet Balance: $wallet_balance found in ${#wallet_addr[@]} address entries"

# ###############################################
# Input destination payment address
# ###############################################
echo "Enter receiving address for wallet funds addr1q9********************* (104-character address)"
read -p 'Payment Addr: ' payAddr

if [ -z "$payAddr" ]; then
   echo "Error: Please enter the dest payment address e.g. addr1q*****; exiting..."
   exit
fi

# ###############################################
# Get the destination payment addr transactions
# ###############################################
BalanceOut=$($ONLINECLI query utxo --address $payAddr --mainnet | tail -n +3 | sort -k3 -nr)
echo "Dest Addr OK: $payAddr"

# ###############################################
# Calculate dest payment address balance
# ###############################################
dst_balance=0       # total balance of dest addr
txcnt=0             # count of tx in dest addr
while read -r utxo; do
    dst_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    if [ ! -z "$utxo_balance" ]; then
        dst_balance=$((${dst_balance}+${utxo_balance}))
        echo "Incoming->Tx: ${dst_addr}#${idx} ADA: ${utxo_balance}"
        let "txcnt = $txcnt + 1"
    fi
done <<< "$BalanceOut"
echo "Addr Balance: ${dst_balance} in ${txcnt} UTXO's"

# ###############################################
# How long should the transaction be valid?
# ###############################################
echo "Define a expiration for this transaction."
read -p 'Choose expiry time in seconds (default=10800 - 3hrs): ' exp_sec
if [ -z "$exp_sec" ]; then
    exp_sec=10800
fi
echo "TXexpiration: $exp_sec seconds"

# ###############################################
# Find the current slot of the blockchain to use
# for calculation of the invalid-thereafter value
# ###############################################
currentSlot=$($ONLINECLI query tip --mainnet | jq -r '.slot')
echo "Current Slot: $currentSlot"

# ###############################################
# Create the --tx-in src address transaction list
# ###############################################
tx_in=""
for src_tx in ${wallet_tx[@]}; do
    tx_in="${tx_in} --tx-in ${src_tx}"
    echo "Adding SrcTx: ${src_tx}"
done
# echo "tx_in: $tx_in"

# ###############################################
# Build raw transaction file tx.tmp to get fee
# ###############################################
$ONLINECLI transaction build-raw \
    ${tx_in} \
    --tx-out "$payAddr"+"0"  \
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
# Calculate the receiving (dst) address balance
# ###############################################
total_out=$((${dst_balance}+${wallet_balance}-${fee}))
echo "ADA after TX: ${total_out} (${dst_balance} current balance + ${wallet_balance} receiving balance - ${fee} tx fee)"

# ###############################################
# Create the --tx-out address transaction list
# ###############################################
tx_out="--tx-out ${payAddr}+${total_out}"
echo "Out dst addr: ${tx_out}"

# ###############################################
# Build the final transaction
# ###############################################
$ONLINECLI transaction build-raw \
    ${tx_in} \
    ${tx_out} \
    --fee ${fee} \
    --invalid-hereafter $((${currentSlot} + ${exp_sec})) \
    --mary-era \
    --out-file tx.raw
[[ ! -f tx.raw ]] && { echo "missing tx.raw, exiting..."; exit; }
echo "TX inputfile: `ls -l tx.raw`"

# ###############################################
# Create the --signing-key-file skey file list
# ###############################################
skey_files=""
for keyfile in ${wallet_skeys[@]}; do
    skey_files="${skey_files} --signing-key-file ${keyfile}"
    echo "Add skeyfile: ${keyfile}"
done

# ###############################################
# Sign transaction with relevant src address keys
# ###############################################
$ONLINECLI transaction sign \
    --tx-body-file tx.raw \
    $skey_files \
    --mainnet \
    --out-file "$OUTFILE"
[[ ! -f "$OUTFILE" ]] && { echo "missing $OUTFILE, exiting..."; exit; }
echo "Created signed transaction file $OUTFILE"
echo
echo "executing temp file cleanup: rm wallet.skey params.json tx.raw tx.tmp"
rm wallet-*.skey params.json tx.raw tx.tmp
echo "To verify, type: "
echo "$ONLINECLI transaction view --tx-file $OUTFILE"
echo "To submit, type: "
echo "$ONLINECLI transaction submit --tx-file $OUTFILE --mainnet"
