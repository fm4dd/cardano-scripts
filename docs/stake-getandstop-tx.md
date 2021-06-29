# Cardano Scripts

## stake-getandstop-tx.sh

Creates a transaction that withdraws the rewards balance into a wallet address, and deregisters the wallet from staking, reclaiming the stake key deposit. This combines the function of withdraw-rewards-tx.sh and stake-deregister-tx.sh into a single transaction.

**Warning:**  
Manual transaction generation is dangerous.
Wrong execution, typos etc can cause loss of funds.
Extracted wallet key files are a high risk for all
wallet funds when the computer is compromised. Use
at your own risk.

### Prerequisites

- Wallet folder with the payment address key pair and the stake-rewards key pair
  
- Check the stake rewards address before execution. Example below shows 500 ADA refund from stake pool deregistration.

```
pi@ubuntu:~$ /home/pi/bin/cardano-cli query stake-address-info --address stake1uy37fvul************************** --mainnet
[
    {
        "address": "stake1uy37fvul**************************",
        "rewardAccountBalance": 500000000,
        "delegation": null
    }
]
```

### Usage

```
./stake-getandstop-tx.sh <wallet-folder>
```

### Example run
```
pi@ubuntu:~$ ./stake-getandstop-tx.sh ~/pool-wallet
Created stake key deregistration file: -rw------- 1 pi pi 187 Jun 19 11:25 key-deregistration.cert
Define a expiration for this transaction.
Choose expiry time in seconds (default=10800 - 3hrs): 
Using transaction expiration time: 10800
Current Slot: 32503186
Payment Addr: addr1q9w5k4cct2gc8hh***************************
Got balance of addr1q9w5k4cct2gc8hh***************************
Incoming->Tx: 0ab78dcf7e87b615970*******************************#0 ADA: 12333285
Addr Balance: 12333285 from UTXOs: 1
Rewards Addr: stake1uy37fvul*********************************
Got balance of stake1uy37fvul*********************************
DstAddr Balance: 12333285
Rewards Balance: 500000000
TX inputfile: -rw------- 1 pi pi 371 Jun 19 11:25 tx.tmp
Transact Fee: 178701
ADA after TX: 514154584
TX inputfile: -rw------- 1 pi pi 463 Jun 19 11:25 tx.raw
Created signed transaction stake-getstop-tx.signed

executing temp file cleanup: rm params.json tx.raw tx.tmp
To submit, type: 
/home/pi/bin/cardano-cli transaction submit --tx-file stake-getstop-tx.signed --mainnet
```
Now submit the transaction, using a running, synchronized node:
```
pi@ubuntu:~$ /home/pi/bin/cardano-cli transaction submit --tx-file stake-getstop-tx.signed --mainnet
Transaction successfully submitted.
```
Verify the rewards address deregistration:
```
pi@ubuntu:~$ /home/pi/bin/cardano-cli query stake-address-info --address stake1uy37fvul************************** --mainnet
[]
```

## Credits
