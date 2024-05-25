#!/usr/bin/env python

import datetime
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt

# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} timeline_months.csv")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
scale = "linear"
months, count, amount_btc, amount_usd = [], [], [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:
        parts = line.split(file_separator)
        months.append(datetime.datetime.strptime(parts[0], dateformat))
        count.append(int(parts[1]))
        amount_btc.append(round(float(parts[2]), 2))
        amount_usd.append(round(float(parts[3]) / 1000000, 2))


fig, axes = plt.subplots(3)

titles = ["Number of transactions", "Payment sum (in BTC)", "Payment sum (in million USD)"]
stats = [count, amount_btc, amount_usd]
colours = ["blue", "green", "red"]
epsilons = [75, 250, 1.5]

for i in range(len(stats)):
    ax = axes[i]
    y_values = stats[i]

    ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
    ax.xaxis.set_major_locator(md.MonthLocator(interval=3))
    ax.set_xlim(months[0], months[-1])

    ax.yaxis.set_major_formatter(formatter)
    ax.tick_params(axis='y', labelrotation=25)
    ax.set_yscale(scale)

    # Add value labels
    epsilon = epsilons[i]
    for j in range(1, len(y_values) - 1):
        if y_values[j] > (y_values[j-1] + epsilon) and y_values[j] > (y_values[j+1] + epsilon):
            ax.text(months[j], y_values[j], y_values[j], ha="center", va="bottom", fontfamily="monospace", fontsize=11)
    ax.text(months[0], y_values[0], y_values[0], ha="left", va="bottom", fontfamily="monospace", fontsize=11)
    ax.text(months[-1], y_values[-1], y_values[-1], ha="right", va="bottom", fontfamily="monospace", fontsize=11)

    ax.plot(months, y_values, color=colours[i], marker='o')
    ax.set_title(titles[i])
    ax.grid()


first_month = months[0].strftime("%B %Y")
last_month = months[-1].strftime("%B %Y")
fig.suptitle(f"Timeline of ransom transactions per month in the period from {first_month} until {last_month}")

fig.autofmt_xdate(rotation=25)
plt.gcf().set_size_inches(20, 10, forward=True)
plt.tight_layout()

# plt.savefig("timeline_months.png")
plt.show()
