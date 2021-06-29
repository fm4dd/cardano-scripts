# Cardano Scripts

## stake-register-tx.sh

Creates a transaction to register the wallet for staking, paying the stake key deposit fee (2 ADA).
The stake key registration is a pre-requisite step before registering a new stake pool.

**Warning:**  
Manual transaction generation is dangerous.
Wrong execution, typos etc can cause loss of funds.
Extracted wallet key files are a high risk for all
wallet funds when the computer is compromised. Use
at your own risk.

### Prerequisites

- Wallet folder with the payment address key pair and the stake-rewards key pair
  
- Check the stake rewards address does not return any data yet:

```
pi@ubuntu:~$ bin/cardano-cli query stake-address-info --address stake1uy37fvu************************** --mainnet
[]
```
- Check the payment address balance can cover the transaction fee:

```
cardano-cli query utxo --address addr1q8f7mpzld44cnywlwwupfl7************************** --mainnet
```
- Cardano full node socket to query the current blockchain tip, calculate tx fees and to submit the transaction

### Usage

```
./stake-register-tx.sh <wallet-folder>
```

### Example run
```
pi@ubuntu:~/scripts$ ./stake-register-tx.sh ../pool-wallet
Created stake key registration file: -rw------- 1 pi pi 185 Jun 26 22:32 key-registration.cert
Define a expiration for this transaction.
Choose expiry time in seconds (default=10800 - 3hrs): 
Using transaction expiration time: 10800
Current Slot: 33148034
Payment Addr: addr1q9w5k4cct2gc8hh***************************
Got balance of addr1q9w5k4cct2gc8hh***************************
Incoming->Tx: cfa8a18e8fa51de2c6********************************#0 ADA: 514154584
Addr Balance: 514154584 from UTXOs: 1
DstAddr Balance: 514154584
Rewards Balance: 
TX inputfile: -rw------- 1 pi pi 371 Jun 26 22:32 tx.tmp
Transact Fee: 178701
ADA after TX: 511975883
TX inputfile: -rw------- 1 pi pi 387 Jun 26 22:32 tx.raw
Created signed transaction stake-register-tx.signed

executing temp file cleanup: rm params.json tx.raw tx.tmp
To submit, type: 
/home/pi/bin/cardano-cli transaction submit --tx-file stake-register-tx.signed --mainnet
```
Now submit the transaction, using a running, synchronized node:
```
pi@lp-ms02:~/cardano$ /home/pi/cardano/relay/bin/cardano-cli transaction submit \
 --tx-file stake-register-tx.signed --mainnet
Transaction successfully submitted.
```
Verify the rewards address registration success:
```
pi@ubuntu:~$ bin/cardano-cli query stake-address-info --address stake1uy37fvul************************** --mainnet
[
    {
        "address": "stake1uy37fvu***************************",
        "rewardAccountBalance": 0,
        "delegation": null
    }
]
```

## Credits
