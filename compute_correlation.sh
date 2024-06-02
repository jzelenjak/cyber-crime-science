#!/bin/bash
#
# This script computes the correlation coefficients (Pearson and Spearman) for the average monthly Bitcoin market price and the average monthly ransom size.
# The average monthly Bitcoin market price is stored in data/bitcoin-market-price.csv (see data/preprocess_bitcoin.sh).
# The average ransoms are computed based on the Ransomwhere dataset (https://api.ransomwhe.re/export).
# To download the file you can run: curl -sL "https://api.ransomwhe.re/export" | jq --indent 0 '.result' > data.json


set -euo pipefail
IFS=$'\n\t'

umask 077


first_month_filter="2012-03"
last_month_filter="2024-03"

function usage() {
    echo -e "Usage: $0 data/bitcoin-market-price.csv data.json\n"
    echo -e "\tdata/bitcoin-market-price.csv - the preprocessed file with the monthly Bitcoin market price (see data/preprocess_bitcoin.sh)"
    echo -e "\tdata.json - the current up-to-date version of the dataset (available on: https://api.ransomwhe.re/export)"
}

function compute_bitcoin_average_monthly_price() {
    # The file is assumed to be already preprocessed (see data/preprocess_bitcoin.sh script for more details), so here we only apply filtering

    awk -F, -v first_month="$first_month_filter" -v last_month="$last_month_filter" '$1 >= first_month && $1 <= last_month { print $0; }' "$1"
}

function compute_average_monthly_ransom() {
    # Expects the full JSON file (data.json)

    jq -r '.[] | .transactions.[] | [ .time, .amountUSD ] | @csv' "$1" |
        awk -F, '
            {
                $1 = strftime("%Y-%m", $1);
                count[$1] += 1;
                sum_usd[$1] += $2;
            } END {
                for (month in count) {
                    avg_usd = sum_usd[month] / count[month];
                    printf("%s,%.2f\n", month, avg_usd);
                }
            }' |
            sort -t ',' -k 1,1 |
            awk -F, '$1 >= "'$first_month_filter'" && $1 <= "'$last_month_filter'" { print $0; }'
}

function compute_pearson_coefficient() {
    # Formula taken from: https://en.wikipedia.org/wiki/Pearson_correlation_coefficient

    # Join to match the months
    joined=$(join -j 1 -t, -a1 -o1.1,1.2,2.2 -e '-1' <(compute_bitcoin_average_monthly_price "$1") <(compute_average_monthly_ransom "$2"))
    # Fill in the missing months for the average ransoms by using the average ransom from the previous month (sort of extrapolation)
    joined=$(echo -e "$joined" | awk -F, 'BEGIN { prev_month_ransom = 0.0; } $3 == "-1" { $3 = prev_month_ransom; } { printf("%s,%f,%f\n", $1, $2, $3); prev_month_ransom = $3; }')
    # Compute the Pearson correlation coefficient
    echo -e "$joined" |
        awk -F, '
            {
                x = $2;
                y = $3
                sum_xy += x * y;
                sum_x += x;
                sum_y += y;
                sum_x2 += x * x;
                sum_y2 += y * y;
                n += 1;
            }
            END {
                x_hat = sum_x / n;
                x_hat2 = x_hat * x_hat;
                y_hat = sum_y / n;
                y_hat2 = y_hat * y_hat;

                r_xy = (sum_xy - n * x_hat * y_hat) / ( sqrt(sum_x2 - n * x_hat2) * sqrt(sum_y2 - n * y_hat2) );
                printf("Pearson correlation coefficient: r_xy = %f\n", r_xy);
            }'

}

function compute_spearman_coefficient() {
    # Formula taken from: https://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient

    # Join to match the months
    joined=$(join -j 1 -t, -a1 -o1.1,1.2,2.2 -e '-1' <(compute_bitcoin_average_monthly_price "$1") <(compute_average_monthly_ransom "$2"))
    # Fill in the missing months for the average ransoms by using the average ransom from the previous month (sort of extrapolation)
    joined=$(echo -e "$joined" | awk -F, 'BEGIN { prev_month_ransom = 0.0; } $3 == "-1" { $3 = prev_month_ransom; } { printf("%s,%f,%f\n", $1, $2, $3); prev_month_ransom = $3; }')
    # Extract and rank the bitcoin prices
    prices=$(echo -e "$joined" | cut -d, -f1,2)
    ranked_prices=$(echo -e "$prices" | sort -t, -k2,2 -g | awk -F, '{ print $0 "," NR; }' | sort -t, -k1,1)
    # Extract and rank the average ransoms
    ransoms=$(echo -e "$joined" | cut -d, -f1,3)
    ranked_ransoms=$(echo -e "$ransoms" | sort -t, -k2,2 -g | awk -F, '{ print $0 "," NR; }' | sort -t, -k1,1)
    # Join the ranked series and compute the Spearman correlation coefficient
    join -j 1 -t, <(echo -e "$ranked_prices") <(echo -e "$ranked_ransoms") |
        awk -F, '
            {
                # Example format: 2021-12,49126.85,100,158297.07,92
                # Find the difference between the two rank columns, square it and add to the sum of d^2
                rank_x = $3;
                rank_y = $5
                d = rank_x - rank_y;
                d2 = d * d;
                sum_d2 += d2;
                n += 1;
            }
            END {
                r_s = 1 - ( (6 * sum_d2) / ( n * (n * n - 1) ) );
                printf("Spearman correlation coefficient: r_s = %f\n", r_s);
            }'
}


# Check if exactly two arguments have been provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Check if the provided files exist
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
[[ -f "$2" ]] || { echo "File $2 does not exist." >&2 ; exit 1; }

# Note that Pearson requires normality, so take the result with a grain of sault...
compute_pearson_coefficient "$1" "$2"
compute_spearman_coefficient "$1" "$2"
