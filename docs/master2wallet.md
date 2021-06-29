# Cardano Scripts

## master2wallet.sh

Creates the individual key files from a Daedalus wallet mnemonic, or from a Ledger-extracted master key. The key files enable Cardano network transactions on the commandline, e.g. using 'cardano-cli'.

```
pi@ubuntu:~/scripts$ ls my-wallet/
base.addr            payment.evkey  payment.xprv  stake.addr   stake.vkey
base.addr_candidate  payment.skey   payment.xpub  stake.evkey  stake.xprv
payment.addr         payment.vkey   root.prv      stake.skey   stake.xpub
```

**Warning:**  
The wallet key files ultimately allow all wallet actions, including moving funds. This creates severe risk for any access to the involved computer. Use at your own risk.

Cardano wallet mnemonic uses BIP-0039 dictionaries. The current 24-word mnemonic has 32 bytes (256-bit) entropy plus one byte checksum.
Technically the script could be called entropy2wallet, but for the ledger master key input.

### Prerequisites

- Cardano-wallet binaries https://github.com/input-output-hk/cardano-wallet/releases
- jq - Command-line JSON processor
```
sudo apt-get install jq
```
- Shelley genesis config file
```
wget https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished/download/1/mainnet-shelley-genesis.json
```

### Usage

```
./master2wallet.sh <ouptut dir> <Ledger Master Key>
./master2wallet.sh <ouptut dir> <Daedalus wallet 24-word mnemonics>
```

### Example run (random sample key data)

```
pi@ubuntu:~/scripts$ ./master2wallet.sh my-wallet b88077c0eff291fedb7923efa2d8f990464957b1479d1fb5b885a56223c9dd5d959b790117e14933a5e8************************************************************************************d6583e3297ef9d446a7e9ac8
OK - Converting 192-character Ledger masterkey
OK - Successfully created root.prv
OK - Created stake.xprv
Select a payment key, ask for a key with balance, or
use '0/0' for picking the first key from the wallet.
Daedalus keys are displayed top-down in this order:
1852H/1815H/0H/0/0 - Daedalus key 0 (top key)
1852H/1815H/0H/1/0 - Daedalus key 1 (top-1 key)
1852H/1815H/0H/0/1 - Daedalus key 2 (top-2 key)
1852H/1815H/0H/1/1 - Daedalus key 3 (top-3 key)
1852H/1815H/0H/0/2 - Daedalus key 4 (top-4 key)
1852H/1815H/0H/1/2 - Daedalus key 5 (top-5 key)
1852H/1815H/0H/0/3 - Daedalus key 6 (top-6 key)
1852H/1815H/0H/1/3 - Daedalus key 7 (top-7 key)
1852H/1815H/0H/0/4 - Daedalus key 8 (top-8 key)
1852H/1815H/0H/1/4 - Daedalus key 9 (top-9 key)
Choose Key # with existing balance, or enter "0/0": 0/0
OK - Created payment.xprv for key 1852H/1815H/0H/0/0
OK - Generating wallet keys for Mainnet
OK - Created stake.xpub
{
    "stake_reference": "by value",
    "stake_key_hash_bech32": "stake_vkh1m7zd0a4k9x3atlvw88aes65plqy2jujr*******************",
    "stake_key_hash": "df84d7f6b629a3d5fd8e39fb986a81f80*******************",
    "spending_key_hash_bech32": "addr_vkh10az3kwgqykake8308tyuyk5f9azvl83*******************",
    "address_style": "Shelley",
    "spending_key_hash": "7f451b390025bb6c9e2f3ac9c25a892f44c*******************",
    "network_tag": 1
}
OK - Base address generated from 1852H/1815H/0H/0/0
addr1q9l52xeeqqjmkmy79uavnsj63yh5fnu7x6*********************************************8tcwqs0xqlfvs3tsnft
Important! The base.addr and the base.addr_candidate must be the same
Files base.addr and base.addr_candidate are identical
addr1q9l52xeeqqjmkmy79uavnsj63yh5fnu7x6*********************************************8tcwqs0xqlfvs3tsnft
addr1q9l52xeeqqjmkmy79uavnsj63yh5fnu7x6*********************************************8tcwqs0xqlfvs3tsnft
OK - Copying base.addr into payment.addr

Clear shell history:
cat /dev/null > ~/.bash_history && history -c
```

To verify correct wallet creation, payment address and stake rewards address can be compared with the original Daedalus wallet. They should be identical.

## Credits

This script is a adoption from ilap at https://gist.github.com/ilap/5af151351dcf30a2954685b6edc0039b. All credits to the original author.

## Links

[Cardano wallet address derivation](https://github.com/input-output-hk/cardano-wallet/wiki/About-Address-Derivation)  
[BIP-44 wallet key hierarchy notes](https://github.com/input-output-hk/cardano-wallet/wiki/Notes-about-BIP-44)  
[Wallet Cryptography and Encoding](https://github.com/input-output-hk/cardano-wallet/wiki/Wallet-Cryptography-and-Encoding)
