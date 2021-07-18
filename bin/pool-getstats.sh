#!/bin/bash
# ##############################################################
# pool-getstats.sh
#
# This script queries the pool data from adapools.org API
# and formats it for feeding into the prometheus/grafana monitor
# Orig description:
# https://crypto2099.io/adding-pool-stats-to-grafana-dashboard/
#
# The outfile is consumed through ExecStart=/usr/local/bin/node_exporter \
# --collector.textfile.directory="/home/pi/cardano/producer/log" \
# --collector.textfile
# Best to be configured in:
# vi /etc/default/prometheus-node-exporter, see ARGS=""
# The text collector parses all files in that directory matching *.prom
# 
# This script runs on the node periodically through /etc/crontab, e.g.
# # query the cardano pool stats once every 4 hours:
# 20 */4  * * *   pi      /home/pi/cardano/producer/bin/pool-getstats.sh
#
# Set POOLID to query the correct pool, OUTFILE for the result
# ##############################################################
POOLID="120164*********************************************4238dc7"
OUTFILE="/home/pi/cardano/producer/log/adapools.prom"
# uncomment next line for debug output
# echo "/usr/bin/curl https://js.adapools.org/pools/$POOLID/summary.json 2>/dev/null | /usr/bin/jq '.data | del(.hist_bpe, .handles, .hist_roa, .db_ticker, .db_name, .db_url, .ticker_orig, .pool_id, .pool_id_bech32, .group_basic, .direct, .db_description)' | tr -d \\\"{},: | awk NF | sed -e 's/null/0/' | sed -e 's/^[ \t]*/adapools_/' > $OUTFILE"
# command to execute
/usr/bin/curl https://js.adapools.org/pools/${POOLID}/summary.json 2>/dev/null | /usr/bin/jq '.data | del(.hist_bpe, .handles, .hist_roa, .db_ticker, .db_name, .db_url, .ticker_orig, .pool_id, .pool_id_bech32, .group_basic, .direct, .db_description, .stake_x_deleg)' | tr -d \"{},: | awk NF |  sed -e 's/null/0/' | sed -e 's/^[ \t]*/adapools_/' > "$OUTFILE"
