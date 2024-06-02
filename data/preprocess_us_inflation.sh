#!/bin/bash
#
# This script is only used to preprocess the table with the US inflation rates and convert it into a csv file (with the rates per month).
# The table with the US inflation rates is taken from: https://www.usinflationcalculator.com/inflation/current-inflation-rates/ (Annual Inflation Rates)
# You can copy the table from the website, paste it into Excel or LibreOffice and then export as csv (e.g. into a file "us-inflation-rates.csv"). In either case, the input file must be a csv.
# You can redirect the output of this script into a file of your choice, e.g. `./preprocess_us_inflation.sh us-inflation-rates.csv > us-monthly-inflation-rates.csv`


set -euo pipefail
IFS=$'\n\t'

umask 077


function usage() {
    echo -e "Usage: $0 us-inflation-rates.csv\n"
    echo -e "\tus-inflationrates.csv - the table (in a csv file) taken from Annual Inflation Rates on: "
    echo -e "\t\thttps://www.usinflationcalculator.com/inflation/current-inflation-rates/"
}


# Check if exactly one argument has been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }

first_month="2012-03"
last_month="2024-03"

awk -F, '
    NR > 1 {  # Skip the header
        for (i = 2; i < NF; i++) {  # Using the columns Jan to Dec without Ave
            if ($i != " ") {
                month = sprintf("%d-%02d", $1, i - 1);
                inflation[month] = $i;
            }
        }
    }
    END {
        for (month in inflation) {
            printf("%s,%.1f\n", month, inflation[month]);
        }
    }' "$1" |
    sort -t, -k 1,1 |  # Sort chronologically
    awk -F, '$1 >= "'$first_month'" && $1 <= "'$last_month'" { print $0; }'

