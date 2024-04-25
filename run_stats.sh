#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage(){
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

# Check if exactly one argument has been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
# To download the file: curl -sL "https://api.ransomwhe.re/export" | jq --indent 0 '.result' > data.json

ransomwhere="$1"

echo -e "\e[1;92mWelcome to $0! How about this? \e[0m"

print_title "Total number of addresses"
print_result $(jq '.[] | length' "$ransomwhere")

print_title "Total number of transactions"
print_result $(jq '.[].transactions | length' "$ransomwhere" | paste -d '+' -s | bc)

print_title "Total payment sum (BTC)"
print_result $(jq '.[].transactions.[].amount' "$ransomwhere" | paste -d '+' -s | bc)

print_title "Total payment sum (USD)"
print_result $(jq '.[].transactions.[].amountUSD' "$ransomwhere" | paste -d '+' -s | bc | awk '{ printf "%.2f", $1; }')


print_title "Timeline of transactions (months)"
timeline_months=$(jq -r '.[] | .transactions.[] | [ .time, .amount, .amountUSD ] | @csv' "$ransomwhere" | awk -F',' 'BEGIN { printf "Year-Month\tCount\tAmount(BTC)\tAmount(USD)\n"; } { $1=strftime("%Y-%m", $1); count[$1] += 1; amountBTC[$1] += $2; amountUSD[$1] += $3; } END { for (time_period in count) { printf "%s\t%d\t%d\t%.2f\n", time_period, count[time_period], amountBTC[time_period], amountUSD[time_period]; } }' | sort -t '-' -k 2,2 -M | sort -t $'\t' -k 1,1 -s -n)
timeline_months_pretty=$(echo -e "$timeline_months" | column -t -s $'\t')
print_misc "$timeline_months_pretty"
echo -e "$timeline_months" >| timeline_months.txt


print_title "Timeline of transactions (years)"
timeline_years=$(echo -e "$timeline_months" | tr '-' '\t' | awk -F'\t' 'BEGIN { printf "Year\tCount\tAmount(BTC)\tAmount(USD)\n"; }  NR>1 { count[$1] += $3; amountBTC[$1] += $4; amountUSD[$1] += $5; } END { for (year in count) { printf "%s\t%d\t%d\t%.2f\n", year, count[year], amountBTC[year], amountUSD[year]; } }')
timeline_years_pretty=$(echo -e "$timeline_years" | column -t -s $'\t')
print_result "$timeline_years_pretty"
echo -e "$timeline_years" >| timeline_years.txt

# cat data.json | jq -r 'map([ .family, (.transactions | length) ] | @csv) | .[]' | tr -d '"' | awk -F, '{ families[$1] += $2 } END { for (family in families) { print family ":" families[family]; } }' | sort -t: -k2 -rn | awk -F: '{ print $1 ": " $2; }'

# print_title "Number of transactions per year"
# transactions_per_year=$(jq '.[] | .transactions.[].time' "$ransomwhere" | sort -n | sed 's/^\([0-9]*\)$/date +"%Y" -d @\1/' | bash | sort | uniq -c | sort -rn)
# print_misc "$transactions_per_year"

# jq -r '.[] | .transactions.[] | [ .time, .amount ] | @csv' data.json | awk -F',' '{ $1=strftime("%Y", $1); amount[$1] += $2; } END { for (year in amount) { print year "\t" amount[year]; } }'

# print_title "Timeline of transactions"
# timeline=$(jq -r '.[] | .transactions.[] | [ .time, .amount, .amountUSD ] | @csv' "$ransomwhere" | awk -F',' 'BEGIN { printf "Time\tCount\tAmount(BTC)\tAmount(USD)\n"; } { $1=strftime("%Y", $1); count[$1] += 1; amountBTC[$1] += $2; amountUSD[$1] += $3; } END { for (time_period in count) { printf "%d\t%d\t%d\t%.2f\n", time_period, count[time_period], amountBTC[time_period], amountUSD[time_period]; } }')
# timeline_pretty=$(echo -e "$timeline" | column -t -s $'\t')
# print_result "$timeline_pretty"
# echo -e "$timeline" >| timeline.txt
