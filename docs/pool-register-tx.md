# Cardano Scripts

## pool-register-tx.sh

Creates a transaction to register a new stake pool configuration including pool cost, pledge value, pool margin or relay information. while the stake pool becomes visible after blockchain processing, it may take a bit to propagate to pool monitoring sites. The registration incurs the pool deposit fee, deducted from the pool payment address. If correctly registered and if the pledge value is met, the pool network operation itself starts after completing the current and next epoch.

**Warning:**  
Manual transaction generation is dangerous.
Wrong execution, typos etc can cause loss of funds.
Extracted wallet key files are a high risk for all
wallet funds when the computer is compromised. Use
at your own risk.

### Prerequisites

- Wallet folder with the payment address key pair and the producer node (cold) key pair
  
- Check the payment address balance can cover the pool deposit:

```
cardano-cli query utxo --address addr1q9w5k4************************** --mainnet
```
- Cardano full node socket to query the current blockchain tip, calculate tx fees and to submit the transaction

- Currently, the relay parameters are not queried. Need to edit the script header to update.

### Usage

```
./pool-register-tx.sh <wallet-folder>
```

This script generates a stake pool registration file (Cardano calls it "pool registration certificate"), and creates
the transaction that submits it to the blockchain, announcing the pool to the world.

### Example run
```
pi@ubuntu:~/scripts$ ./pool-register-tx.sh ../pool-wallet/
Download the latest poolMetaData.json file.
Enter URL (e.g. http://tama.fm4dd.com/meta.json): http://tama.fm4dd.com/meta.json
Created poolMetaData hash: 74f82ef8f20bbb587493300faca8**************************
Enter the pool cost amount in ADA (e.g. 340).
Enter ADA, or return for default 340 : 
Set pool cost value: 340000000
Enter the pool pedge amount in ADA (e.g. 2000).
Enter ADA, or return for default 1000 : 
Set pool pledge value: 1000000000
Enter the pool margin 0..1 (e.g. 0.01 = 1%).
Enter value, or return for default 0.01 : 
Set pool margin value: 0.01
Using relay parameter: --single-host-pool-relay relay.fm4dd.com --pool-relay-port 5513
Created pool registration file: -rw------- 1 pi pi 582 Jun 27 12:45 pool-register.cert
Created stake delegation file: -rw------- 1 pi pi 243 Jun 27 12:45 stake-delegation.cert
Define a expiration for this transaction.
Choose expiry time in seconds (default=10800 - 3hrs): 
Using transaction expiration time: 10800
Current Slot: 33199234
Payment Addr: addr1q9w5k4cct2gc8***********************************************
Got balance of addr1q9w5k4cct2gc8***********************************************
Incoming->Tx: cfa8a18e8fa51de2c691*****************************************#0 ADA: 514154584
Addr Balance: 514154584 from UTXOs: 1
TX inputfile: -rw------- 1 pi pi 899 Jun 27 12:45 tx.tmp
Pool Deposit: 500000000
Transact Fee: 190317
ADA after TX: 13964267
TX inputfile: -rw------- 1 pi pi 915 Jun 27 12:45 tx.raw
Created signed transaction register-pool-tx.signed

executing temp file cleanup: rm params.json poolMetaData.json poolMetaDataHash.txt tx.raw tx.tmp
To submit, type: 
/home/pi/bin/cardano-cli transaction submit --tx-file register-pool-tx.signed --mainnet
```

The transaction content can be verified with the cardano-cli before submission:
```
bin/cardano-cli transaction view --tx-file register-pool-tx.signed
```

Now submit the transaction, using a running, synchronized node:
```
pi@ubuntu:~$ bin/cardano-cli transaction submit --tx-file register-pool-tx.signed --mainnet
Transaction successfully submitted.
```
Verify the successful stake pool update:
```
cardano-cli query pool-params --stake-pool-id pool1zg****************************************** --mainnet
```

Insufficient funds on the payment address generate the "Negative quantity" error:

```
Command failed: transaction build-raw  Error: Transaction validaton error: Negative quantity (-286035733) in transaction output: TxOut (AddressInEra (ShelleyAddressInEra ShelleyBasedEraMary) ... (TxOutValue MultiAssetInMaryEra (valueFromList [(AdaAssetId,-286035733)]))
missing tx.raw, exiting...
```
## Credits

