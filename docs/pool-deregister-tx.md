# Cardano Scripts

## pool-deregister-tx.sh

Creates a transaction to deregister the stake pool producer node from staking, and to reclaim the pool deposit. This stops the stake pool operation with a lead time of min 2 epochs, and max 18 epochs (defined in protocol parameters).

**Warning:**  
Manual transaction generation is dangerous.
Wrong execution, typos etc can cause loss of funds.
Extracted wallet key files are a high risk for all
wallet funds when the computer is compromised. Use
at your own risk.

Unless the pool has no delegations, it is curteous to announce pool retirement with a lead time greater than minimum 2 epochs. Because retiring the stake pool would "orphan" any delegated wallets, Cardano allows for declaring retirement up to 18 epochs (90 days) from announcement date.

After the pool deregistration becomes effective, deregister the stake key and reclaim the stake key deposit.

### Prerequisites

- Wallet folder with the payment address key pair and the producer node (cold) key pair
  
- Check the stake pool status and pool parameters:

```
cardano-cli query pool-params --stake-pool-id pool1zg****************************************** --mainnet | egrep 'publicKey|retiring'
        "publicKey": "120164437b858******************************************",
    "retiring": null

```
- Check the payment address balance can cover the transaction fee:

```
cardano-cli query utxo --address addr1q9w5k4************************** --mainnet
```
- Cardano full node socket to query the current blockchain tip, calculate tx fees and to submit the transaction

### Usage

```
./pool-deregister-tx.sh <wallet-folder>
```

This script generates a stake pool deregistration file (Cardano calls it "deregistration certificate"), and creates
the transaction that submits it to the blockchain, announcing the pool retirement for the selected epoch.

### Example run
```
pi@ubuntu:~$ ./scripts/pool-deregister-tx.sh ~/pool-wallet
Queried current epoch=270 and max future epoch=+18
Define the pool retirement epoch.
Choose epoch between 272 and 288: 
Pool retirement effective in epoch: 272
Created pool deregistration file: -rw------- 1 pi pi 182 Jun  6 17:37 pool-deregistration.cert
Define a expiration for this transaction.
Choose expiry time in seconds (default=10800 - 3hrs): 
Using transaction expiration time: 10800
Current Slot: 31402359
Payment Addr: addr1q9w5k4cct2gc8hhmajjvz*****************************************************
Got balance of addr1q9w5k4cct2gc8hhmajjvz*****************************************************
Incoming->Tx: d6c78f5f6391af9f08e2*****************************************************#0 ADA: 7315374
Incoming->Tx: cf88b86000cd5c8299d4*****************************************************#0 ADA: 5200000
Addr Balance: 12515374 from UTXOs: 2
TX inputfile: -rw------- 1 pi pi 445 Jun  6 17:37 tx.tmp
Transact Fee: 182089
ADA after TX: 12333285
TX inputfile: -rw------- 1 pi pi 461 Jun  6 17:37 tx.raw
Created signed transaction retire-pool-tx.signed

executing temp file cleanup: rm params.json tx.raw tx.tmp
To submit, type: 
/home/pi/bin/cardano-cli transaction submit --tx-file retire-pool-tx.signed --mainnet
```
Now submit the transaction, using a running, synchronized node:
```
pi@ubuntu:~$ bin/cardano-cli transaction submit --tx-file retire-pool-tx.signed --mainnet
Transaction successfully submitted.
```
Verify the successful stake pool deregistration, checking the retirement value:
```
pi@lp-ms03:~/cardano $ producer/bin/cardano-cli query pool-params --stake-pool-id pool1zg****************************************** --mainnet | egrep 'publicKey|retiring'                                           "publicKey": "120164437b858******************************************",
    "retiring": 272
```

## Credits

[Cardano Documentation - Retiring a Stake Pool](https://docs.cardano.org/projects/cardano-node/en/latest/stake-pool-operations/retire_stakepool.html)
