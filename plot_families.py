#!/usr/bin/env python

import datetime
import sys

import numpy as np
import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt


# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} timeline_families.csv")
    exit(1)


date_format = "%Y-%m"
date_locator = md.MonthLocator(interval=3)
time_period = "month"

num_cols_legend = 5
font_size_legend = "small"

scale = "linear"
families = dict()
with open(sys.argv[1], "r") as file:
    for line in file.readlines()[1:]:  # Skip the header
        # Format: Family,Month,Count,Sum (BTC),Sum (USD)
        # Example: Conti,2017-12,1,0.166500,1940.923832
        parts = line.split(file_separator)
        family = parts[0]
        time = datetime.datetime.strptime(parts[1], date_format)
        count = int(parts[2])
        if count == 0:
            continue
        sum_btc = float(parts[3])
        sum_usd = float(parts[4])

        if not family in families:
            # Example: {"Conti": {"time": [2017-12,...], "count": [1,...], "sum_btc": [0.166500,...], "sum_usd": [1940.923832,...]},...}
            families[family] = dict()
            families[family]["time"] = []
            families[family]["count"] = []
            families[family]["sum_btc"] = []
            families[family]["sum_usd"] = []
        families[family]["time"].append(time)
        families[family]["count"].append(count)
        families[family]["sum_btc"].append(sum_btc)
        families[family]["sum_usd"].append(sum_usd)

# Splitting into groups
SMALL_THRESHOLD = 1000
MEDIUM_THRESHOLD = 50000
small, medium, large = [], [], []
for family in families:
    max_sum_usd = max(families[family]["sum_usd"])
    if max_sum_usd < SMALL_THRESHOLD:
        small.append(family)
    elif max_sum_usd < MEDIUM_THRESHOLD:
        medium.append(family)
    else:
        large.append(family)

print("Small:", len(small))
print("Medium:", len(medium))
print("Large:", len(large))

def plot_family_group(family_names, group_name="small"):
    fig, (ax1, ax2, ax3) = plt.subplots(3)
    fig.suptitle(f"Timeline of transactions of different ransomware families ({group_name})")

    formatter = mt.ScalarFormatter()
    formatter.set_scientific(False)

    for family_name in family_names:
        time = families[family_name]["time"]
        count = families[family_name]["count"]
        sum_btc = families[family_name]["sum_btc"]
        sum_usd = families[family_name]["sum_usd"]
        colour = np.random.rand(3,)
        ax1.plot(time, count, color=colour, marker='o', label=family_name)
        ax2.plot(time, sum_btc, color=colour, marker='o', label=family_name)
        ax3.plot(time, sum_usd, color=colour, marker='o', label=family_name)

    # Plot the number of transactions
    ax1.set_title("Number of transactions")
    ax1.xaxis.set_major_formatter(md.DateFormatter(date_format))
    ax1.xaxis.set_major_locator(date_locator)
    ax1.yaxis.set_major_formatter(formatter)
    ax1.tick_params(labelrotation=25)
    ax1.set_yscale(scale)
    ax1.legend(ncol=num_cols_legend, fontsize=font_size_legend)
    ax1.grid()

    # Plot the payment sum in BTC
    ax2.set_title("Payment sum in BTC")
    ax2.xaxis.set_major_formatter(md.DateFormatter(date_format))
    ax2.xaxis.set_major_locator(date_locator)
    ax2.yaxis.set_major_formatter(formatter)
    ax2.tick_params(labelrotation=25)
    ax2.set_yscale(scale)
    ax2.legend(ncol=num_cols_legend, fontsize=font_size_legend)
    ax2.grid()

    # Plot the payment sum in USD
    ax3.set_title("Payment sum in USD")
    ax3.xaxis.set_major_formatter(md.DateFormatter(date_format))
    ax3.xaxis.set_major_locator(date_locator)
    ax3.yaxis.set_major_formatter(formatter)
    ax3.tick_params(labelrotation=25)
    ax3.set_yscale(scale)
    ax3.legend(ncol=num_cols_legend, fontsize=font_size_legend)
    ax3.grid()

    plt.gcf().set_size_inches(22, 12, forward=True)
    plt.tight_layout()

    # plt.savefig(f"timeline_families_{group_name}.png")
    plt.show()
    fig.clf()


plot_family_group(small, "small")
plot_family_group(medium, "medium")
plot_family_group(large, "large")

