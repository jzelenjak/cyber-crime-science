#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

umask 077


BITCOIN_FACTOR=100000000
TOP_N=15

function usage() {
    echo "Usage: $0 data.json"
}

function print_title() {
    echo -ne "\e[1;91m"
    echo -ne "$1"
    echo -e "\e[0m"
}

function print_result() {
    echo -ne "\e[1;96m"
    echo -ne "$1"
    echo -e "\e[0m"
}

function compute_stats() {
    jq -r '.[] | .family as $family | .transactions[] | [$family, .amount, .amountUSD] | @csv' "$1" | tr -d '"' |
        awk -F, '
        {
            count[$1] += 1;
            sumBTC[$1] += $2 / '"$BITCOIN_FACTOR"';
            sumUSD[$1] += $3;
        }
        END {
            for (family in count) {
                sumBTC_rounded = int(sumBTC[family] * 100 + 0.5) / 100;
                sumUSD_rounded = int(sumUSD[family] * 100 + 0.5) / 100;
                printf("%s,%d,%.2f,%.2f\n", family, count[family], sumBTC_rounded, sumUSD_rounded);
            }
        }'
}


# Check if exactly one argument has been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
# To download the file: curl -sL "https://api.ransomwhe.re/export" | jq --indent 0 '.result' > data.json


header="Family,Count,Sum (BTC),Sum (USD)"
families=$(compute_stats "$1")
top_families_by_count=$(echo -e "$families" | sort -t, -k2,2 -rn | awk -F, 'BEGIN { print "'"$header"'"; } NR <= '"$TOP_N"' { print $0; }')
top_families_by_btc=$(echo -e "$families" | sort -t, -k3,3 -rg | awk -F, 'BEGIN { print "'"$header"'"; } NR <= '"$TOP_N"' { print $0; }')
top_families_by_usd=$(echo -e "$families" | sort -t, -k4,4 -rg | awk -F, 'BEGIN { print "'"$header"'"; } NR <= '"$TOP_N"' { print $0; }')
#echo -e "$top_families_by_count\n" > top_families.csv
#echo -e "$top_families_by_btc\n" >> top_families.csv
#echo -e "$top_families_by_usd" >> top_families.csv

top_families_by_count_pretty=$(echo -e "$top_families_by_count" | tr ',' '\t' | column -t -s $'\t')
top_families_by_btc_pretty=$(echo -e "$top_families_by_btc" | tr ',' '\t' | column -t -s $'\t')
top_families_by_usd_pretty=$(echo -e "$top_families_by_usd" | tr ',' '\t' | column -t -s $'\t')

print_title "Top $TOP_N families by the number of transactions"
print_result "$top_families_by_count_pretty"
print_title "\nTop $TOP_N families by the payment sum in BTC"
print_result "$top_families_by_btc_pretty"
print_title "\nTop $TOP_N families by the payment sum in USD"
print_result "$top_families_by_usd_pretty"

