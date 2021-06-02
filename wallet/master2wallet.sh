#!/bin/bash 
# ##########################################################
# master2wallet.sh
# Derives Cardano wallet keys either from a ledger master
# key (extracted with ledger2master.py), or from Daedalus
# wallet backup mnemonics. Extracted keys can be used for
# manual transactions with cardano-cli on a synced node.
#
# Code adapted from:
# https://gist.github.com/ilap/5af151351dcf30a2954685b6edc0039b
#
# Prerequisites:
# cardano-wallet-linux64
# jq (e.g. sudo apt-get install jq)
# Shelley genesis config file
#
# Commandline Args:
# 1 - wallet folder to store the key files
# 2 - master key in 192-char hex string format
#     the master key can be extracted with:
#     ledger2master.py
#     returns "402b03cd9...1492658" (192-char hex string)
#
# Usage:
# ./master2wallet.sh ~/ledger-wallet "402b03cd9...1492658"
#
# note:
# In cip5 key names were updated, see cip5 examples at
# https://cips.cardano.org/cips/cip5/
# https://github.com/input-output-hk/cardano-addresses
#
# ##########################################################
# ATTENTION: Extracting wallet keys is very dangerous!!!!!!!
# !! Unintented file access may cause loss of funds !!!!!!!!
# !! Wrong execution, typos later may cause loss of funds !!
# ##########################################################

# ####################################################
# Set the path to the wallet binaries
# ####################################################
CADDR=/home/pi/cardano-wallet-linux64/cardano-address
[[ -z "$CADDR" ]] && { echo "cardano-address cannot be found, exiting..." >&2 ; exit 127; }

CCLI=/home/pi/cardano-wallet-linux64/cardano-cli
[[ -z "$CCLI" ]] && { echo "cardano-cli cannot be found, exiting..." >&2 ; exit 127; }

BECH32=/home/pi/cardano-wallet-linux64/bech32
[[ -z "$BECH32" ]] && { echo "bech32 cannot be found, exiting..." >&2 ; exit 127; }

# ####################################################
# Check for the Shelley genesis config file
# ####################################################
GEN_FILE=${GEN_FILE:="$HOME/conf/shelley-genesis.json"}
[[ ! -f "$GEN_FILE" ]] && { echo "genesis file $HOME/conf/shelley-genesis.json does not exit, exiting..."
 >&2 ; exit 127; }

# ################################################3dd####
# Check for cmdline args: output-dir and masterkey
# ####################################################
[[ "$#" -ne 2 ]] && {
       echo "usage: `basename $0` <ouptut dir> <Ledger Master Key>" >&2
       echo "or `basename $0` <ouptut dir> <Daedalus wallet 24-word mnemonics>" >&2
       echo "Ledger masterkey is generated with ledger2master.py" >&2
       exit 127
}

# ####################################################
# Assign 1st parameter as output-dir. Create if needed
# ####################################################
OUT_DIR="$1"
[[ -e "$OUT_DIR"  ]] && {
       echo "Error: \"$OUT_DIR\" already exists. Delete and run again." >&2
       exit 127
} || mkdir -p "$OUT_DIR" && pushd "$OUT_DIR" >/dev/null

# ####################################################
# Check if 2nd parameter is a 192-char masterkey str
# or a mnemonic such as "word1 word2 word3 ... word24"
# ####################################################
if [[ $2 == *" "* ]] && [ $(echo $2 |wc -w) == 24 ]; then
   # #################################################
   # Detected the 2nd parameter as 24-word mnemonics
   # #################################################
   echo "OK - Converting 24-word Daedalus wallet mnemonic"
   # ####################################################
   # Generate xtended priv key from mnemonics as root.prv
   # ####################################################
   echo "$2" | "$CADDR" key from-recovery-phrase Shelley > root.prv

elif [ ${#2} == 192 ]; then
   # #################################################
   # Detected the 2nd parameter as a Ledger masterkey
   # #################################################
   echo "OK - Converting ${#2}-character Ledger masterkey"
   # #################################################
   # Convert master key to root.prv extended priv key
   # used to have xprv prefix -> changed to root_xsk
   # #################################################
   echo "$2" | "$BECH32" root_xsk > root.prv

else
   echo "Error: invalid 2nd argument, exiting..."
   exit
fi

# #################################################
# Check success of the extended priv key creation
# #################################################
if [ -s "root.prv"  ]; then
   echo "OK - Successfully created root.prv"
else
   echo "ERROR: Could not create root.prv"
   exit 126
fi

# ####################################################
# Derive stake account extended private key stake.xprv
#
# Cardano uses a BIP-44 hierarchy with purpose = 1852
# Cointype 1815 is registered for ADA. Wallet Schema:
# <purpose>/<cointype>/<account#>/<accounttype>/<addr>
# <account#> is fixed 0
# <accounttype> 0 = external, receiving address list
#               1 = int address list, e.g. for change
#               2 = only one rewards address at addr=0
# ####################################################
cat root.prv |\
"$CADDR" key child 1852H/1815H/0H/2/0 > stake.xprv
if [ -s "stake.xprv"  ]; then
    echo "OK - Created stake.xprv"
else
    echo "ERROR - Could not create stake.xprv"
    exit 125
fi

# ####################################################
# Check which extended payment priv-key to extract
# ####################################################
echo "Select a payment key, ask for a key with balance, or"
echo "use '0/0' for picking the first key from the wallet."
echo "Daedalus keys are displayed top-down in this order:"
echo "1852H/1815H/0H/0/0 - Daedalus key 0 (top key)"
echo "1852H/1815H/0H/1/0 - Daedalus key 1 (top-1 key)"
echo "1852H/1815H/0H/0/1 - Daedalus key 2 (top-2 key)"
echo "1852H/1815H/0H/1/1 - Daedalus key 3 (top-3 key)"
echo "1852H/1815H/0H/0/2 - Daedalus key 4 (top-4 key)"
echo "1852H/1815H/0H/1/2 - Daedalus key 5 (top-5 key)"
echo "1852H/1815H/0H/0/3 - Daedalus key 6 (top-6 key)"
echo "1852H/1815H/0H/1/3 - Daedalus key 7 (top-7 key)"
echo "1852H/1815H/0H/0/4 - Daedalus key 8 (top-8 key)"
echo "1852H/1815H/0H/1/4 - Daedalus key 9 (top-9 key)"
read -p 'Choose Key # with existing balance, or enter "0/0": ' paynum

if [ -z "$paynum" ]; then
   echo "Error: Please select a key number e.g. 0/0; exiting..."
   exit
fi

# ####################################################
# Derive extended payment private key payment.xprv
# ####################################################
cat root.prv |\
"$CADDR" key child 1852H/1815H/0H/$paynum > payment.xprv
if [ -s "payment.xprv"  ]; then
    echo "OK - Created payment.xprv for key 1852H/1815H/0H/$paynum"
else
    echo "ERROR - Could not create payment.xprv"
    exit 124
fi

# ####################################################
# Extract networkId and networkMagic from Shelley genesis
# config file. Should be 'Mainnet' and '764824073'
# ####################################################
NW=$(jq '.networkId' -r "$GEN_FILE")
NW_ID=$(jq '.networkMagic' -r "$GEN_FILE")
echo "OK - Generating wallet keys for $NW"

# ####################################################
# Set the NW ID: 1 = Mainnet, 0 = Testnet
# ####################################################
if [ "$NW" == "Testnet" ]; then
  NETWORK=0
  MAGIC="--testnet-magic $NW_ID"
  CONV="bech32 | bech32 addr_test"
else
  NETWORK=1
  MAGIC="--mainnet"
  CONV="cat"
fi

# ####################################################
# Derive stake account extended public key stake.xpub
# ####################################################
cat stake.xprv | "$CADDR" key public --with-chain-code > stake.xpub
if [ -s "stake.xpub"  ]; then
    echo "OK - Created stake.xpub"
else
    echo "ERROR - Could not create stake.xpub"
    exit 124
fi

# ####################################################
# Derive payment extended public key payment.xpub
# ####################################################
cat payment.xprv | "$CADDR" key public --with-chain-code > payment.xpub

# ####################################################
# Create base.addr_candidate
# ####################################################
cat payment.xpub | "$CADDR" address payment --network-tag $NETWORK |\
"$CADDR" address delegation $(cat stake.xpub) > base.addr_candidate

cat base.addr_candidate | "$CADDR" address inspect
echo "OK - Base address generated from 1852H/1815H/0H/$paynum"

if [  "$NW" == "Testnet" ]; then
  cat base.addr_candidate | "$BECH32" | "$BECH32" addr_test > base.addr_candidate_test
  mv base.addr_candidate_test base.addr_candidate
fi
cat base.addr_candidate 
echo

# ####################################################
# Create stake.skey, stake.evkey and stake.vkey files
# ####################################################
SESKEY=$( cat stake.xprv | "$BECH32" | cut -b -128 )$( cat stake.xpub | "$BECH32")

cat << EOF > stake.skey
{
    "type": "StakeExtendedSigningKeyShelley_ed25519_bip32",
    "description": "",
    "cborHex": "5880$SESKEY"
}
EOF

"$CCLI" key verification-key --signing-key-file stake.skey --verification-key-file stake.evkey

"$CCLI" key non-extended-key --extended-verification-key-file stake.evkey --verification-key-file stake.vkey

# ####################################################
# Create payment.skey, payment.evkey and payment.vkey
# ####################################################
PESKEY=$( cat payment.xprv | "$BECH32" | cut -b -128 )$( cat payment.xpub | "$BECH32")

cat << EOF > payment.skey
{
    "type": "PaymentExtendedSigningKeyShelley_ed25519_bip32",
    "description": "Payment Signing Key",
    "cborHex": "5880$PESKEY"
}
EOF

"$CCLI" key verification-key --signing-key-file payment.skey --verification-key-file payment.evkey

"$CCLI" key non-extended-key --extended-verification-key-file payment.evkey --verification-key-file payment.vkey

# ####################################################
# Create stake.addr and payment.addr files
# ####################################################
"$CCLI" stake-address build --stake-verification-key-file stake.vkey $MAGIC --out-file stake.addr
"$CCLI" address build --payment-verification-key-file payment.vkey --stake-verification-key-file stake.vkey $MAGIC --out-file base.addr

echo "Important! The base.addr and the base.addr_candidate must be the same"
diff -s base.addr base.addr_candidate
echo `cat base.addr_candidate`
echo `cat base.addr`
echo "OK - Copying base.addr into payment.addr"
cp base.addr payment.addr
echo
echo "Clear shell history:"
echo "cat /dev/null > ~/.bash_history && history -c"
popd >/dev/null
