#!/bin/sh -e

if [ -z "$BITCOIN_CORE_IP" ]; then
  BITCOIN_CORE_IP=$(getent hosts bitcoin-core | tr -s ' ' | awk '{ print $1 }')
fi
echo "Bitcoin ip: $BITCOIN_CORE_IP"

echo "Watching bitcoin core is running"
while true; do
  bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP getblockchaininfo 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Bitcoin core is not running, sleeping for 3 seconds"
    sleep 3
  else
    echo "Bitcoin core is running"
    break
  fi
done


echo "Checking if have wallet"
if [ ! -d /data/.bitcoin/regtest/wallets/wallet ]; then
  echo "Creating wallet"
  echo bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP createwallet "wallet"
  bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP createwallet "wallet"
  echo "Wallet created"
fi

echo "Checking if wallet is loaded"
if [ -z "$(bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP listwallets | grep wallet)" ]; then
  echo "Loading wallet"
  bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP loadwallet "wallet"
  echo "Wallet loaded"
fi

echo "Checking if have 101 blocks"
if [ "$(bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP getblockcount)" -lt 101 ]; then
  echo "Generating 101 blocks"
  bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP generatetoaddress 101 $(bitcoin-cli -rpcconnect=$BITCOIN_CORE_IP -rpcwallet=wallet getnewaddress)
  echo "101 blocks generated"
fi