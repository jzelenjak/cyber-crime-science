#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

umask 077

BITCOIN_FACTOR=100000000


function usage() {
    echo "Usage: $0 ransomwhere.json data.json"
}

function print_title() {
    echo -ne "\e[1;91m" ; echo -n "$1" ; echo -e "\e[0m"
}

function print_result() {
    echo -ne "\e[1;96m" ; echo -ne "$1" ; echo -e "\e[0m"
}

function print_misc() {
    echo -ne "\e[1;93m" ; echo -ne "$1" ; echo -e "\e[0m"
}


# Check if exactly two arguments have been provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Check if the provided files exist
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
[[ -f "$2" ]] || { echo "File $2 does not exist." >&2 ; exit 1; }

# To download the full dataset: curl -sL "https://api.ransomwhe.re/export" | jq --indent 0 '.result' > data.json
# George's dataset: https://zenodo.org/records/6512123

george_data="$1"
full_data="$2"

# Comparing addresses
num_addresses_george=$(jq '.[].address' "$george_data" | sort -u | wc -l)
num_addresses_full=$(jq '.[].address' "$full_data" | sort -u | wc -l)
increase_num_addresses=$((num_addresses_full - num_addresses_george))

# Extracting more fields from JSON, use something like:
# `jq -r '.[] | { address: .address, family: .family, createdAt: .createdAt, updatedAt: .updatedAt, trans: .transactions | length } | [ .address, .family, .createdAt, .updatedAt, .trans ] | @csv' "$george"
empty_address_entries_george=$(jq -r '.[] | { address: .address, family: .family, trans: .transactions | length } | [ .address, .family, .trans ] | @csv' "$george_data" | tr -d '"' | awk -F, '$NF == 0 { print $0 }' | sort)
empty_address_entries_full=$(jq -r '.[] | { address: .address, family: .family, trans: .transactions | length } | [ .address, .family, .trans ] | @csv' "$full_data" | tr -d '"' | awk -F, '$NF == 0 { print $0 }' | sort)
new_empty_addresses=$(comm -23 <(echo -e "$empty_address_entries_full") <(echo -e "$empty_address_entries_george"))  # Only present in the full dataset
new_empty_addresses_families=$(echo -e "$new_empty_addresses" | cut -d, -f2 | sort | uniq -c | sort -rn | awk '{ print $2 ": " $1 }')  # Extract the family, compute the count
increase_empty_addresses=$(echo -e "$new_empty_addresses_families" | awk -F': ' '{ count += $2; } END { print count; }')

print_title "Number of addresses"
print_result "George: $num_addresses_george"
print_result "Full: $num_addresses_full"
print_result "Increase: $increase_num_addresses"
print_result "Increase (empty addresses): $increase_empty_addresses"
print_misc "$new_empty_addresses_families"
echo -ne "\n"

# New addresses (not present in George's dataset)
echo -e "\e[1;97mSanity check"
# Only in George's dataset (should be 0)
echo -n "Only George: "
comm -23 <(jq -r '.[].address' "$george_data" | sort) <(jq -r '.[].address' "$full_data" | sort) | wc -l
# Only in the full dataset
echo -n "Only Full: "
comm -13 <(jq -r '.[].address' "$george_data" | sort) <(jq -r '.[].address' "$full_data" | sort) | wc -l
# Intersection
echo -n "Intersection: "
comm -12 <(jq -r '.[].address' "$george_data" | sort) <(jq -r '.[].address' "$full_data" | sort) | wc -l
echo -ne "\n\e[0m"

# Comparing the number of transactions
num_transactions_george=$(jq '.[].transactions | length' "$george_data" | paste -d '+' -s | bc)
num_transactions_full=$(jq '.[].transactions | length' "$full_data" | paste -d '+' -s | bc)
increase_num_transactions=$((num_transactions_full - num_transactions_george))
print_title "Number of transactions"
print_result "George: $num_transactions_george"
print_result "Full: $num_transactions_full"
print_result "Increase: $increase_num_transactions"
echo -ne "\n"

# Comparing total payment sums (BTC)
payment_sum_btc_george=$(jq '.[].transactions.[].amount' "$george_data" | paste -d '+' -s | bc | awk '{ printf "%f", $1 / '"$BITCOIN_FACTOR"'; }')
payment_sum_btc_full=$(jq '.[].transactions.[].amount' "$full_data" | paste -d '+' -s | bc | awk '{ printf "%f", $1 / '"$BITCOIN_FACTOR"'; }')
increase_payment_sum_btc=$(bc <<< "$payment_sum_btc_full-$payment_sum_btc_george")
print_title "Total payment sum (BTC)"
print_result "George: $payment_sum_btc_george"
print_result "Full: $payment_sum_btc_full"
print_result "Increase: $increase_payment_sum_btc"
echo -ne "\n"

# Comparing total payment sums (USD)
payment_sum_usd_george=$(jq '.[].transactions.[].amountUSD' "$george_data" | paste -d '+' -s | bc | awk '{ printf "%f", $1; }')
payment_sum_usd_full=$(jq '.[].transactions.[].amountUSD' "$full_data" | paste -d '+' -s | bc | awk '{ printf "%f", $1; }')
increase_payment_sum_usd=$(bc <<< "$payment_sum_usd_full-$payment_sum_usd_george")
print_title "Total payment sum (USD)"
print_result "George: $payment_sum_usd_george"
print_result "Full: $payment_sum_usd_full"
print_result "Increase: $increase_payment_sum_usd"
echo -ne "\n"

# Comparing time ranges
print_title "Time range of transactions"
transactions_george=$(jq '.[].transactions.[].time' "$george_data" | awk '{ $1 = strftime("%Y-%m-%d %H:%M:%S", $1); print $0; }' | sort | awk 'NR == 1 { print "First transaction (George): " $0; }; END { print "Last transaction (George): " $0; }')
transactions_full=$(jq '.[].transactions.[].time' "$full_data" | awk '{ $1 = strftime("%Y-%m-%d %H:%M:%S", $1); print $0; }' | sort | awk 'NR == 1 { print "First transaction (Full): " $0; }; END { print "Last transaction (Full): " $0; }')
print_result "$transactions_george"
print_result "$transactions_full"
echo -ne "\n"

# New families (not present in George's dataset)
families_george=$(jq -r '.[].family' "$george_data" | sort -u)
families_full=$(jq -r '.[].family' "$full_data" | sort -u)
num_families_george=$(echo -e "$families_george" | wc -l)
num_families_full=$(echo -e "$families_full" | wc -l)
increase_num_families=$((num_families_full - num_families_george))
print_title "Number of families"
print_result "George: $num_families_george"
print_result "Full: $num_families_full"
print_result "Increase: $increase_num_families"
echo -ne "\n"

echo -e "\e[1;97mSanity check"
# Only in George's dataset (should be 0)
echo -n "Only George: "
comm -23 <(echo -e "$families_george") <(echo -e "$families_full") | wc -l
# Only in the full dataset
echo -n "Only Full: "
comm -13 <(echo -e "$families_george") <(echo -e "$families_full") | wc -l
# Intersection
echo -n "Intersection: "
comm -12 <(echo -e "$families_george") <(echo -e "$families_full") | wc -l
echo -e "\e[0m"

new_families=$(comm -23 <(echo -e "$families_full") <(echo -e "$families_george"))  # Only in the full dataset
num_new_families=$(echo -e "$new_families" | wc -l)
print_title "New families (${num_new_families})"
print_misc "$new_families"
echo -ne "\n"

