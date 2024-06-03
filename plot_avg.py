#!/usr/bin/env python
#
# This script plots the timeline of the average ransom per month, based on the file timeline_month.csv.
# In order to get the file, run the script run_stats.sh.

import datetime
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt


# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 2:
    print(f"Usage: python {sys.argv[0]} timeline_months.csv\n\n       Run run_stats.sh to get timeline_months.csv file")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
datelocator = md.MonthLocator(interval=3)
scale = "linear"
usd_factor = 1000000  # Show USD timeline in million USD

months, avg_btc, avg_usd = [], [], []
with open(sys.argv[1], "r") as file:  # Skip the header
    for line in file.readlines()[1:]:
        # Month,Count,Sum (BTC),Sum (USD),Average (BTC),Average (USD)
        # 2022-04,3,254.291225,9978791.73,84.763742,3326263.91
        parts = line.split(file_separator)
        months.append(datetime.datetime.strptime(parts[0], dateformat))
        avg_btc.append(round(float(parts[4]), 4))
        avg_usd.append(round(float(parts[5]) / usd_factor, 2))


fig, axes = plt.subplots(2)

# Make the scale look better...
ymax_usd = round(max(avg_usd))
ymax_btc = ymax_usd * 100


stats = [avg_btc, avg_usd]
titles = ["BTC", "USD (in millions)"]  # Update the title if you change usd_factor
ymax = [ymax_btc, ymax_usd]
colours = ["green", "red"]
epsilons = [10, 0.15]


for i in range(2):
    ax = axes[i]
    y_values = stats[i]

    ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
    ax.xaxis.set_major_locator(datelocator)
    ax.set_xlim(months[0], months[-1])

    ax.yaxis.set_major_formatter(formatter)
    ax.tick_params(axis='y', labelrotation=25)
    ax.set_ylim(0, ymax[i])
    ax.set_yscale(scale)

    # Add value labels for peaks
    epsilon = epsilons[i]
    for j in range(1, len(y_values) - 1):
        if y_values[j] > (y_values[j-1] + epsilon) and y_values[j] > (y_values[j+1] + epsilon):
            ax.text(months[j], y_values[j], y_values[j], ha="center", va="bottom", fontfamily="monospace", fontsize=17)
    ax.text(months[0], y_values[0], y_values[0], ha="left", va="bottom", fontfamily="monospace", fontsize=17)
    ax.text(months[-1], y_values[-1], y_values[-1], ha="right", va="bottom", fontfamily="monospace", fontsize=17)

    # Increase font (credits to https://stackoverflow.com/questions/3899980/how-to-change-the-font-size-on-a-matplotlib-plot)
    for item in (ax.get_xticklabels() + ax.get_yticklabels()):
        item.set_fontsize(14)

    # Credits to: https://stackoverflow.com/questions/46735745/how-to-control-scientific-notation-in-matplotlib
    ax.get_yaxis().set_major_formatter(mt.FuncFormatter(lambda x, p: format(int(x), ',')))

    ax.plot(months, y_values, color=colours[i], marker='o')
    ax.set_title(titles[i], fontsize=18)
    ax.grid()


first_month = months[0].strftime("%B %Y")
last_month = months[-1].strftime("%B %Y")
fig.suptitle(f"Timeline of the average ransom size per month in the period from {first_month} until {last_month}", fontsize=20)

fig.autofmt_xdate(rotation=25)
plt.gcf().set_size_inches(22, 11, forward=True)
plt.tight_layout()

#plt.savefig("timeline_avg_ransom_month.png")
plt.show()
