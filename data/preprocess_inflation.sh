#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

umask 077

function usage() {
    echo -e "Usage: $0 inflation.csv\n"
    echo -e "\tinflation.csv is the table taken from Annual Inflation Rates on: "
    echo -e "\thttps://www.usinflationcalculator.com/inflation/current-inflation-rates/"
}


# Check if exactly one argument has been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
# File taken from Table: Annual Inflation Rates on https://www.usinflationcalculator.com/inflation/current-inflation-rates/

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

