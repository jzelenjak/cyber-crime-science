#!/bin/bash
#
# This script is only used to preprocess the table with the US inflation rates and convert it into two csv files:
#   - One file with the rates per month
#   - Another file with the rates per year
# The table with the US inflation rates is taken from: https://www.usinflationcalculator.com/inflation/current-inflation-rates/ (Annual Inflation Rates)
# File us_inflation_rates_table_example.csv is an example that you could use with the last month May 2024.
# If you want a more up-to-date version, you can copy the table from the website, paste it into Excel/LibreOffice and export as csv (e.g. into a file "us_inflation_rates.csv").
# In either case, the input file must be a csv, with the following format (including the header!):
#   Year,Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,Ave
#   2024,3.1,3.2,3.5,3.4,Avail. June 12,,,,,,,,
#   2023,6.4,6.0,5.0,4.9,4.0,3.0,3.2,3.7,3.7,3.2,3.1,3.4,4.1
#   ...
# The output of this script will be written in the files us_yearly_inflation_rates.csv and us_monthly_inflation_rates.csv, respectively.


set -euo pipefail
IFS=$'\n\t'

umask 077


first_year="2012"
last_year="2023"
first_month="2012-03"
last_month="2024-03"

output_file_years="us_yearly_inflation_rates.csv"
output_file_months="us_monthly_inflation_rates.csv"

function usage() {
    echo -e "Usage: $0 us_inflation_rates.csv\n"
    echo -e "\tus_inflation_rates.csv - a csv file with the table taken from Annual Inflation Rates on: "
    echo -e "\t\thttps://www.usinflationcalculator.com/inflation/current-inflation-rates/"
}

function compute_yearly_rates() {
    # Year,Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,Ave
    # 2024,3.1,3.2,3.5,3.4,Avail. June 12,,,,,,,,
    # 2023,6.4,6.0,5.0,4.9,4.0,3.0,3.2,3.7,3.7,3.2,3.1,3.4,4.1
    awk -F, 'NR > 1 && $NF != " " { print $1 "," $NF; }' "$1" |
        sort -t, -k 1,1 |  # Sort chronologically
        awk -F, -v start="$first_year" -v end="$last_year" '$1 >= start && $1 <= end { print $0; }' |  # Apply filtering
        awk -F, 'BEGIN { print "Year,Rate"; } { print $0; }' > "$2"  # Add a header
}

function compute_monthly_rates() {
    # Year,Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,Ave
    # 2024,3.1,3.2,3.5,3.4,Avail. June 12,,,,,,,,
    # 2023,6.4,6.0,5.0,4.9,4.0,3.0,3.2,3.7,3.7,3.2,3.1,3.4,4.1
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
        awk -F, -v start="$first_month" -v end="$last_month" '$1 >= start && $1 <= end { print $0; }' |  # Apply filtering
        awk -F, 'BEGIN { print "Month,Rate"; } { print $0; }' > "$2"  # Add a header
}


# Check if exactly one argument has been provided
[[ $# -ne 1 ]] && { usage >&2 ; exit 1; }

# Check if the provided file exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }

compute_yearly_rates "$1" "$output_file_years"
compute_monthly_rates "$1" "$output_file_months"
