#!/bin/bash
#
# This script is used to compare the monthly timeline of ransomware families in the current up-to-date version of the Ransomwhere dataset and in the version used by George and Kris (https://dl.acm.org/doi/10.1145/3582489).
#   The current version of the dataset can be downloaded on https://api.ransomwhe.re/export (e.g. curl -sL "https://api.ransomwhe.re/export" | jq --indent 0 '.result' > data.json).
#   George's dataset is available here: https://zenodo.org/records/6512123.
# This script could also be used to compare the monthly timeline of ransomware families in two versions of the Ransomwhere dataset (not necessarily the ones mentioned above).
#
# The computed statistics for each ransomware family in one month in the monthly timeline include:
# - The number of transactions in that month
# - The payment sum in BTC in that month
# - The payment sum in USD in that month
# - The number of (unique) used addresses in that month
# - The number of (unique) known addresses so far (sort of a cumulative sum)
# Furthermore, for each family the totals for the corresponding statistics are also computed.
#   Note: for totals the used addresses are equal to the known addresses (we know all addresses the family has used).
# See below in the script for commented out lines regarding applying filtering to keep only the lines with the changed number of transactions, removing totals and saving the output to a csv file.


set -euo pipefail
IFS=$'\n\t'

umask 077

# The Bitcoin amounts in Ransomwhere dataset are in Satoshi
BITCOIN_FACTOR=100000000

function usage() {
    echo -e "Usage: $0 george_data.json full_data.json\n"
    echo -e "\tgeorge_data.json - the dataset version used by George and Kris (available on: https://zenodo.org/records/6512123)"
    echo -e "\tfull_data.json - the current up-to-date version of the dataset (available on: https://api.ransomwhe.re/export)"
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
        sort -t, -k1,1 -k2,2 |  # Sorting is very important here for the dates and families
        awk -F, -v bitcoin_factor="$BITCOIN_FACTOR" '
            BEGIN {
                printf("0.Family,Month,Count,Sum (BTC),Sum (USD),Used Addresses,Known Addresses\n");
            }
            {
                # More on 2d arrays: https://www.gnu.org/software/gawk/manual/html_node/Multidimensional.html
                # Format:    Family, Timestamp,                           Address   BTC,               USD
                # Example: WannaCry,1632310212,12t9YDPgwueZ9NyMgw519p7AA8isjr6SMw,26346,11.480139828412979
                $2 = strftime("%Y-%m", $2);  # Convert the date
                count[$1,$2] += 1;
                btc = $4 / bitcoin_factor;
                usd = $5;
                sum_btc[$1,$2] += btc;
                sum_usd[$1,$2] += usd;
                total_count[$1] += 1;
                total_sum_btc[$1] += btc;
                total_sum_usd[$1] += usd;
                last_month[$1] = $2;

                # Check if we have already seen this ransomware family with this address
                # `seen_addresses` is only used for the check, `known_addresses_total` is a global count so far (including previous months)
                if (!seen_addresses[$1,$3]++) {
                    known_addresses_total[$1] += 1;
                }
                known_addresses[$1,$2] = known_addresses_total[$1];

                # Check if we have already seen this ransomware family with this address during this month
                if (!seen_addresses_month[$1,$2,$3]++) {
                    used_addresses_month[$1,$2] += 1;
                }

            }
            END {
                fmt_str = "%s,%s,%d,%f,%.2f,%d,%d\n";

                for (combined in count) {
                    split(combined, separate, SUBSEP);

                    family = separate[1];
                    month = separate[2];
                    count_family = count[family,month];
                    sum_btc_family = sum_btc[family,month];
                    sum_usd_family = sum_usd[family,month];
                    used_addresses_family = used_addresses_month[family,month];
                    known_addresses_family = known_addresses[family,month];

                    printf(fmt_str, family, month, count_family, sum_btc_family, sum_usd_family, used_addresses_family, known_addresses_family);

                    # Print the total values
                    if (month == last_month[family]) {
                        # Here total used addresses and total known addresses are the same (we know all addresses they have used)
                        printf(fmt_str, family, "Total", total_count[family], total_sum_btc[family], total_sum_usd[family], known_addresses_family, known_addresses_family);
                    }
                }
            }' |
            sort -t, -k1,1 -k2,2
}


# Check if exactly two arguments have been provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Check if the provided files exist
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
[[ -f "$2" ]] || { echo "File $2 does not exist." >&2 ; exit 1; }

# Transaction timestamps are in UTC
export TZ="UTC"
# For consistent sorting
export LC_ALL=en_US.UTF-8

george_data="$1"
full_data="$2"


timeline_families_george=$(compute_timeline_families "$george_data" | sed 's/,/|/' | sort -t, -k1,1)  # Combine family and date (replace only the first comma)
timeline_families_full=$(compute_timeline_families "$full_data" | sed 's/,/|/' | sort -t, -k1,1)      # The pipes are then used as the join field

# We can join only by a single field and both files must be sorted by key column (see https://stackoverflow.com/questions/2619562/joining-multiple-fields-in-text-files-on-unix)
# Example input format: Xorist|2017-09,1,0.024044,101.677080,1,3
joined_families=$(join -j 1 -t, -a 1 -a 2 -e '-' -o2.1,1.2,1.3,1.4,1.5,1.6,2.2,2.3,2.4,2.5,2.6 <(echo -e "$timeline_families_george") <(echo -e "$timeline_families_full") | tr '|' ',' | sort -t, -k1,1 -k2,2 | sed 's/0.Family/Family/')

# Apply filtering for the rows with the changed number of transactions (if needed)
# Example format: Conti,2017-12,1,0.166500,1934.206357,1,1,1,0.166500,1940.923832,1,1
joined_families=$(echo -e "$joined_families" | awk -F, 'NR == 1 { print $0; }; $3 != $8 { print $0; }')

# Remove "Total" (if needed)
# joined_families=$(echo -e "$joined_families" | awk -F, '$2 != "Total" { print $0; }')

# Write into a csv file
# echo -e "$joined_families" > families_comparison.csv

# Pretty print
joined_families=$(echo -e "$joined_families" | tr ' ' '_' | tr ',' '\t'  | column -t -s $'\t')

# Separate ransomware families
joined_families=$(echo -e "$joined_families" | awk 'BEGIN { previous_family = "!placeholder!"; }; NR == 1 { len = length($0); }; $1 != previous_family { for (i = 0; i < len; i++) { printf("-"); } printf("\n"); previous_family = $1; }; { print $0; } END { for (i = 0; i < len; i++) { printf("-"); } printf("\n"); }' | tr '_' ' ')
print_result "$joined_families"
