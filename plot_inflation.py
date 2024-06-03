#!/usr/bin/env python
#
# This script plots the yearly timeline of the US and global inflation rates, based on the files us_yearly_inflation_rates.csv and world_inflation_rates.csv.
# Both files us_yearly_inflation_rates.csv and world_inflation_rates.csv are located in the data/ directory.

import datetime
import math
import sys

import matplotlib.dates as md
import matplotlib.pyplot as plt
import matplotlib.ticker as mt
import numpy as np


# The file is assumed to be comma-separated (i.e. in the csv format)
file_separator = ","
if len(sys.argv) != 3:
    print(f"Usage: python {sys.argv[0]} data/us_yearly_inflation_rates.csv data/world_inflation_rates.csv")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y"
datelocator = md.YearLocator()

us_years, us_rates = [], []
with open(sys.argv[1], "r") as file:
    for line in file.readlines():
        parts = line.split(file_separator)
        us_years.append(datetime.datetime.strptime(parts[0], dateformat))
        us_rates.append(float(parts[1]))

world_years, world_rates = [], []
with open(sys.argv[2], "r") as file:
    for line in file.readlines():
        parts = line.split(file_separator)
        world_years.append(datetime.datetime.strptime(parts[0], dateformat))
        world_rates.append(float(parts[1]))


fig = plt.figure()
ax = fig.add_subplot(111)

ax.xaxis.set_major_formatter(md.DateFormatter(dateformat))
ax.xaxis.set_major_locator(datelocator)
ax.yaxis.set_major_formatter(formatter)
ax.tick_params(labelrotation=25, labelsize=14)

ymin = math.floor(min(min(us_rates), min(world_rates)))
ymax = math.ceil(max(max(us_rates), max(world_rates)))
plt.yticks(np.arange(ymin, ymax, 0.5).tolist(), fontsize=13)
plt.ylim(ymin, ymax)

plt.xlim(us_years[0], us_years[-1])
first_year = us_years[0].strftime("%Y")
last_year = us_years[-1].strftime("%Y")
plt.title(f"US and World Inflation Rates in the period from {first_year} and {last_year}", fontsize=20)

# Add value labels for peaks for the US line
for i in range(1, len(us_rates) - 1):
    plt.text(us_years[i], us_rates[i], us_rates[i], ha="center", va="bottom", fontfamily="monospace", fontsize=15)
plt.text(us_years[0], us_rates[0], us_rates[0], ha="left", va="bottom", fontfamily="monospace", fontsize=15)
plt.text(us_years[-1], us_rates[-1], us_rates[-1], ha="right", va="bottom", fontfamily="monospace", fontsize=15)
# Add value labels for peaks for the world line
for i in range(1, len(world_rates) - 1):
    plt.text(world_years[i], world_rates[i], world_rates[i], ha="center", va="bottom", fontfamily="monospace", fontsize=15)
plt.text(world_years[0], world_rates[0], world_rates[0], ha="left", va="bottom", fontfamily="monospace", fontsize=15)
plt.text(world_years[-1], world_rates[-1], world_rates[-1], ha="right", va="bottom", fontfamily="monospace", fontsize=15)

plt.plot(us_years, us_rates, color='black', label="US")
plt.plot(world_years, world_rates, color='cyan', label="World")
plt.gcf().set_size_inches(22, 11, forward=True)
plt.grid()
plt.legend(fontsize=15)
plt.tight_layout()

#plt.savefig("inflation.png")
plt.show()
