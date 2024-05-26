#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

umask 077


first_month_filter="2014-09"
last_month_filter="2024-03"

function usage() {
    echo "Usage: $0 market-price.json data.json"
}

function compute_bitcoin_average_monthly_price() {
    # The time is represented by milliseconds, so we have to divide by 1000
    jq -r '."market-price".[] | [ .x, .y ] | @csv' "$1" |
        awk -F, '{ $1 = strftime("%Y-%m", $1 / 1000); printf("%s,%.2f\n", $1, $2); }' |
        awk -F, '
            {
                sum[$1] += $2;
                count[$1] += 1;
            }
            END {
                for (month in count) {
                    avg_month_price = sum[month] / count[month];
                    avg_month_price = int(avg_month_price * 100 + 0.5) / 100;
                    printf("%s,%.2f\n", month, avg_month_price);
                }
            }' |
            sort -t, -k 1,1 |
            awk -F, '$1 >= "'$first_month_filter'" && $1 <= "'$last_month_filter'" { print $0; }'
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
                    avg_usd = int(avg_usd * 100 + 0.5) / 100;
                    printf("%s,%.2f\n", month, avg_usd);
                }
            }' |
            sort -t ',' -k 1,1 |
            awk -F, '$1 >= "'$first_month_filter'" && $1 <= "'$last_month_filter'" { print $0; }'
}

function compute_pearson_coefficient() {
    # Formula taken from: https://en.wikipedia.org/wiki/Pearson_correlation_coefficient
    join -j 1 -t, <(compute_bitcoin_average_monthly_price "$1") <(compute_average_monthly_ransom "$2") |
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

    # Join to only keep the months that are in both series
    joined=$(join -j 1 -t, <(compute_bitcoin_average_monthly_price "$1") <(compute_average_monthly_ransom "$2"))
    # Extract and rank the bitcoin prices
    prices=$(echo -e "$joined" | cut -d, -f1,2)
    ranked_prices=$(echo -e "$prices" | sort -t, -k2,2 -g | awk -F, '{ print $0 "," NR; }' | sort -t, -k1,1)
    # Extract and rank the average ransoms
    ransoms=$(echo -e "$joined" | cut -d, -f1,3)
    ranked_ransoms=$(echo -e "$ransoms" | sort -t, -k2,2 -g | awk -F, '{ print $0 "," NR; }' | sort -t, -k1,1)
    # Join again the ranked series and compute the Spearman correlation coefficient
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
                r_s = 1 - (6 * sum_d2) / ( n * (n * n - 1) );
                printf("Spearman correlation coefficient: r_s = %f\n", r_s);
            }'
}


# Check if exactly two argument have been provided
[[ $# -ne 2 ]] && { usage >&2 ; exit 1; }

# Check if the provided files exists
[[ -f "$1" ]] || { echo "File $1 does not exist." >&2 ; exit 1; }
[[ -f "$2" ]] || { echo "File $2 does not exist." >&2 ; exit 1; }
# To download the file: curl -sL "https://api.ransomwhe.re/export" | jq --indent 0 '.result' > data.json
# To download the file, go to https://www.blockchain.com/explorer/charts/market-price and export the JSON file with the following parameters:
#   "metric1": "market-price", "metric2": "market-price", "type": "linear", "average": "1d", "timespan": "all"

compute_pearson_coefficient "$1" "$2"
compute_spearman_coefficient "$1" "$2"

