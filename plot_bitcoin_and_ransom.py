#!/usr/bin/env python
#
# This script plots the average monthly Bitcoin market price and the average monthly ransom size based on the files data/bitcoin_market_price.csv and timeline_months.csv.
# In order to get the file timeline_months.csv, run the script run_stats.sh.
# The timeline plot is in logarithmic scale.


import datetime
import math
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt
import numpy as np


# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 3:
    print(f"Usage: python {sys.argv[0]} data/bitcoin_market_price.csv timeline_months.csv\n\n       Run run_stats.sh to get timeline_families.csv file")
    exit(1)

formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
datelocator = md.MonthLocator(interval=3)

btc_months, prices = [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:  # Skip the header
        parts = line.split(file_separator)
        btc_months.append(datetime.datetime.strptime(parts[0], dateformat))
        prices.append(float(parts[1]))


ransom_months, avg_ransoms = [], []
curr_btc_month = 0
with open(sys.argv[2], "r") as file:
    for line in file.readlines()[1:]:  # Skip the header
        # Expected format:
        # Month,Count,Sum (BTC),Sum (USD),Average (BTC),Average (USD)
        # 2012-03,1,0.004076,0.000000,0.004076,0.000000
        parts = line.split(file_separator)
        month = datetime.datetime.strptime(parts[0], dateformat)
        avg_ransom = float(parts[-1])
        # Add missing months (some sort of extrapolation)
        while month != btc_months[curr_btc_month]:
            print("No ransoms in", btc_months[curr_btc_month].strftime("%B %Y"))
            prev_month_ransom = avg_ransoms[-1] if len(avg_ransoms) != 0 else 0
            ransom_months.append(btc_months[curr_btc_month])
            avg_ransoms.append(prev_month_ransom)
            curr_btc_month += 1
        ransom_months.append(month)
        avg_ransoms.append(avg_ransom)
        curr_btc_month += 1


fig = plt.figure()
ax = fig.add_subplot(111)

ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax.xaxis.set_major_locator(datelocator)
ax.yaxis.set_major_formatter(formatter)
ax.tick_params(labelrotation=25, labelsize=14)
plt.yscale("log")

first_month, last_month = btc_months[0], btc_months[-1]
plt.xlim(first_month, last_month)
first_month_str = first_month.strftime("%B %Y")
last_month_str = last_month.strftime("%B %Y")
plt.title(f"Bitcoin average montly market price vs average monthly ransom size in the period from {first_month_str} and {last_month_str}", fontsize=20)

plt.plot(btc_months, prices, color='blue', label="Bitcoin market price", marker='o')
plt.plot(ransom_months, avg_ransoms, color='red', label="Average monthly ransom", marker='o')
plt.gcf().set_size_inches(22, 11, forward=True)
plt.grid()
plt.legend(fontsize=15)
plt.tight_layout()

#plt.savefig("bitcoin_vs_average_ransom.png")
plt.show()
