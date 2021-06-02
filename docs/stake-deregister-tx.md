# Cardano Scripts

## stake-deregister-tx.sh

Creates a transaction to to deregister the wallet from staking, and to reclaim the stake key deposit. The rewards balance must be zero at this point.

**Warning:**  
Manual transaction generation is dangerous.
Wrong execution, typos etc can cause loss of funds.
Extracted wallet key files are a high risk for all
wallet funds when the computer is compromised. Use
at your own risk.

### Prerequisites

- Wallet folder with the payment address key pair and the stake-rewards key pair
  
- Check the stake rewards address balance is zero:

```
cardano-cli query stake-address-info --address stake1u8gflE**************************** --mainnet
```
- Check the payment address balance can cover the transaction fee:

```
cardano-cli query utxo --address addr1q8f7mpzld44cnywlwwupfl7************************** --mainnet
```
- Cardano full node socket to query the current blockchain tip, calculate tx fees and to submit the transaction

- Generation of the stake key deregistration file
```
pi@ubuntu:~$ bin/cardano-cli stake-address deregistration-certificate \
--stake-verification-key-file my-wallet/stake.vkey --out-file stake-stop.cert
```
The generated file is in JSON format, with the stake rewards address (stake verification key) encoded into the “cborHex” field. Cardano calls it deregistration certificate, although at this stage it has not been signed or otherwise certified.
```
pi@ubuntu:~$ cat stake-stop.cert
{
    "type": "CertificateShelley",
    "description": "Stake Address Deregistration Certificate",
    "cborHex": "82018200581c******************************************"
}
```

### Usage

```
./stake-deregister-tx.sh <wallet-folder> <deregistration-cert>
```

### Example run
```
pi@ubuntu:~$ ./scripts/stake-deregister-tx.sh my-wallet stake-stop.cert 
Define a expiration for this transaction.
Choose expiry time in seconds (default=10800 - 3hrs): 
Using transaction expiration time: 10800
Current Slot: 30815254
Payment Addr: addr1q8f7mpzld44cnywlwwupfl7***************************
Got balance of addr1q8f7mpzld44cnywlwwupfl7***************************
Incoming->Tx: 24659a51040836010f644cb2071*******************************#0 ADA: 266444500
Addr Balance: 266444500 from UTXOs: 1
TX inputfile: -rw------- 1 pi pi 371 May 31 22:33 tx.tmp
Transact Fee: 178701
ADA after TX: 268265799
TX inputfile: -rw------- 1 pi pi 387 May 31 22:33 tx.raw
Created signed transaction stake-stop-tx.signed

executing temp file cleanup: rm params.json tx.raw tx.tmp
To submit, type: 
scp stake-stop-tx.signed pi@192.168.1.22:~/cardano
/home/pi/cardano/relay/bin/cardano-cli transaction submit --tx-file stake-stop-tx.signed --mainnet
```
Now submit the transaction, using a running, synchronized node:
```
pi@lp-ms02:~/cardano$ /home/pi/cardano/relay/bin/cardano-cli transaction submit \
 --tx-file stake-stop-tx.signed --mainnet
Transaction successfully submitted.
```
Verify the rewards address deregistration:
```
pi@lp-ms02:~$ /home/pi/cardano/relay/bin/cardano-cli query stake-address-info \
 --address stake1u8gflE**************************** --mainnet
[]
```

## Credits