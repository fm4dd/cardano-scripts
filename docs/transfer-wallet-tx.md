# Cardano Scripts

## transfer-wallet-tx.sh

Creates a signed transaction to withdraw all funds from all address in the wallet with a single transaction. The remaining wallet balance will be total zero (leaves not a single lovelace behind). This assumes that the rewards address is already zero.
 
**Warning:**  
Manual transaction generation is very dangerous.
Wrong execution, typos etc can cause loss of all funds.
Extracted wallet key files are a high risk for all
wallet funds when the computer is compromised. Use
at your own risk.

### Prerequisites

- Wallet folder with the the wallet root key pair extracted
- The wallet having at least one address with enough balance to transfer and pay for the transaction fee.
- The destination address to receive the wallet funds
  
Check destination address balance before transfer. In this example, it is an empty address.
```
pi@ubuntu:~$ bin/cardano-cli query utxo --address addr1qy69aeaf59gku*************************** --mainnet
                           TxHash                                 TxIx        Amount
--------------------------------------------------------------------------------------
```

### Usage

```
./transfer-wallet-tx.sh <wallet-folder>
```

### Example run
```
pi@ubuntu:~/scripts$ ./transfer-wallet-tx.sh ../h2-wallet
Stake pubkey: stake_xvk1yxj94zjxrhw2jp9***************************
checking Wallet balance:
key child 1852H/1815H/0H/0/0 - addr1q9z6w83et5uh***************************
...
key child 1852H/1815H/0H/1/2 - addr1q9v5yg3ac5c6*************************** Balance [74668655]
...
key child 1852H/1815H/0H/1/3 - addr1q8f76qhdunx8*************************** Balance [26265799]
...
key child 1852H/1815H/0H/0/26 - addr1qxwq9qlcngs***************************

Wallet Balance: 100934454 found in 2 address entries
Enter receiving address for wallet funds addr1q********************** (104-character address)
Payment Addr: addr1qy69aeaf59gku***************************
Dest Addr OK: addr1qy69aeaf59gku***************************
Addr Balance: 0 in 0 UTXO's
Define a expiration for this transaction.
Choose expiry time in seconds (default=10800 - 3hrs): 
TXexpiration: 10800 seconds
Current Slot: 32624036
Adding SrcTx: cf88b86000cd2***************************#1
Adding SrcTx: c59a018099215***************************#0
TX inputfile: -rw------- 1 pi pi 371 Jun 20 12:30 tx.tmp
Transact Fee: 176941
ADA after TX: 100757513 (0 current balance + 100934454 receiving balance - 176941 tx fee)
Out dst addr: --tx-out addr1qy69aeaf59gku***************************+100757513
TX inputfile: -rw------- 1 pi pi 387 Jun 20 12:30 tx.raw
Add skeyfile: wallet-0.skey
Add skeyfile: wallet-1.skey
Created signed transaction file transfer-wallet-tx.signed

executing temp file cleanup: rm wallet.skey params.json tx.raw tx.tmp
To verify, type: 
/home/pi/bin/cardano-cli transaction view --tx-file transfer-wallet-tx.signed
To submit, type: 
/home/pi/bin/cardano-cli transaction submit --tx-file transfer-wallet-tx.signed --mainnet
```
The transaction file looks like this
```
pi@ubuntu:~$ bin/cardano-cli transaction view --tx-file transfer-wallet-tx.signed
auxiliary data: null
auxiliary data hash: null
certificates: []
era: Mary
fee: 176941
inputs:
- c59a018099215***************************#0
- cf88b86000cd2***************************#1
mint:
  lovelace: 0
  policies: {}
outputs:
- address:
    Bech32: addr1qy69aeaf59gku***************************
    credential:
      key hash: 345ee7a9a15185858***************************
    network: Mainnet
    stake reference: StakeRefBase (KeyHashObj (KeyHash "23ee9c58ca1***************************"))
  amount:
    lovelace: 100757513
    policies: {}
update: null
validity interval:
  invalid before: null
  invalid hereafter: 32630336
withdrawals: []
```
Now submit the transaction, using a running, synchronized node:
```
pi@ubuntu:~$ bin/cardano-cli transaction submit --tx-file transfer-wallet-tx.signed --mainnet
Transaction successfully submitted.
```
Verify the transaction success, checking the funds in the destination address:
```
pi@ubuntu:~$ bin/cardano-cli query utxo --address addr1qy69aeaf59gku*************************** --mainnet
                           TxHash                                 TxIx        Amount
--------------------------------------------------------------------------------------
a3ff8ed38a55**************************************************     0         100757513 lovelace
```

## Credits
