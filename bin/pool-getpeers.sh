#!/bin/bash
# shellcheck disable=SC2086,SC2034
# ##########################################################
# pool-getpeers.sh
# Because Cardano has no peer autodiscovery, all peers are
# centrally registered and distributed for node interconnect.
#
# Connects to the API at https://api.clio.one/htopology/v1
# It returns a list of Cardano node IP's limited by MAXPEERS
# and announces our own relay node to the world.
#
# This script is a copy of topologyupdater.sh provided by
# https://github.com/cardano-community/guild-operators
# to be run exactly once per hour through cron:
# # Publish node to the topology fetch list, every hour
# 02 *  * * *   pi      /home/pi/cardano/relay/bin/pool-getpeers.sh > /dev/null 2>&1
#
# Success Result:
# { "resultcode": "204", "datetime":"2021-03-19 22:02:02", "clientIp":
# "xxx.xx.xx.xxx", "iptype": 4, "msg": "glad you're staying with us" }
#
# Error Results:
# { "resultcode": "504", "datetime":"2021-03-19 21:02:03", "clientIp":
# "xxx.xx.xx.xxx", "iptype": 4, "msg": "one request per hour please" }
# { "resultcode": "503", "datetime":"2021-04-10 08:02:04", "clientIp":
# "xxx.xx.xx.xxx", "msg": "blockNo 5505872 seems out of sync. please retry" }
# { "resultcode": "502", "datetime":"2021-04-10 09:02:01", "clientIp":
# ""xxx.xx.xx.xxx, "msg": "invalid blockNo []" }
# ##########################################################

# In a cluster, only execute if the relay is running
PID=$(pidof /home/pi/cardano/relay/bin/cardano-node)
if [ $? == 1 ]; then
  exit
fi

 
MAXPEERS=12
OUTFILE=/home/pi/cardano/relay/etc/mainnet-topology.json.new
USERNAME=pi
CNODE_PORT=5513 # must match your relay node port as set in the startup command
CNODE_HOSTNAME="CHANGE ME"  # optional. must resolve to the IP you are requesting from
CNODE_HOME=/home/pi/cardano/relay
CNODE_BIN="${CNODE_HOME}/bin"
CNODE_LOG_DIR="${CNODE_HOME}/log"
GENESIS_JSON="${CNODE_HOME}/etc/mainnet-shelley-genesis.json"
NETWORKID=$(jq -r .networkId $GENESIS_JSON)
CNODE_VALENCY=1   # optional for multi-IP hostnames
NWMAGIC=$(jq -r .networkMagic < $GENESIS_JSON)
[[ "${NETWORKID}" = "Mainnet" ]] && HASH_IDENTIFIER="--mainnet" || HASH_IDENTIFIER="--testnet-magic ${NWMAGIC}"
[[ "${NWMAGIC}" = "764824073" ]] && NETWORK_IDENTIFIER="--mainnet" || NETWORK_IDENTIFIER="--testnet-magic ${NWMAGIC}"
 
export PATH="${CNODE_BIN}:${PATH}"
export CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/node.sock"
 
blockNo=$(/home/pi/cardano/relay/bin/cardano-cli query tip ${NETWORK_IDENTIFIER} | jq -r .block)
 
# Note:
# if you run your node in IPv4/IPv6 dual stack network configuration and want announced the
# IPv4 address only please add the -4 parameter to the curl command below  (curl -4 -s ...)
if [ "${CNODE_HOSTNAME}" != "CHANGE ME" ]; then
  T_HOSTNAME="&hostname=${CNODE_HOSTNAME}"
else
  T_HOSTNAME=''
fi

if [ ! -d ${CNODE_LOG_DIR} ]; then
  mkdir -p ${CNODE_LOG_DIR};
fi
 
curl -s "https://api.clio.one/htopology/v1/?port=${CNODE_PORT}&blockNo=${blockNo}&valency=${CNODE_VALENCY}&magic=${NWMAGIC}${T_HOSTNAME}" | tee -a $CNODE_LOG_DIR/topologyUpdater_lastresult.json

curl -s -S -o ${OUTFILE} "https://api.clio.one/htopology/v1/fetch/?max=${MAXPEERS}&customPeers=127.0.0.1:6000:1|relays-new.cardano-mainnet.iohk.io:3001:2"
