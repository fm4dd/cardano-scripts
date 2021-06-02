# Cardano Scripts

## withdraw-rewards-tx.sh

Creates a transaction to withdraw all received staking rewards from the 
wallet's stake rewards address. A zero balance of the stake rewards address 
is the prerequiste condition to deregister the wallet from staking, and to 
reclaim the stake key deposit.

To stop the wallet staking and stake rewards collection, e.g. for closing 
out the wallet, the subsequent stake key deregistration is needed. 

**Warning:**  
Manual transaction generation is dangerous.
Wrong execution, typos etc can cause loss of funds.
Extracted wallet key files are a high risk for all
wallet funds when the computer is compromised. Use
at your own risk.

### Prerequisites

- Wallet folder with the payment address key pair and the stake-rewards key pair
  
- Check if the stake rewards address balance is non-zero:

```
cardano-cli query stake-address-info --address stake1u8gflE**************************** --mainnet
```
- Check the payment address balance can cover the transaction fee:

```
cardano-cli query utxo --address addr1q8f7mpzld44cnywlwwupfl7************************** --mainnet
```
- Cardano full node socket to query the current blockchain tip, calculate tx fees and to submit the transaction

### Usage

```
./withdraw-rewards-tx.sh <wallet-folder>
```

### Example run

```
pi@ubuntu:~/scripts$ ./withdraw-rewards-tx.sh ~/my-wallet
Define expiration for this transaction.
Choose expiry time in seconds (default=10800 - 3hrs): 
Using transaction expiration time: 10800
Current Slot: 30799899
Rewards Addr: stake1u8gflE****************************
Rewards output
[
    {
        "address": "stake1u8gflE****************************",
        "rewardAccountBalance": 5395880,
        "delegation": "pool1zg******************************"
    }
]
Got balance of stake1u8gflE****************************
Rewards Balance: 5395880
Payment Addr: addr1q8f7mpzld44cnywlwwupfl7***************************
Got balance of addr1q8f7mpzld44cnywlwwupfl7****************************
Incoming->Tx: cd27f7a03ca5d90ab1fd8ce9a29752*******************************#0 ADA: 261227233
Addr Balance: 261227233 from UTXOs: 1
TX inputfile: -rw------- 1 pi pi 367 May 31 18:14 tx.tmp
Transact Fee: 178613
ADA after TX: 266444500
TX inputfile: -rw------- 1 pi pi 391 May 31 18:14 tx.raw
Created signed transaction withdraw-rewards-tx.signed
executing temp file cleanup: rm params.json tx.raw tx.tmp

Copy the transaction to the synced cardano node, and submit: 
scp withdraw-rewards-tx.signed pi@192.168.1.22:~/cardano
/home/pi/cardano/relay/bin/cardano-cli transaction submit --tx-file withdraw-rewards-tx.signed --mainnet

```
Now submit the transaction, using a running, synchronized node:
```
pi@lp-ms02:~/cardano$ /home/pi/cardano/relay/bin/cardano-cli transaction submit --tx-file withdraw-rewards-tx.signed --mainnet
Transaction successfully submitted.
```
Verify the rewards account balance is now zero:
```
pi@lp-ms02:~/cardano$ /home/pi/cardano/relay/bin/cardano-cli query stake-address-info --address stake1u8gflE**************************** --mainnet
[
    {
        "address": "stake1u8gflE****************************",
        "rewardAccountBalance": 0,
        "delegation": "pool1zg******************************"
    }
]
```

### Credits

Cardano project rewards withdrawal documentation:
https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/withdraw-rewards.html
