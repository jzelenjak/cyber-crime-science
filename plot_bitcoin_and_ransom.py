#!/usr/bin/env python

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
    print(f"Usage: {sys.argv[0]} bitcoin_market_price.csv timeline_months.csv")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
btc_months, prices = [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines():  #[1:]:
        parts = line.split(file_separator)
        btc_months.append(datetime.datetime.strptime(parts[0], dateformat))
        prices.append(float(parts[1]))

ransom_months, avg_ransoms = [], []
with open(sys.argv[2], "r") as file:
    for line in file.readlines()[1:]:  # Skip the header
        # Expected format:
        # Month,Count,Sum (BTC),Sum (USD),Average (BTC),Average (USD)
        # 2012-03,1,0.004076,0.000000,0.004076,0.000000
        parts = line.split(file_separator)
        # Skip zeros, so that logarithm is not negative
        if float(parts[-1]) != 0.0:
            ransom_months.append(datetime.datetime.strptime(parts[0], dateformat))
            avg_ransoms.append(float(parts[-1]))

fig = plt.figure()
ax = fig.add_subplot(111)

ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax.xaxis.set_major_locator(md.MonthLocator(interval=3))
ax.yaxis.set_major_formatter(formatter)
ax.tick_params(labelrotation=25, labelsize=13)

first_month, last_month = btc_months[0], btc_months[-1]
# first_month, last_month = ransom_months[0], ransom_months[-1]
plt.xlim(first_month, last_month)
first_month_str = first_month.strftime("%B %Y")
last_month_str = last_month.strftime("%B %Y")
plt.title(f"Bitcoin average montly market price vs average monthly ransom size in the period from {first_month_str} and {last_month_str}", fontsize=15)
plt.yscale("log")


plt.plot(btc_months, prices, color='blue', label="Bitcoin market price", marker='o')
plt.plot(ransom_months, avg_ransoms, color='red', label="Average monthly ransom", marker='o')
plt.gcf().set_size_inches(20, 10, forward=True)
plt.grid()
plt.legend(fontsize=13)
plt.tight_layout()

plt.show()
