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
if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} bitcoin_market_price.csv")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
months, prices = [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines():  #[1:]:
        parts = line.split(file_separator)
        months.append(datetime.datetime.strptime(parts[0], dateformat))
        prices.append(float(parts[1]))

fig = plt.figure()
ax = fig.add_subplot(111)

ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax.xaxis.set_major_locator(md.MonthLocator(interval=3))
ax.yaxis.set_major_formatter(formatter)
ax.tick_params(labelrotation=25)

step = 2500
ymax = int(round(max(prices), -4))  # round to the nearest 10000
plt.yticks(range(0, ymax + 1, step))
plt.ylim(0, ymax)
plt.ylabel("USD")

plt.xlim(months[0], months[-1])
first_month = months[0].strftime("%B %Y")
last_month = months[-1].strftime("%B %Y")
plt.title(f"Bitcoin market price in the period from {first_month} and {last_month}")


# Add value labels
epsilon = 100
for i in range(1, len(prices) - 1):
    if prices[i] > (prices[i-1] + epsilon) and prices[i] > (prices[i+1] + epsilon):
        plt.text(months[i], prices[i], prices[i])
plt.text(months[-1], prices[-1], prices[-1])


plt.plot(months, prices, color='blue')
plt.gcf().set_size_inches(20, 10, forward=True)
plt.grid()
plt.tight_layout()

plt.show()
