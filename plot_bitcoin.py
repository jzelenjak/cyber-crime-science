#!/usr/bin/env python
#
# This script plots the average monthly Bitcoin market price based on the file data/bitcoin_market_price.csv.


import datetime
import math
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt
import numpy as np


# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 2:
    print(f"Usage: python {sys.argv[0]} data/bitcoin_market_price.csv")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
datelocator = md.MonthLocator(interval=3)
months, prices = [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines():
        parts = line.split(file_separator)
        months.append(datetime.datetime.strptime(parts[0], dateformat))
        prices.append(float(parts[1]))

fig = plt.figure()
ax = fig.add_subplot(111)

ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax.xaxis.set_major_locator(datelocator)
ax.yaxis.set_major_formatter(formatter)
# Credits to: https://stackoverflow.com/questions/46735745/how-to-control-scientific-notation-in-matplotlib
ax.get_yaxis().set_major_formatter(mt.FuncFormatter(lambda x, p: format(int(x), ',')))
ax.tick_params(labelrotation=25, labelsize=14)

step = 2500
ymax = int(round(max(prices), -4))  # round to the nearest 10000
plt.yticks(range(0, ymax + 1, step), fontsize=14)
plt.ylim(0, ymax)

plt.xlim(months[0], months[-1])
first_month = months[0].strftime("%B %Y")
last_month = months[-1].strftime("%B %Y")
plt.title(f"Average monthly Bitcoin market price in USD in the period from {first_month} and {last_month}", fontsize=20)

# Add value labels for peaks
epsilon = 100
for i in range(1, len(prices) - 1):
    if prices[i] > (prices[i-1] + epsilon) and prices[i] > (prices[i+1] + epsilon):
        plt.text(months[i], prices[i], prices[i], ha="center", va="bottom", fontfamily="monospace", fontsize=15)
plt.text(months[0], prices[0], prices[0], ha="left", va="bottom", fontfamily="monospace", fontsize=15)
plt.text(months[-1], prices[-1], prices[-1], ha="right", va="bottom", fontfamily="monospace", fontsize=15)

plt.plot(months, prices, color='blue')
plt.gcf().set_size_inches(22, 11, forward=True)
plt.grid()
plt.tight_layout()

#plt.savefig("bitcoin_market_price.png")
plt.show()
