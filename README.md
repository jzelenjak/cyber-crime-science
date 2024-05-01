# Cyber Crime Science - Scripts

This repository contains the scripts used for the Cyber Crime Science course at TU Delft. We have investigated the influence of external factors on ransomware operations and financial behaviours. We have based our work on the paper by Oosthoek et al. ([A Tale of Two Markets: Investigating the Ransomware Payments Economy](https://dl.acm.org/doi/10.1145/3582489)).

**NB! Ransomware is bad for security. Do NOT perform any ransomware attacks, even if you know what you are doing.**

## How to run

First, download the [Ransomwhere](https://ransomwhe.re/) dataset. Then you run

```bash
$ ./run_stats.sh data.json
```

where `data.json` is the name of the downloaded JSON file.

The script `compare_datasets.sh` was only used to find the changes after the work of Oosthoek et al. and is not needed for other purposes.

## Plotting

It is possible to plot the timeline of transactions (per year and per month), the timeline of the average ransom (per year and per month) and the timeline of ransomware families.

First, comment out the corresponding lines in `run_stats.sh` in order to get the txt output with the data. Then run the Python script (`plot_years.py`, `plot_months.py`, `plot_avg.py` or `plot_families.py`) with the corresponding txt file.

