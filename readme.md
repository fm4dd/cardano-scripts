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

[ledger2master.py](wallet/ledger2master.py)

Extracts the Ledger HW wallet master key data from mnemonics. Together with 'master2wallet.sh', it converts a Ledger-connected Daedalus HW wallet into a soft wallet. [...details](docs/ledger2master.md)

[master2wallet.sh](wallet/master2wallet.sh)

Creates the individual key files from a Daedalus wallet mnemonic, or from a Ledger-extracted master key. The key files enable Cardano network transactions on the commandline, e.g. using 'cardano-cli'. [...details](docs/master2wallet.md)

[withdraw-rewards-tx.sh](wallet/withdraw-rewards-tx.sh)

Creates a transaction to withdraw all received staking rewards from the wallet's stake rewards address. A zero balance of the stake rewards address is the prerequiste condition to deregister the wallet from staking, and to reclaim the stake key deposit. [...details](docs/withdraw-rewards-tx.md)

[stake-deregister-tx.sh](wallet/stake-deregister-tx.sh)

Creates a transaction to to deregister the wallet from staking, and to reclaim the stake key deposit. [...details](docs/stake-deregister-tx.md)

