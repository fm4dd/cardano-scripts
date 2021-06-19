#!/bin/bash
# ##################################################
# update-cardano-node.sh	20210410 fm4dd
# This script downloads and compiles the select
# version of the cardano node binaries.
# ##################################################

# ##################################################
# 0 Define the new node version
# ##################################################
echo "Node Update 0: set node version      "
echo "-------------------------------------"
# This string will set the git tag to checkout
version="1.27.0" # the cardano-node version to use. 
echo "Version to build: $version"
read -rsp $'#1 done - Press any key to continue...\n\n' -n1 key
echo

# ##################################################
# 1 Check prerequisite libraries
# ##################################################
echo "Node Update 1: sudo apt-get update -y"
echo "-------------------------------------"
sudo apt-get update -y
echo "Node Update 1: sudo apt-get install ... -y"
echo "-------------------------------------"
sudo apt-get install automake build-essential pkg-config libffi-dev libgmp-dev \
 libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq \
 wget libncursesw5 libtool autoconf -y
read -rsp $'#1 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 2 Check prerequisite haskell bins
# ##################################################
echo "Node Update 2: cabal update"
echo "-------------------------------------"
echo "Run: cabal update"
cabal update
echo "Run: cabal --version"
cabal --version
echo "Node Update 2: ghc check"
echo "-------------------------------------"
echo "Run: ghc --version"
which ghc
ghc --version
read -rsp $'#2 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 3 Clone node repo
# ##################################################
echo "Node Update #3: Clone node repo"
echo "-------------------------------------"
echo "cd ~/src; mv cardano-node cardano-node.orig"
cd ~/src; mv cardano-node cardano-node.orig
echo "git clone https://github.com/input-output-hk/cardano-node.git"
git clone https://github.com/input-output-hk/cardano-node.git
echo "Git returned $?"
if [ "$?" -ne 0 ]; then echo "Error: git clone was not successful!"; fi
read -rsp $'#3 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 4 Checkout selected node version
# ##################################################
echo "Node Update #4: Checkout version $version"
echo "-------------------------------------"
echo "cd cardano-node; git fetch --tags --recurse-submodules --all"
cd cardano-node; git fetch --tags --recurse-submodules --all
echo "git tag -l | grep $version"
git tag -l | grep $version
echo "git checkout tags/$version"
git checkout tags/$version
read -rsp $'#4 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 5 Check and set IOHK libsodium dependency
# ##################################################
echo "Node Update #5: Check IOHK libsodium "
echo "-------------------------------------"
echo "Check /usr/local/lib/libsodium.so.23.3.0"
ls -l /usr/local/lib/libsodium.so.23.3.0
echo "Check LD_LIBRARY_PATH includes /usr/local/lib"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
read -rsp $'#5 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 6 Prepare the compiler and start compilation
# ##################################################
echo "Node Update #6: Compile the binaries "
echo "-------------------------------------"
echo "Run: cabal configure --with-compiler=ghc-8.10.4"
cabal configure --with-compiler=ghc-8.10.4
echo "Add \"package cardano-crypto-praos\" to cabal.project.local"
echo "package cardano-crypto-praos" >>  cabal.project.local
echo "Add \"  flags: -external-libsodium-vrf\" to  cabal.project.local"
echo "  flags: -external-libsodium-vrf" >>  cabal.project.local
echo "Run: cabal build all - `date`"
read -rsp $'#6 ready - Press any key to continue...\n\n' -n1 key
cabal build all
echo "Node Update #6: done - `date`"
read -rsp $'#6 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 7 Check if we got new binaries
# ##################################################
echo "Node Update #7: Check new binaries "
echo "-------------------------------------"
echo "ls -l dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-node-$version/x/cardano-node/build/cardano-node/cardano-node"
ls -l dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-node-$version/x/cardano-node/build/cardano-node/cardano-node
echo "ls -l dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-$version/x/cardano-cli/build/cardano-cli/cardano-cli"
ls -l dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-$version/x/cardano-cli/build/cardano-cli/cardano-cli
echo "dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-node-$version/x/cardano-node/build/cardano-node/cardano-node --version"
dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-node-$version/x/cardano-node/build/cardano-node/cardano-node --version
echo "dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-$version/x/cardano-cli/build/cardano-cli/cardano-cli --version"
dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-$version/x/cardano-cli/build/cardano-cli/cardano-cli --version
read -rsp $'#7 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 8 Pack the new binaries
# ##################################################
echo "Node Update #8: pack the new binaries"
echo "-------------------------------------"
today=$(date +%Y%m%d)
echo "cd ~/src; mkdir $today-cardano-v$version"
cd ~/src; mkdir $today-cardano-v$version
echo "cp cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-$version/x/cardano-cli/build/cardano-cli/cardano-cli $today-cardano-v$version"
cp cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-cli-$version/x/cardano-cli/build/cardano-cli/cardano-cli $today-cardano-v$version
echo "cp cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-node-$version/x/cardano-node/build/cardano-node/cardano-node $today-cardano-v$version"
cp cardano-node/dist-newstyle/build/x86_64-linux/ghc-8.10.4/cardano-node-$version/x/cardano-node/build/cardano-node/cardano-node $today-cardano-v$version
echo "ls -l $today-cardano-v$version"
ls -l $today-cardano-v$version
echo "tar cvfz $today-cardano-v$version.tgz $today-cardano-v$version"
tar cvfz $today-cardano-v$version.tgz $today-cardano-v$version
read -rsp $'#8 done - Press any key to continue...\n\n' -n1 key
echo
# ##################################################
# 9 Distribute new binaries
# ##################################################
echo "Node Update #9: Send binaries to node"
echo "-------------------------------------"
echo "scp ~/src/$today-cardano-v$version.tgz 192.168.11.222:~/cardano"
scp ~/src/$today-cardano-v$version.tgz 192.168.11.222:~/cardano
echo "scp ~src/$today-cardano-v$version.tgz 192.168.11.223:~/cardano"
scp ~/src/$today-cardano-v$version.tgz 192.168.11.223:~/cardano
read -rsp $'#9 done - Press any key to continue...\n\n' -n1 key
echo
