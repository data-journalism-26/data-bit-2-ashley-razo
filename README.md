# America's Invisible Killer: Heat as the Deadliest U.S. Weather Hazard

**Data Bit 2 — Data Journalism**
**Author:** Ashley Razo
**Date:** April 2026

---

## What I Did

This Data Bit examines two decades of U.S. weather fatality data to argue that **extreme heat is America's deadliest natural disaster** — killing more people than hurricanes, tornadoes, and floods combined — yet remains uncounted, underfunded, and unclassified as a federal disaster.

The piece makes two specific, data-driven arguments:
1. By official NWS counts, heat outpaces every other weather hazard in average annual deaths
2. Those official counts are themselves a severe undercount — experts estimate the true toll is 5–10× higher

### Technique
- **Programmatic work:** R (`readr`, `dplyr`, `tidyr`, `ggplot2`) for data pipeline and static figures
- **Interactive visualization:** D3.js embedded in `index.html` — hover-enabled bar chart and annotated line chart with estimated range ribbon
- **Design principles applied:** CVD-safe colors, zero-based axes, ordered by magnitude (not alphabetically), direct labels instead of legends, gridlines only where helpful, no 3D, no pie charts

---

## Repository Structure

```
├── index.html                          # Final written piece (interactive)
├── analysis.R                          # R pipeline: import → clean → figures
├── data/
│   └── nws_weather_fatalities.csv      # Raw data compiled from NWS annual PDFs
├── figures/
│   ├── fig1_avg_deaths_by_hazard.png   # Static Fig 1 (R output)
│   └── fig2_heat_deaths_trend.png      # Static Fig 2 (R output)
└── README.md
```

---

## Data Source & Pipeline

**Primary source:** NOAA National Weather Service Annual Natural Hazard Statistics
- URL: [weather.gov/hazstat](https://www.weather.gov/hazstat/)
- Annual PDFs: `sum04.pdf` through `sum24.pdf`
- Data manually compiled into `data/nws_weather_fatalities.csv`

**Pipeline:**
1. `analysis.R` imports `data/nws_weather_fatalities.csv`
2. Reshapes to long format using `tidyr::pivot_longer()`
3. Computes 2004–2024 averages by hazard type
4. Produces two static figures saved to `figures/`

**Note on data quality:**
NWS figures are direct-cause fatalities compiled from death certificates. Heat deaths are widely acknowledged as severe undercounts — when someone dies of cardiac arrest during a heat wave, heat rarely appears on the death certificate. The CDC has urged improved heat attribution since 2017. Expert estimates (Ebi, University of Washington) suggest the true toll is 5–10× official counts.

The 2005 hurricane figure (1,094 deaths, almost entirely from Katrina) is excluded from the long-run average to avoid single-event distortion of the 21-year trend.

---

## How to Reproduce

1. Clone this repository
2. Install required R packages:
   ```r
   install.packages(c("readr", "dplyr", "tidyr", "ggplot2", "scales"))
   ```
3. Run `analysis.R` from the repo root:
   ```r
   source("analysis.R")
   ```
4. Figures will be saved to `figures/`
5. Open `index.html` in any browser to view the interactive article

---

## 🔗 View the Final Piece

👉 **[Click here to read the article](https://raw.githack.com/data-journalism-26/data-bit-2-ashley/main/index.html)**

*(Update the URL above with your actual repository name before submitting.)*
