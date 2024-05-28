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
    print(f"Usage: {sys.argv[0]} us-montly-inflation-rates.csv")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y-%m"
months, rates = [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines():  #[1:]:
        parts = line.split(file_separator)
        months.append(datetime.datetime.strptime(parts[0], dateformat))
        rates.append(float(parts[1]))

fig = plt.figure()
ax = fig.add_subplot(111)

ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax.xaxis.set_major_locator(md.MonthLocator(interval=3))
ax.yaxis.set_major_formatter(formatter)
ax.tick_params(labelrotation=25, labelsize=13)

ymin = math.floor(min(rates))
ymax = math.ceil(max(rates))
plt.yticks(np.arange(ymin, ymax, 0.5).tolist())
plt.ylim(ymin, ymax)

# Add value labels
epsilon = 0.1
for i in range(1, len(rates) - 1):
    if rates[i] > (rates[i-1] + epsilon) and rates[i] > (rates[i+1] + epsilon):
        plt.text(months[i], rates[i], rates[i], fontsize=13)
plt.text(months[0], rates[0], rates[0], fontsize=13)
plt.text(months[-1], rates[-1], rates[-1], fontsize=13)

plt.xlim(months[0], months[-1])
first_month = months[0].strftime("%B %Y")
last_month = months[-1].strftime("%B %Y")
plt.title(f"US Inflation Rates in the period from {first_month} and {last_month}", fontsize=15)

plt.plot(months, rates, color='black', label="US")
plt.gcf().set_size_inches(20, 10, forward=True)
plt.grid()
plt.tight_layout()

plt.show()
