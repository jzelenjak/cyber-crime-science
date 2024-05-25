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
if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} us-yearly-inflation-rates.csv world-inflation-rates.csv")
    exit(1)


formatter = mt.ScalarFormatter()
formatter.set_scientific(False)

dateformat = "%Y"
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
ax.xaxis.set_major_locator(md.YearLocator())
ax.yaxis.set_major_formatter(formatter)
ax.tick_params(labelrotation=25)

ymin = math.floor(min(min(us_rates), min(world_rates)))
ymax = math.ceil(max(max(us_rates), max(world_rates)))
plt.yticks(np.arange(ymin, ymax, 0.5).tolist())
plt.ylim(ymin, ymax)

plt.xlim(us_years[0], us_years[-1])
first_year = us_years[0].strftime("%Y")
last_year = us_years[-1].strftime("%Y")
plt.title(f"US and World Inflation Rates in the period from {first_year} and {last_year}")

# Add value labels
for i in range(len(us_rates)):
    plt.text(us_years[i], us_rates[i], us_rates[i])
for i in range(len(world_rates)):
    plt.text(world_years[i], world_rates[i], world_rates[i])

plt.plot(us_years, us_rates, color='black', label="US")
plt.plot(world_years, world_rates, color='cyan', label="World")
plt.gcf().set_size_inches(20, 10, forward=True)
plt.grid()
plt.legend()
plt.tight_layout()

plt.show()
