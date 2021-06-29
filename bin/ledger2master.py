#!/usr/bin/python3
# ##########################################################
# ledger2master.py
#
# Create a Ledger MasterKey from its BIP39 mnemonic sentence
# returns the wallet master key to derive Cardano soft wallet
# address keys with the master2wallet.sh script
# output e.g. like "402b03cd9...1492658" (192-char hex string)
#
# ##########################################################
# ATTENTION: Extracting master keys is very dangerous!!!!!!!
# Unintented mnemomic or key access may cause loss of funds!
# Derived keys create a soft wallet w/o needing a HW device!
# ##########################################################

import os
import sys
import binascii
import hmac
import hashlib
# bip functions see https://pypi.org/project/bip-utils/
# if needed do pip3 install bip_utils, and then import:
# from bip_utils import Bip39EntropyGenerator, Bip39MnemonicGenerator, Bip39MnemonicValidator, Bip39SeedGenerator, Bip39WordsNum, Bip39Languages
from bip_utils import Bip39MnemonicGenerator, Bip39WordsNum, Bip39Languages

# ##########################################################
# enter the 24-word ledger mnemonic for the key conversion
# !!! Delete it after conversion to prevent losing funds !!!
# !!! from inadvertantly leaking it with this script !!!!!!!
# ##########################################################
mnemonic = ""

# ##########################################################
# test mnemonics - "abandon abandon abandon..." are tests
# whose entropy value is b"00000000000000000000000000000000"
# ##########################################################
#mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
# Above 12-word test mnemonic will create this test masterkey:
#testmaster = "402b03cd9c8bed9ba9f9bd6cd9c315ce9fcc59c7c25d37c85a36096617e69d418e35cb4a3b737afd007f0688618f21a8831643c0e6c77fc33c06026d2a0fc93832596435e70647d7d98ef102a32ea40319ca8fb6c851d7346d3bd8f9d1492658"
# another test mnemonic for 24-word variant
#mnemonic ="abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
#testmaster = "48a8bed7f7f5e33e640d883ddf77df9768d91ad5cb7c68fb8fa8792f82126352ea0ed23bd0fd594340c7342229e928825970c4343b0ad191ae53fb684b9860bb1b51dc0e67e858099f64691e7e62cbf6a408d5fb907fdc7ac97344baaf175c6e"

# ##########################################################
# For tests we can also get random 24 word mnemonics with a
# default language (English)
# ##########################################################
#mnemonic = Bip39MnemonicGenerator().FromWordsNumber(Bip39WordsNum.WORDS_NUM_24)
#print("debug mnemonic word str: " + mnemonic)

if len(mnemonic.split()) != 24:
   print("Error: No mnemonic wordlist received; exiting...")
   exit(127)

# ##########################################################
# convert mnemonic to entropy bytes with default language (English)
# ##########################################################
# entropy = Bip39MnemonicValidator(mnemonic).GetEntropy()
# print("debug entropy bytes: " + binascii.hexlify(bytearray(entropy)).decode('ascii'))

# ##########################################################
# convert entropy to mnemonic
# ##########################################################
# mnemonic2 = Bip39MnemonicGenerator().FromEntropy(entropy)
# print("debug mnemonic word str: " + mnemonic2)

# ######################################################
# Get the seed from the provided BIP39 mnemonic sentence
# ######################################################
hf_name = "sha512"
hashpass = mnemonic.encode()
salt = b"mnemonic"
iterations = 2048
keylen = 64
masterseed = bytearray(hashlib.pbkdf2_hmac(hf_name, hashpass, salt, iterations, keylen))

hmac_key = b"ed25519 seed"
# message needs to be '1' + masterseed
message = bytearray(b'\x01')
message.extend(masterseed)
# ######################################################
# generate the chaincode cc
# ######################################################
cc = hmac.digest(hmac_key, message, hashlib.sha256)
# print("debug masterseed digest: " + binascii.hexlify(cc).decode('ascii'))
# print("debug should be string : 32596435e70647d7d98ef102a32ea40319ca8fb6c851d7346d3bd8f9d1492658")

# ######################################################
# create the hash of seed. Needs bytearray type to modify
# ######################################################
i = bytearray(hmac.digest(hmac_key, masterseed, hashlib.sha512))
while (i[31] & 0b00100000):
    i = bytearray(hmac.digest(hmac_key, i, hashlib.sha512))
    #print("debug masterseed i-[31]: " + format(i[31], '08b'))
    
i[0]  &= 0b11111000  # clear the lowest 3 bits
i[31] &= 0b01111111  # clear the highest bit
i[31] |= 0b01000000  # set the 2nd highest bit
#print("debug masterseed digest: " + binascii.hexlify(i).decode('ascii'))

# ##########################################################
# Final masterkey assembly: concat extended key + chaincode
# result is 96 bytes key data
# ##########################################################
masterkey = i + cc

# ##########################################################
# Convert masterkey to 192-char printable hex string
# ##########################################################
masterstring = binascii.hexlify(bytearray(masterkey)).decode('ascii')
print("final masterkey str: " + masterstring)
if 'testmaster' in locals():
    print("debug should be str: " + testmaster)
