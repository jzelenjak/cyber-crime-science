#!/usr/bin/env python

import datetime
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt


# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} <timeline_months.csv|timeline_years.csv>")
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

scale = "linear"
months, avg_btc, avg_usd = [], [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:
        # Month,Count,Sum (BTC),Sum (USD),Average (BTC),Average (USD)
        # 2012-03,1,0.004076,0.000000,0.004076,0.000000
        parts = line.split(file_separator)
        months.append(datetime.datetime.strptime(parts[0], date_format))
        avg_btc.append(round(float(parts[4]), 2))
        avg_usd.append(round(float(parts[5]) / 1000000, 2))  # Convert into million USD


fig, axes = plt.subplots(2)

ymax_usd = round(max(avg_usd))
ymax_btc = ymax_usd * 100


stats = [avg_btc, avg_usd]
titles = ["BTC", "USD (in millions)"]
ymax = [ymax_btc, ymax_usd]
colours = ["green", "red"]
epsilons = [10, 0.15]


for i in range(2):
    ax = axes[i]
    y_values = stats[i]

    ax.xaxis.set_major_formatter(md.DateFormatter(date_format))
    ax.xaxis.set_major_locator(date_locator)
    ax.set_xlim(months[0], months[-1])

    ax.yaxis.set_major_formatter(formatter)
    ax.tick_params(axis='y', labelrotation=25)
    ax.set_ylim(0, ymax[i])
    ax.set_yscale(scale)

    # Add value labels
    epsilon = epsilons[i]
    for j in range(1, len(y_values) - 1):
        if y_values[j] > (y_values[j-1] + epsilon) and y_values[j] > (y_values[j+1] + epsilon):
            ax.text(months[j], y_values[j], y_values[j], ha="center", va="bottom", fontfamily="monospace", fontsize=15)
    ax.text(months[0], y_values[0], y_values[0], ha="left", va="bottom", fontfamily="monospace", fontsize=15)
    ax.text(months[-1], y_values[-1], y_values[-1], ha="right", va="bottom", fontfamily="monospace", fontsize=15)

    # Increase font (credits to https://stackoverflow.com/questions/3899980/how-to-change-the-font-size-on-a-matplotlib-plot)
    #for item in [ax.title, ax.xaxis.label, ax.yaxis.label]:
    #    item.set_fontsize(17)
    for item in (ax.get_xticklabels() + ax.get_yticklabels()):
        item.set_fontsize(12)

    ax.plot(months, y_values, color=colours[i], marker='o')
    ax.set_title(titles[i], fontsize=15)
    ax.grid()


first_month = months[0].strftime("%B %Y")
last_month = months[-1].strftime("%B %Y")
fig.suptitle(f"Timeline of the average ransom size per {time_period} in the period from {first_month} until {last_month}", fontsize=15)

fig.autofmt_xdate(rotation=45)
plt.gcf().set_size_inches(20, 10, forward=True)
#plt.rcParams.update({'font.size': 22})
plt.tight_layout()

#plt.savefig(f"timeline_avg_ransom_{time_period}s.pdf")
plt.show()
