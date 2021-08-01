#!/bin/bash
# ###############################################
# check-node-release.sh:
# This script checks if Cardano released a new
# version of its node software package.
# It queries the version string of the github
# repo release section for the 'latest' entry,
# and compares it to the running version. If 
# the github release is newer, a notification
# e-mail goes out for latest package download.
#
# Requires: apt install curl ssmtp
#
# Example run:
# pi@lp-ms03:~/cardano/stake-schedule$ ./check-node-release.sh
# currentVerStr: 1.26.2
# latest VerStr: 1.27.0
# checkResult: <
# Node Update: Cardano released version 1.27.0, we are on version 1.26.2
# See also Github at https://github.com/input-output-hk/cardano-node/releases
# This notification was created by check-node-release.sh on host lp-ms03
# Sent notification email to admin@my-pool.com
#
# Run through /etc/crontab e.g. once per week
# # Check for new cardano node software release
# 9  8    * * 6 pi      /home/pi/cardano/relay/bin/check-node-release.sh > /dev/null 2>&1
# ###############################################
NODEREPO="input-output-hk/cardano-node"
NODEBIN="/home/pi/cardano/relay/bin/cardano-node"
RECIPIENT="admin@my-pool.com"
SENDER="'node version-checker' <no-reply@my-pool.com>"
SUBJECT="cardano-node version notification"

# ###############################################
# get_latest_release() retrieves the release str
# of a given repo as $1, listed under 'latest'
# ###############################################
function get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# ###############################################
# version_compare() numerically checks 2 version
# strings arg $1 and $2, returns '<', '>', or '='
# ###############################################
function version_compare () {
  function sub_ver () {
    local len=${#1}
    temp=${1%%"."*} && indexOf=`echo ${1%%"."*} | echo ${#temp}`
    echo -e "${1:0:indexOf}"
  }
  function cut_dot () {
    local offset=${#1}
    local length=${#2}
    echo -e "${2:((++offset)):length}"
  }
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "=" && exit 0
  fi
  local v1=`echo -e "${1}" | tr -d '[[:space:]]'`
  local v2=`echo -e "${2}" | tr -d '[[:space:]]'`
  local v1_sub=`sub_ver $v1`
  local v2_sub=`sub_ver $v2`
  if (( v1_sub > v2_sub )); then
    echo ">"
  elif (( v1_sub < v2_sub )); then
    echo "<"
  else
    version_compare `cut_dot $v1_sub $v1` `cut_dot $v2_sub $v2`
  fi
}

# ###############################################
# get the node version from the running system
# ###############################################
currentVerStr=$($NODEBIN version | head -1 | cut -d " " -f 2)
if  [ -z $currentVerStr ]; then
   echo "Error: Could not get local cardano-node version, exiting..."
   exit
fi
# debug: set a different version to test the script
#currentVerStr="1.26.6"
echo "currentVerStr: $currentVerStr"

# ###############################################
# latest node version from the github repository
# ###############################################
latestVerStr=$(get_latest_release $NODEREPO)
if  [ -z $latestVerStr ]; then
   echo "Error: Could not get github cardano-node version, exiting..."
   exit
fi
echo "latest VerStr: $latestVerStr"

# ###############################################
# Check which side is running a newer version
# ###############################################
checkResult=$(version_compare "$currentVerStr" "$latestVerStr")
echo "checkResult: $checkResult"

if  [ "$checkResult" == "=" ]; then
    # we are running latest, nothing to worry about
    echo "OK: cardano-node is running the latest version $latestVerStr"
    exit
fi
if [ "$checkResult" == ">" ]; then
    # we are running newer than relased? Something is wrong...
    echo "Error: cardano-node version $currentVerStr higher than github version $latestVerStr"
    exit
fi

# ###############################################
# Github has the newer version, send a heads up
# ###############################################
MESSAGE="Node Update: Cardano released version $latestVerStr, we are on version $currentVerStr
See also Github at https://github.com/input-output-hk/cardano-node/releases
Latest pre-compiled binary at
https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux/latest-finished

This notification was created by check-node-release.sh on host `hostname`"
echo $MESSAGE

/usr/sbin/ssmtp -t << EOF
To: $RECIPIENT
From: $SENDER
Subject: $SUBJECT

$MESSAGE
EOF

echo "Sent notification email to $RECIPIENT"
