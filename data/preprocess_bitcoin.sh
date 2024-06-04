#!/bin/bash
#
# This script is only used to preprocess the JSON file with the Bitcoin market price and to convert it into a csv file.
# To download the JSON file with the Bitcoin market price, go to https://www.blockchain.com/explorer/charts/market-price and export the JSON file with the following parameters:
#   "metric1": "market-price", "metric2": "market-price", "type": "linear", "average": "1d", "timespan": "all"
# The computed Bitcoin market price is the average market price per month, since we also compute average ransoms per month.
# The output of this script will be written in the files bitcoin_market_price.csv.


set -euo pipefail
IFS=$'\n\t'

umask 077


first_month="2012-03"
last_month="2024-03"

output_file="bitcoin_market_price.csv"

function usage() {
    echo -e "Usage: $0 market-price.json\n"
    echo -e "\tmarket-price.json - the JSON file with the Bitcoin market price taken from https://www.blockchain.com/explorer/charts/market-price"
    echo -e '\t\t(export the JSON file with the following parameters: "metric1": "market-price", "metric2": "market-price", "type": "linear", "average": "1d", "timespan": "all")'
}


# Check if exactly one arguments have been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }


# The time is represented by milliseconds, so we have to divide by 1000
jq -r '."market-price".[] | [ .x, .y ] | @csv' "$1" |
    awk -F, '{ $1 = strftime("%Y-%m", $1 / 1000); printf("%s,%f\n", $1, $2); }' |
    awk -F, '
        {
            sum[$1] += $2;
            count[$1] += 1;
        }
        END {
            for (month in count) {
                avg_month_price = sum[month] / count[month];
                printf("%s,%.2f\n", month, avg_month_price);
            }
        }' |
        sort -t, -k 1,1 |  # Sort chronologically
        awk -F, '$1 >= "'$first_month'" && $1 <= "'$last_month'" { print $0; }' |
        awk -F, 'BEGIN { print "Month,Price"; } { print $0; }' > "$output_file"
