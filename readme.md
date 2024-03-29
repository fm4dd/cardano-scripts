# Cardano Scripts

## Background

Collection of scripts created during research on the [Cardano](https://cardano.org/) ecosystem.

**Warning:**  
Scripts were written and run with specific versions of Cardano. The
Cardano project progress brings change that may render scripts unusable.
Cardano funds have value: Any errors, bugs, oversights, typos etc
can destroy all funds irrecoverably. Scripts were created for personal education.
Use at your own risk.

## Prerequisites

Most scripts require Cardano commandline tools such as 'cardano-cli'.
Transaction-related scripts need the socket connection to a synchronized Cardano node.
This could be from the running Daedalus wallet, or a relay full node running on a separate host.

## Wallet-related scripts

[ledger2master.py](bin/ledger2master.py)

Extracts the Ledger HW wallet master key data from mnemonics. Together with 'master2wallet.sh', it converts a Ledger-connected Daedalus HW wallet into a soft wallet. [...details](docs/ledger2master.md)

[master2wallet.sh](bin/master2wallet.sh)

Creates the individual key files from a Daedalus wallet mnemonic, or from a Ledger-extracted master key. The key files enable Cardano network transactions on the commandline, e.g. using 'cardano-cli'. [...details](docs/master2wallet.md)

[stake-register-tx.sh](bin/stake-register-tx.sh)

Creates a transaction to to register the wallet for staking, paying the stake key deposit (2 ADA). [...details](docs/stake-register-tx.md)

[withdraw-rewards-tx.sh](bin/withdraw-rewards-tx.sh)

Creates a transaction to withdraw all received staking rewards from the wallet's stake rewards address. A zero balance of the stake rewards address is the prerequiste condition to deregister the wallet from staking, and to reclaim the stake key deposit. [...details](docs/withdraw-rewards-tx.md)

[stake-deregister-tx.sh](bin/stake-deregister-tx.sh)

Creates a transaction to to deregister the wallet from staking, and to reclaim the stake key deposit. [...details](docs/stake-deregister-tx.md)

[stake-getandstop-tx.sh](bin/stake-getandstop-tx.sh)

Creates a transaction that withdraws the rewards balance into a wallet address, and deregisters the wallet from staking, reclaiming the stake key deposit. This combines the function of withdraw-rewards-tx.sh and stake-deregister-tx.sh into a single transaction. [...details](docs/stake-getandstop-tx.md)

[transfer-wallet-tx.sh](bin/transfer-wallet-tx.sh)

Creates a signed transaction to withdraw all funds from all address in the wallet with a single transaction. The remaining wallet balance will be zero. This assumes that the rewards address is already zero. [...details](docs/transfer-wallet-tx.md)

## StakePool-related scripts

[pool-register-tx.sh](bin/pool-register-tx.sh)

This script generates the stake pool registration and creates the transaction that submits it to the blockchain, announcing the pool to the world. [...details](docs/pool-register-tx.md)

[pool-update-tx.sh](bin/pool-update-tx.sh)

Creates a transaction to announce updates to the stake pool configuration including pool cost, pledge value, pool margin or relay information. [...details](docs/pool-update-tx.md)

[pool-new-kesperiod.sh](bin/pool-new-kesperiod.sh)

Creates a new operational cert with an updated expiration date. Currently, the certificate expires after 93 days (KES period). Each new cert gets a incremented issuer number (serial) and start date, resetting the KES period. If not renewed, the producer node stops working. [...details](docs/pool-new-kesperiod.md)

[pool-deregister-tx.sh](bin/pool-deregister-tx.sh)

Creates a transaction to to deregister the stake pool producer node from staking, and to reclaim the pool deposit. This stops the stake pool operation with a minimum lead time of 2 epochs. [...details](docs/pool-deregister-tx.md)

[pool-getpeers.sh](bin/pool-getpeers.sh)

Because Cardano does not have peer auto-discovery yet, this script announces our relay to the public, and collects a number of nodes for peering. It outputs into the tolopgy.json configuration file that is read by the relay node during startup. Must run exactly every 60 mins.

[pool-getschedule.sh](bin/pool-getschedule.sh)

Cardano's proof of stake system holds a lottery that pre-assigns the block production for the upcoming epoch. If the pool has sufficient stake and some luck, this script returns the slots for validating a block, or "No slots found for current epoch". Sends an e-mail with the result.

[pool-getstats.sh](bin/pool-getstats.sh)

Queries the pool statistics from the adapools.org API, and formats it as a prom file for feeding the results into the Prometheus/Grafana pool monitoring.

[check-node-release.sh](bin/check-node-release.sh)

Checks if Cardano released a new node software to upgrade. It runs periodically on a relay node, and checks the node version against the latest release version available in the Github repo. If a newer one is found, it sends a notification e-mail with the download link to the admin.
