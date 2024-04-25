#!/usr/bin/env python

import datetime
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt


if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} timeline_years.txt")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y"
years, count, amount_btc, amount_usd = [], [], [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:
        parts = line.split("\t")
        years.append(datetime.datetime.strptime(parts[0], dateformat))
        count.append(int(parts[1]))
        amount_btc.append(float(parts[2]))
        amount_usd.append(float(parts[3]) / 1000000)


fig, (ax1, ax2, ax3) = plt.subplots(3)
fig.suptitle("Timeline of ransom transactions per year")

ax1.plot(years, count, color='blue')
ax1.set_title("Number of transactions")
ax1.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax1.xaxis.set_major_locator(md.YearLocator())
ax1.yaxis.set_major_formatter(formatter)
ax1.grid()

ax2.plot(years, amount_btc, color='green')
ax2.set_title("Payment sum (in BTC)")
ax2.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax2.xaxis.set_major_locator(md.YearLocator())
ax2.yaxis.set_major_formatter(formatter)
ax2.grid()

ax3.plot(years, amount_usd, color='red')
ax3.set_title("Payment sum (in million USD)")
ax3.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax3.xaxis.set_major_locator(md.YearLocator())
ax3.yaxis.set_major_formatter(formatter)
ax3.grid()

plt.gcf().set_size_inches(20, 10, forward=True)
plt.tight_layout()

# plt.savefig("timeline_years.png")
plt.show()
