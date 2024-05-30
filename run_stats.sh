#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

umask 077


BITCOIN_FACTOR=100000000

function usage() {
    echo "Usage: $0 data.json"
}

function print_title() {
    echo -ne "\e[1;91m"
    echo -n "$1"
    echo -e "\e[0m"
}

function print_result() {
    echo -ne "\e[1;96m"
    echo -ne "$1"
    echo -e "\e[0m"
}

function print_misc() {
    echo -ne "\e[1;93m"
    echo -ne "$1"
    echo -e "\e[0m"
}

function print_general_stats() {
    # Expects the full JSON file (data.json)
    print_title "Total number of transactions"
    print_result $(jq '.[].transactions | length' "$1" | paste -d '+' -s | bc)

    print_title "Total payment sum (BTC)"
    print_result $(jq '.[].transactions.[].amount' "$1" | paste -d '+' -s | bc | awk '{ printf "%f", $1 / '"$BITCOIN_FACTOR"'; }')

    print_title "Total payment sum (USD)"
    print_result $(jq '.[].transactions.[].amountUSD' "$1" | paste -d '+' -s | bc | awk '{ printf "%f", $1; }')

    print_title "Time range of transactions"
    transactions=$(jq '.[].transactions.[].time' "$1" |
                    awk '{ $1 = strftime("%Y-%m-%d %H:%M:%S", $1); print $0; }' | sort |
                    awk 'NR == 1 { print "First transaction: " $0; }; END { print "Last transaction: " $0; }')
    print_result "$transactions"

    address_entries=$(jq -r '.[] | { address: .address, family: .family, createdAt: .createdAt, updatedAt: .updatedAt, trans: .transactions | length } | [ .address, .family, .createdAt, .updatedAt, .trans ] | @csv' "$1" | tr -d '"')
    transactions=$(echo -e "$address_entries" | awk -F, '$NF != 0 { print $0 }')
    no_transactions=$(echo -e "$address_entries" | awk -F, '$NF == 0 { print $0 }')

    total_addresses=$(echo -e "$address_entries" | cut -d, -f1 | sort -u | wc -l)
    empty_addresses=$(echo -e "$no_transactions" | cut -d, -f1 | sort -u | wc -l)

    total_families=$(echo -e "$address_entries" | cut -d, -f2 | sort -u)
    non_empty_families=$(echo -e "$transactions" | cut -d, -f2 | sort -u)
    families_with_empty_addresses=$(echo -e "$no_transactions" | cut -d, -f2 | sort -u)
    stats_families_with_empty_addresses=$(echo -e "$no_transactions" | cut -d, -f2 | sort | uniq -c | sort -rn | awk '{ print $2 ": " $1; }')
    stats_families_with_empty_addresses_one_line=$(echo -e "$stats_families_with_empty_addresses" | awk 'NR == 1 { printf("%s", $0); count++; } NR > 1 { printf(", %s", $0); count++; } END { printf(" (%d families in total)\n", count); }')
    empty_families=$(comm -13 <(echo -e "$non_empty_families") <(echo -e "$families_with_empty_addresses"))

    print_title "Total number of families"
    print_result $(echo -e "$total_families" | wc -l)
    print_title "Total number of non-empty families"
    print_result $(echo -e "$non_empty_families" | wc -l)
    print_title "Total number of empty families"
    print_result $(echo -e "$empty_families" | wc -l)

    print_title "Total number of addresses"
    print_result "$total_addresses"
    print_title "Number of empty addresses"
    print_result "$empty_addresses"
    print_misc "$stats_families_with_empty_addresses_one_line"
}

function compute_timeline_years() {
    # Expects the full JSON file (data.json)
    jq -r '.[] | .transactions.[] | [ .time, .amount, .amountUSD ] | @csv' "$1" |
        awk -F',' '
            BEGIN {
                printf "Year,Count,Sum (BTC),Sum (USD),Average (BTC),Average (USD)\n";
            }
            {
                $1 = strftime("%Y", $1);
                count[$1] += 1;
                sum_btc[$1] += $2 / '"$BITCOIN_FACTOR"';
                sum_usd[$1] += $3;
            }
            END {
                for (year in count) {
                    avg_btc = sum_btc[year] / count[year];
                    avg_usd = sum_usd[year] / count[year];
                    fmt_str = "%s,%d,%f,%f,%f,%f\n";
                    printf fmt_str, year, count[year], sum_btc[year], sum_usd[year], avg_btc, avg_usd;
                }
            }' |
            sort -t ',' -k 1,1 -g
}

function print_timeline_years() {
    # Expects the output of the compute_timeline_years function
    print_title "Timeline of transactions (years)"
    timeline_years_pretty=$(echo -e "$1" | tr ',' '\t' | column -t -s $'\t')
    print_result "$timeline_years_pretty"
}

function compute_timeline_months() {
    # Expects the full JSON file (data.json)
    jq -r '.[] | .transactions.[] | [ .time, .amount, .amountUSD ] | @csv' "$1" |
        awk -F',' '
            BEGIN {
                printf "Month,Count,Sum (BTC),Sum (USD),Average (BTC),Average (USD)\n";
            }
            {
                $1 = strftime("%Y-%m", $1);
                count[$1] += 1;
                sum_btc[$1] += $2 / '"$BITCOIN_FACTOR"';
                sum_usd[$1] += $3;
            } END {
                for (time_period in count) {
                    avg_btc = sum_btc[time_period] / count[time_period];
                    avg_usd = sum_usd[time_period] / count[time_period];
                    fmt_str =  "%s,%d,%f,%f,%f,%f\n";
                    printf fmt_str, time_period, count[time_period], sum_btc[time_period], sum_usd[time_period], avg_btc, avg_usd;
                }}' |
                sort -t ',' -k 1,1 -g
}

function print_timeline_months() {
    # Expects the output of the compute_timeline_months function
    print_title "Timeline of transactions (months)"
    timeline_months_pretty=$(echo -e "$1" | tr ',' '\t' | column -t -s $'\t')
    print_misc "$timeline_months_pretty"
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
                    sort -t ',' -k 2,2 -g |
                    sort -t ',' -k 1,1 -s |
                    sed 's/0.Family/Family/'
}

function print_timeline_families() {
    # Expects the output of the compute_timeline_families function
    print_title "Timeline of transactions per families"
    timeline_families_pretty=$(echo -e "$1" | tr ',' '\t' | column -t -s $'\t')
    print_misc "$timeline_families_pretty"
}

# Check if exactly one argument has been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
# To download the file: curl -sL "https://api.ransomwhe.re/export" | jq --indent 0 '.result' > data.json

# Transaction timestamps are in UTC
export TZ="UTC"

ransomwhere="$1"

echo -e "\e[1;92mWelcome to $0! How about this? \e[0m"

# Print general statistics: total number of addresses, total number of transactions, total payment sum (BTC and USD) etc.
print_general_stats "$ransomwhere"

# Print the payment timeline per year
timeline_years=$(compute_timeline_years "$ransomwhere")
print_timeline_years "$timeline_years"
# echo -e "$timeline_years" >| timeline_years.csv

# Print the payment timeline per month
timeline_months=$(compute_timeline_months "$ransomwhere")
print_timeline_months "$timeline_months"
# echo -e "$timeline_months" >| timeline_months.csv

# Print the timeline of ransomware families per month
timeline_families=$(compute_timeline_families "$ransomwhere")
print_timeline_families "$timeline_families"
# echo -e "$timeline_families" >| timeline_families.csv

echo -e "\e[1;95mThis script has been sponsored by Smaragdakis et al.!\e[0m"
echo -e "\e[1;95mHave a nice day!\e[0m"
