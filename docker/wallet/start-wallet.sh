#!/bin/bash

set -e
export NETWORK=${NETWORK:-"regtest"}
export ELECTRUM_URL=${ELECTRUM_URL:-"tcp://esplora-api:60401"}

# check ENV WALLET_NAME and MNEMONIC is set
if [ -z "$WALLET_NAME" ]; then
  echo "Error: WALLET_NAME is not set"
  exit 1
fi
if [ -z "$MNEMONIC" ]; then
  echo "Error: MNEMONIC is not set"
  exit 1
fi

echo "Starting wallet..."
echo "Wallet Name: $WALLET_NAME"

function restore_key() {
  bdk-cli -n $NETWORK key restore --mnemonic "$1"
}

function parse_xprv() {
  json_string="$1"
  xprv=$(echo "$json_string" | jq -r '.xprv')
  echo $xprv
}

function parse_fingerprint() {
  json_string="$1"
  fingerprint=$(echo "$json_string" | jq -r '.fingerprint')
  echo $fingerprint
}

function generate_xpub_descriptor() {
  derive_path="m/86h/1h/0h"
  xprv="$1"
  res=$(bdk-cli key derive --path "$derive_path" --xprv $xprv)
  xpub=$(_parse_xpub_descriptor "$res")
  echo $xpub
}

function generate_xprv_descriptor() {
  derive_path="m/86h/1h/0h"
  xprv="$1"
  res=$(bdk-cli key derive --path "$derive_path" --xprv $xprv)
  xpub=$(_parse_xprv_descriptor "$res")
  echo $xpub
}

function _parse_xpub_descriptor() {
  json_string="$1"
  xpub=$(echo "$json_string" | jq -r '.xpub')
  echo $xpub
}

function _parse_xprv_descriptor() {
  json_string="$1"
  xpub=$(echo "$json_string" | jq -r '.xprv')
  echo $xpub
}

function fix_xpub_descriptor() {
  xpub="$1"
  fixed_xpub=$(echo "$xpub" | sed 's/\*$/<0;1;9;10>\/\*/')
  echo "$fixed_xpub"
}

function fix_rgb_descriptor() {
  xprv="$1"
  rgb_descriptor="tr(${xprv}/86'/1'/0'/9/*)"
  echo "$rgb_descriptor"
}

function generate_address() {
  descriptor="$1"
  address=$(bdk-cli -n $NETWORK wallet --descriptor $descriptor get_new_address)
  echo $address | jq -r '.address'
}

function concat_rgb_descriptor() {
  xprv="$1"
  rgb_descriptor="tr(${xprv}/86'/1'/0'/9/0)"
  echo "$rgb_descriptor"
}

function concat_bitcoin_descriptor() {
  xprv="$1"
  descriptor="tr(${xprv}/86'/1'/0'/0/0)"
  echo "$descriptor"
}

function get_balance() {
  rgb_descriptor="$1"
  bdk-cli -n $NETWORK wallet -w $WALLET_NAME -s $ELECTRUM_URL --descriptor $rgb_descriptor sync >/dev/null
  bdk-cli -n $NETWORK wallet -w $WALLET_NAME -s $ELECTRUM_URL --descriptor $rgb_descriptor get_balance
}

function start_repl() {
  bdk-cli -n $NETWORK repl -w $1 -s $ELECTRUM_URL --descriptor "$2"
}

print_row() {
  printf '%-20s:  %s\n' "$1" "$2"
}

json=$(restore_key "$MNEMONIC")
fingerprint=$(parse_fingerprint "$json")
root_xprv=$(parse_xprv "$json")
xpub=$(generate_xpub_descriptor $root_xprv)
xprv=$(generate_xprv_descriptor $root_xprv)
fixed_xpub=$(fix_xpub_descriptor $xpub)
rgb_descriptor_9_0=$(concat_rgb_descriptor $root_xprv)
rgb_address=$(generate_address $rgb_descriptor_9_0)
rgb_descriptor_9=$(fix_rgb_descriptor $root_xprv)
balance="$(get_balance $rgb_descriptor_9 | jq -r '.satoshi.confirmed')"

bitcoin_descriptor=$(concat_bitcoin_descriptor $root_xprv)
bitcoin_address=$(generate_address $bitcoin_descriptor)

print_row "Network" "$NETWORK"
print_row "Wallet Name" "$WALLET_NAME"
print_row "Fingerprint" "$fingerprint"
print_row "Root XPRV" "$root_xprv"
print_row "XPUB" "$xpub"
print_row "Fixed XPUB" "$fixed_xpub"
print_row "RGB Descriptor 9/0" "$rgb_descriptor_9_0"
print_row "RGB Address" "$rgb_address"
print_row "RGB Descriptor 9/*" "$rgb_descriptor_9"
print_row "Bitcoin Descriptor 0/0" "$bitcoin_descriptor"
print_row "Bitcoin Address" "$bitcoin_address"
print_row "Balance" "$balance"
echo "Wallet is ready"

function welcome() {
  echo "Starting REPL with descriptor ${2}"
  echo "use 'wallet' to interact with the wallet of ${1}"
  echo "use 'help' to see available commands"
  echo "Available commands:"
  echo "  wallet sync"
  echo "  wallet get_balance"
  echo "  wallet get_new_address"
  echo "  wallet list_unspent"
  echo "Press Ctrl+D to exit"
}

if [ "$1" = "repl" ]; then
  echo 'Please choose a descriptor to start the REPL:'
  echo ' - (9) RGB Descriptor 9/*:' $rgb_descriptor_9
  echo ' - (90) RGB Descriptor 9/0:' $rgb_descriptor_9_0
  echo ' - (00) Bitcoin Descriptor 0/0:' $bitcoin_descriptor
  echo ' - (*) quit'
  if [ -n "$2" ]; then
    choice=$2
    echo "Choice is set to $choice, skipping the prompt..."
  else
    echo -n "Enter your choice: "
    read -r choice
  fi
  case $choice in
    9)
      welcome $WALLET_NAME $rgb_descriptor_9
      bdk-cli -n $NETWORK repl -w $WALLET_NAME -s $ELECTRUM_URL --descriptor "$rgb_descriptor_9"
      ;;
    90)
      welcome $WALLET_NAME.90 $rgb_descriptor_9_0
      bdk-cli -n $NETWORK repl -w $WALLET_NAME.90 -s $ELECTRUM_URL --descriptor "$rgb_descriptor_9_0"
      ;;
    00)
      welcome $WALLET_NAME.00 $bitcoin_descriptor
      bdk-cli -n $NETWORK repl -w $WALLET_NAME.00 -s $ELECTRUM_URL --descriptor "$bitcoin_descriptor"
      ;;
    *)
      echo "Exiting..."
      ;;
  esac
else
  echo "Press Ctrl+C to exit"
  while true; do sleep 1; done
fi
