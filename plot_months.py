#!/usr/bin/env python

import datetime
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} stuff.txt")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
time, count, amount_btc, amount_usd = [], [], [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:
        parts = line.split("\t")
        time.append(datetime.datetime.strptime(parts[0], dateformat))
        count.append(int(parts[1]))
        amount_btc.append(int(parts[2]) / 1000000000)
        amount_usd.append(float(parts[3]) / 1000000)


fig, (ax1, ax2, ax3) = plt.subplots(3)
fig.suptitle("Timeline of transactions per month")

# Plot transactions per time
ax1.plot(time, count, color='blue')
ax1.set_title("Number of transactions per month")
ax1.xaxis.set_major_formatter(md.DateFormatter('%Y-%m'))
ax1.xaxis.set_major_locator(md.MonthLocator(interval=3))
ax1.yaxis.set_major_formatter(formatter)
ax1.tick_params(labelrotation=25)
ax1.grid()

# Plot payment sum in BTC per time
ax2.plot(time, amount_btc, color='green')
ax2.set_title("Payment sum per month (in billion BTC)")
ax2.xaxis.set_major_formatter(md.DateFormatter('%Y-%m'))
ax2.xaxis.set_major_locator(md.MonthLocator(interval=3))
ax2.yaxis.set_major_formatter(formatter)
ax2.tick_params(labelrotation=25)
ax2.grid()

# Plot payment sum in BTC per time
ax3.plot(time, amount_usd, color='red')
ax3.set_title("Payment sum per month (in million USD)")
ax3.xaxis.set_major_formatter(md.DateFormatter('%Y-%m'))
ax3.xaxis.set_major_locator(md.MonthLocator(interval=3))
ax3.yaxis.set_major_formatter(formatter)
ax3.tick_params(labelrotation=25)
ax3.grid()

plt.gcf().set_size_inches(20, 10, forward=True)
plt.tight_layout()

# plt.savefig("timeline_months.png")
plt.show()
