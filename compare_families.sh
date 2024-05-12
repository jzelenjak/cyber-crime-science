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


function compute_timeline_families() {
    # Expects the full JSON file (data.json)
    jq -r '.[] | .family as $family | .transactions[] | [$family, .time, .amount, .amountUSD] | @csv' "$1" | tr -d '"' |
        awk -F ',' 'BEGIN {
                        printf "0.Family,Month,Count,Sum (BTC),Sum (USD)\n";
                    }
                    {
                        # More on 2d arrays: https://www.gnu.org/software/gawk/manual/html_node/Multidimensional.html
                        # Example input: "Conti",1576703591,3000096760,218311.1230543254
                        $2 = strftime("%Y-%m", $2);  # Convert the date
                        count[$1,$2] += 1;
                        sum_btc[$1,$2] += $3 / '"$BITCOIN_FACTOR"';
                        sum_usd[$1,$2] += $4;
                    }
                    END {
                        fmt_str =  "%s,%s,%d,%f,%f\n";

                        for (combined in count) {
                            split(combined, separate, SUBSEP);
                            family = separate[1];
                            time_period = separate[2];
                            count_family = count[family,time_period];
                            sum_btc_family = sum_btc[family,time_period];
                            sum_usd_family = sum_usd[family,time_period];
                            printf fmt_str, family, time_period, count_family, sum_btc_family, sum_usd_family;
                        }
                    }
                    ' |
                    tr ' ' '$' |
                    sort -t ',' -k 2,2 -g |
                    sort -t ',' -k 1,1 -s
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

timeline_families_george=$(compute_timeline_families "$george_data" | sed 's/,/|/' | sort -t, -k1,1)  # Combine family and date
timeline_families_full=$(compute_timeline_families "$full_data" | sed 's/,/|/' | sort -t, -k1,1)      # Used as join field

# Join command has two requirements:
#   1. We can join only by a single field.
#   2. Both files must be sorted by key column!
# Xorist|2017-05,1,0.102283,225.269280,1,0.102283,229.878399
joined_families=$(join -j 1 -t',' -a 1 -a 2 -e '-' -o2.1,1.2,1.3,1.4,2.2,2.3,2.4 <(echo -e "$timeline_families_george") <(echo -e "$timeline_families_full"))
# Apply filtering (if needed)
joined_families=$(echo -e "$joined_families" | awk -F',' '$2 != $5 { print $0; }')
# Pretty print
joined_families=$(echo -e "$joined_families" | tr ',' '\t' | tr '|' '\t' | tr '$' ' ' | sed 's/0.Family/Family/' | column -t -s $'\t')
print_result "$joined_families"

