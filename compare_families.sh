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
    jq -r '.[] | .family as $family | .address as $address | .transactions[] | [$family, .time, $address, .amount, .amountUSD] | @csv' "$1" | tr -d '"' |
        tr ' ' '$' |      # Temporarily replace whitespaces in the family name with a dollar (for better sorting)
        sort -t, -k1,2 |  # Sorting is very important here for the addresses
        awk -F ',' 'BEGIN {
                        printf "0.Family,Month,Count,Sum (BTC),Sum (USD),Used Addresses,Known Addresses\n";
                    }
                    {
                        # More on 2d arrays: https://www.gnu.org/software/gawk/manual/html_node/Multidimensional.html
                        # Format:    Family, Timestamp,                           Address   BTC,               USD
                        # Example: WannaCry,1632310212,12t9YDPgwueZ9NyMgw519p7AA8isjr6SMw,26346,11.480139828412979
                        $2 = strftime("%Y-%m", $2);  # Convert the date
                        count[$1,$2] += 1;
                        sum_btc[$1,$2] += $4 / '"$BITCOIN_FACTOR"';
                        sum_usd[$1,$2] += $5;

                        # Check if we have already seen this ransomware family with this address
                        # `seen_addresses` is only used for the check, `known_addresses_total` is a global count so far (including previous time periods)
                        if (!seen_addresses[$1,$3]++) {
                            known_addresses_total[$1] += 1;
                        }
                        known_addresses[$1,$2] = known_addresses_total[$1];

                        # Check if we have already seen this ransomware family with this address during this time period
                        if (!seen_addresses_time_period[$1,$2,$3]++) {
                            used_addresses_time_period[$1,$2] += 1;
                        }

                    }
                    END {
                        fmt_str =  "%s,%s,%d,%f,%f,%d,%d\n";

                        for (combined in count) {
                            split(combined, separate, SUBSEP);
                            family = separate[1];
                            time_period = separate[2];
                            count_family = count[family,time_period];
                            sum_btc_family = sum_btc[family,time_period];
                            sum_usd_family = sum_usd[family,time_period];
                            used_addresses_family = used_addresses_time_period[family,time_period];
                            known_addresses_family = known_addresses[family,time_period];
                            printf fmt_str, family, time_period, count_family, sum_btc_family, sum_usd_family, used_addresses_family, known_addresses_family;
                        }
                    }
                    ' |
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

# For consistent sorting of the families (i.e. without ignoring whitespaces)
# See: https://stackoverflow.com/questions/6923464/unix-sort-ignores-whitespaces
# export LC_ALL=C

timeline_families_george=$(compute_timeline_families "$george_data" | sed 's/,/|/' | sort -t, -k1,1)  # Combine family and date (replace only the first comma)
timeline_families_full=$(compute_timeline_families "$full_data" | sed 's/,/|/' | sort -t, -k1,1)      # Used as join field

# We can join only by a single field and both files must be sorted by key column (see https://stackoverflow.com/questions/2619562/joining-multiple-fields-in-text-files-on-unix)
# Example input format: Xorist|2017-09,1,0.024044,101.677080,1,3
joined_families=$(join -j 1 -t',' -a 1 -a 2 -e '-' -o2.1,1.2,1.3,1.4,1.5,1.6,2.2,2.3,2.4,2.5,2.6 <(echo -e "$timeline_families_george") <(echo -e "$timeline_families_full"))

# Remove replaced characters
joined_families=$(echo -e "$joined_families" | tr '|' ',' | tr '$' ' ' | sed 's/0.Family/Family/')

# Apply filtering (if needed)
# Example format: Conti,2017-12,1,0.166500,1934.206357,1,1,1,0.166500,1940.923832,1,1
# joined_families=$(echo -e "$joined_families" | awk -F',' '$3 != $8 { print $0; }')

# Write into a csv file
# echo -e "$joined_families" > families_comparison.csv

# Pretty print
joined_families=$(echo -e "$joined_families" | tr ' ' '_' | tr ',' '\t'  | column -t -s $'\t')

# Separate ransomware families
joined_families=$(echo -e "$joined_families" | awk 'BEGIN { previous_family = "!placeholder!"; }; NR == 1 { len = length($0); }; $1 != previous_family { for (i = 0; i < len; i++) { printf "-"; } printf "\n"; previous_family = $1; }; { print $0; } END { for (i = 0; i < len; i++) { printf "-"; } printf "\n"; }' | tr '_' ' ' )
print_result "$joined_families"
