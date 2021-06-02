# Cardano Scripts

## ledger2master.py

Creates a Ledger MasterKey from its BIP39 mnemonic backup sentence, and returns the wallet master key needed to derive the Cardano soft wallet address keys with the 'master2wallet.sh' script. The returned ledger master key is displayed in a 192-char hex string format. This assumes the Ledger has the Cardano application installed, and it had been linked to a (Daedalus) Cardano wallet.

**Warning:**  
Extracting the Ledger master key from its mnemonic effectively creates a soft wallet
that no longer provides the strong protection of a hardware key device. Funds can
now be moved without the Ledger, and this creates severe risk for any access to the 
involved computer. This puts all Ledger-managed funds at risk, not just Cardano funds.

### Prerequisites

python3 and the mnemonic-related BIP function library from https://pypi.org/project/bip-utils/

```
pi@ubuntu:~/scripts$ pip3 install bip_utils
```

### Usage

Edit the script header to embed the 24-word Ledger mnemonic
```
pi@ubuntu:~/scripts$ vi ledger2master.py
...
# ##########################################################
# enter the 24-word ledger mnemonic for the key conversion
# !!! Delete it after conversion to prevent losing funds !!!
# !!! from inadvertantly leaking it with this script !!!!!!!
# ##########################################################
mnemonic = "sadness slab ... tube"
```

### Example run (random sample key data)

```
pi@ubuntu:~/scripts$ ./ledger2master.py 
final masterkey str: b88077c0eff291fedb7923efa2d8f990464957b1479d1fb5b885a56223c9dd5d959b790117e14933a5e8************************************************************************************d6583e3297ef9d446a7e9ac8
```

### Credits

This code has been converted to Python from the original Javascript 'ledger2pool' located at https://repl.it/@PalDorogi/ledger2pool#index.js. All credits to the original author PalDorogi.

### Links

[Original Cardano Code Source](https://github.com/input-output-hk/cardano-wallet/wiki/Wallet-Cryptography-and-Encoding#Ledger)
