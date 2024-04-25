#!/usr/bin/env python

import datetime
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <timeline_months.txt|timeline_years.txt>")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

if "month" in sys.argv[1]:
    date_format = "%Y-%m"
    date_locator = md.MonthLocator(interval=3)
    time_period = "month"
elif "year" in sys.argv[1]:
    date_format = "%Y"
    date_locator = md.YearLocator(base=1)
    time_period = "year"

time, avg_btc, avg_usd = [], [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:
        parts = line.split("\t")
        count = int(parts[1])
        if count == 0:
            continue
        time.append(datetime.datetime.strptime(parts[0], date_format))
        avg_btc.append(float(parts[2]) / count)
        avg_usd.append(float(parts[3]) / count)


fig, (ax1, ax2) = plt.subplots(2)
fig.suptitle(f"Timeline of the average ransom size per {time_period}")

# Plot average ransom size in BTC (per month)
ax1.plot(time, avg_btc, color='green')
ax1.set_title("BTC")
ax1.xaxis.set_major_formatter(md.DateFormatter(date_format))
ax1.xaxis.set_major_locator(date_locator)
ax1.yaxis.set_major_formatter(formatter)
ax1.tick_params(labelrotation=25)
ax1.grid()

# Plot average ransom size in USD (per month)
ax2.plot(time, avg_usd, color='red')
ax2.set_title("USD")
ax2.xaxis.set_major_formatter(md.DateFormatter(date_format))
ax2.xaxis.set_major_locator(date_locator)
ax2.yaxis.set_major_formatter(formatter)
ax2.tick_params(labelrotation=25)
ax2.grid()

plt.gcf().set_size_inches(20, 10, forward=True)
plt.tight_layout()

#plt.savefig(f"timeline_avg_ransom_{time_period}s.png")
plt.show()
