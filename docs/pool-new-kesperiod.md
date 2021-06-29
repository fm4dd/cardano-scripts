# Cardano Scripts

## pool-new-kesperiod.sh

Creates a new operational cert with an updated expiration date. Currently, the certificate expires after 93 days (KES period). Existing KES keys can be re-used if the producer node system is not compromised. Each new cert gets a incremented issuer number (serial) and start date, resetting the KES period. The output file of this script is a file named pool-producer-ops.cert.

After creation, the file needs to be placed into the producer node, and the producer node needs a restart to load the renewed cert.

**Warning:**  
This script could fail due to bugs or changes of the cardano-cli interface.
Creating new keys at each renewal is to be more secure. This script re-uses
old keys. Use at your own risk.

### Prerequisites

- Producer node cold-key folder with the node key pair and the node counter file
- Cardano blockchain genesis file
  
### Usage

```
./pool-new-kesperiod.sh <pool-key-folder>
```

### Example run
```
pi@ubuntu:~$ ./pool-new-kesperiod.sh ../producer-cold-keys
Create ops cert number: 5
#Slots/KESPeriod Value: 129600
Found the latest Slot#: 32528261
The current KES period: 250 (Sat 19 Jun 2021 06:22:36 PM JST)
Valid until KES period: 312 (Mon 20 Sep 2021 06:22:36 PM JST)
Successfully created ../producer-cold-keys/pool-producer-ops.cert
Now copy the new cert to the producer node, e.g.:
scp ../producer-cold-keys/pool-producer-ops.cert pool@192.168.11.23:~/cardano/producer/etc/producer.cert.new
ssh pool@192.168.11.23 mv ~/cardano/producer/etc/producer.cert ~/cardano/producer/etc/producer.cert.orig
ssh pool@192.168.11.23 mv ~/cardano/producer/etc/producer.cert.new ~/cardano/producer/etc/producer.cert
```
Checking the cert file:
```
pi@ubuntu:~/scripts$ cat ../cardano-producer-cold-keys/pool-producer-ops.cert
{
    "type": "NodeOperationalCertificate",
    "description": "",
    "cborHex": "82845820c6d994b***************************************...
*************"
}
```

Restart the node to load the new operational certificate.

## Credits

[Cardano Documentation - Key Evolving Signature and KES period](https://github.com/input-output-hk/cardano-node/blob/master/doc/stake-pool-operations/KES_period.md)
