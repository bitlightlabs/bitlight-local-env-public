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

function generate_rgb_address() {
  descriptor="$1"
  address=$(bdk-cli -n $NETWORK wallet --descriptor $descriptor get_new_address)
  echo $address | jq -r '.address'
}

function concat_rgb_descriptor() {
  xprv="$1"
  rgb_descriptor="tr(${xprv}/86'/1'/0'/9/0)"
  echo "$rgb_descriptor"
}

function get_balance() {
  rgb_descriptor="$1"
  bdk-cli -n $NETWORK wallet -w $WALLET_NAME -s $ELECTRUM_URL --descriptor $rgb_descriptor sync >/dev/null
  bdk-cli -n $NETWORK wallet -w $WALLET_NAME -s $ELECTRUM_URL --descriptor $rgb_descriptor get_balance
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
rgb_address=$(generate_rgb_address $rgb_descriptor_9_0)
rgb_descriptor_9=$(fix_rgb_descriptor $root_xprv)
balance="$(get_balance $rgb_descriptor_9 | jq -r '.satoshi.confirmed')"

print_row "Network" "$NETWORK"
print_row "Wallet Name" "$WALLET_NAME"
print_row "Fingerprint" "$fingerprint"
print_row "Root XPRV" "$root_xprv"
print_row "XPUB" "$xpub"
print_row "Fixed XPUB" "$fixed_xpub"
print_row "RGB Descriptor 9/0" "$rgb_descriptor_9_0"
print_row "RGB Address" "$rgb_address"
print_row "RGB Descriptor 9/*" "$rgb_descriptor_9"
print_row "Balance" "$balance"
echo "Wallet is ready"

if [ "$1" = "repl" ]; then
  echo "Starting REPL..."
  echo "use 'wallet' to interact with the wallet of ${WALLET_NAME}"
  echo "use 'help' to see available commands"
  echo "Available commands:"
  echo "  wallet sync"
  echo "  wallet get_balance"
  echo "  wallet get_new_address"
  echo "  wallet list_unspent"
  echo "Press Ctrl+D to exit"
  bdk-cli -n $NETWORK repl -w $WALLET_NAME -s $ELECTRUM_URL --descriptor "$rgb_descriptor_9"
  exit 0
else
  echo "Press Ctrl+C to exit"
  while true; do sleep 1; done
fi
