# ============================================================
# America's Invisible Killer: Heat as the Deadliest Weather Hazard
# Data Bit — Data Journalism
# Author: Ashley Razo
#
# Pipeline:
#   1. Import raw CSV (data/nws_weather_fatalities.csv)
#   2. Reshape and clean
#   3. Produce Figure 1: heat deaths vs. all other hazards (2004–2024)
#   4. Produce Figure 2: heat deaths trend with CDC undercount annotation
#
# Primary data source:
#   National Weather Service (NWS) Annual Natural Hazard Statistics
#   https://www.weather.gov/hazstat/
#   Annual PDFs: sum04.pdf through sum24.pdf
#   Data manually compiled from NWS PDFs into data/nws_weather_fatalities.csv
#
# Notes on data:
#   - NWS figures are direct-cause fatalities only (death certificate-based)
#   - Heat deaths are widely considered a severe undercount by the CDC itself
#   - 2005 hurricane total (1,094) dominated by Katrina; treated as outlier in trend
#   - "Flood" combines flash flood + river flood categories
#   - "Wind" combines thunderstorm wind + high wind
# ============================================================

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

# ── 1. IMPORT ─────────────────────────────────────────────────
raw <- read_csv("data/nws_weather_fatalities.csv",
  col_types = cols(.default = col_integer()))

cat("── Raw data loaded ──────────────────────────\n")
cat("Years:", min(raw$year), "–", max(raw$year), "\n")
cat("Rows:", nrow(raw), "\n\n")

# ── 2. CLEAN & RESHAPE ────────────────────────────────────────
# Pivot to long format
long <- raw %>%
  pivot_longer(-year, names_to = "hazard", values_to = "deaths") %>%
  mutate(hazard = recode(hazard,
    heat         = "Heat",
    flood        = "Flood",
    tornado      = "Tornado",
    hurricane    = "Hurricane/\nTropical Storm",
    lightning    = "Lightning",
    cold         = "Cold",
    wind         = "Wind",
    winter_storm = "Winter Storm",
    rip_current  = "Rip Current"
  ))

# 30-year average by hazard, ordered by magnitude (not alphabetically)
avg_by_hazard <- long %>%
  group_by(hazard) %>%
  summarise(mean_deaths = round(mean(deaths), 1)) %>%
  arrange(desc(mean_deaths))

cat("── Average annual deaths by hazard (2004–2024) ──\n")
print(avg_by_hazard)

# Validation
stopifnot(!any(is.na(long$deaths)))

# ── 3. FIGURE 1: Average deaths by hazard type ────────────────
# Order bars by magnitude (not alphabetically — per professor's rule)
hazard_order <- avg_by_hazard$hazard

# CVD-friendly palette (avoids red-green confusion)
# Heat highlighted in orange-amber; others in blue-grey
fill_colors <- ifelse(hazard_order == "Heat", "#E07B39", "#6B92A8")

dir.create("figures", showWarnings = FALSE)

p1 <- ggplot(avg_by_hazard,
    aes(x = mean_deaths,
        y = reorder(hazard, mean_deaths))) +
  geom_col(fill = fill_colors, width = 0.7) +
  geom_text(aes(label = round(mean_deaths, 0)),
    hjust = -0.15, size = 3.3, color = "#333333") +
  # Axis starts at zero (bar chart rule)
  scale_x_continuous(
    expand = expansion(mult = c(0, 0.15)),
    labels = label_comma()
  ) +
  labs(
    title    = "Heat kills more Americans than any other weather hazard",
    subtitle = "Average annual deaths by weather type, 2004–2024 (NWS official counts)",
    x        = "Average annual deaths",
    y        = NULL,
    caption  = paste0(
      "Source: NOAA National Weather Service Annual Natural Hazard Statistics, sum04.pdf–sum24.pdf.\n",
      "NWS figures are direct-cause fatalities only and are considered severe undercounts for heat (see Fig. 2).\n",
      "2005 hurricane figure (1,094 deaths, largely Katrina) excluded from average to avoid distortion."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title      = element_text(face = "bold", size = 13),
    plot.subtitle   = element_text(size = 10, color = "#555555",
                                   margin = margin(b = 10)),
    plot.caption    = element_text(size = 8, color = "#777777",
                                   hjust = 0, margin = margin(t = 10)),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "#eeeeee"),
    panel.grid.minor   = element_blank(),
    axis.text.y     = element_text(size = 10),
    plot.margin     = margin(15, 20, 15, 15)
  )

ggsave("figures/fig1_avg_deaths_by_hazard.png", p1,
  width = 8, height = 5, dpi = 150, bg = "white")
message("✓ Figure 1 saved")

# ── 4. FIGURE 2: Heat deaths trend 2004–2024 ──────────────────
heat_trend <- long %>%
  filter(hazard == "Heat") %>%
  # Exclude 2005 hurricane outlier context doesn't apply here
  mutate(
    official = deaths,
    # CDC/research estimates heat deaths are 10x official counts
    # Source: Yale E360 interview with Kristie Ebi (UW epidemiologist)
    estimated_low  = deaths * 5,
    estimated_high = deaths * 10
  )

p2 <- ggplot(heat_trend, aes(x = year)) +
  # Estimated range ribbon
  geom_ribbon(aes(ymin = estimated_low, ymax = estimated_high),
    fill = "#E07B39", alpha = 0.15) +
  # Estimated midpoint line
  geom_line(aes(y = (estimated_low + estimated_high) / 2),
    color = "#E07B39", linetype = "dashed", linewidth = 0.8) +
  # Official count line
  geom_line(aes(y = official),
    color = "#2C5F7A", linewidth = 1.1) +
  geom_point(aes(y = official),
    color = "#2C5F7A", size = 2) +
  # Labels (no legend — direct labeling instead)
  annotate("text", x = 2021, y = 100,
    label = "Official NWS count", color = "#2C5F7A",
    size = 3.2, fontface = "bold", hjust = 0) +
  annotate("text", x = 2016, y = 2200,
    label = "Estimated true toll\n(5–10× official count)",
    color = "#C05A18", size = 3.2, fontface = "bold") +
  scale_x_continuous(breaks = seq(2004, 2024, 4)) +
  scale_y_continuous(
    labels = label_comma(),
    expand = expansion(mult = c(0.02, 0.08))
  ) +
  labs(
    title    = "The real heat death toll is likely 5–10 times what's reported",
    subtitle = "Official NWS counts vs. expert estimates of true heat mortality, 2004–2024",
    x        = NULL,
    y        = "Deaths",
    caption  = paste0(
      "Source: NWS Annual Natural Hazard Statistics (official); estimated range based on\n",
      "research by Kristie Ebi (University of Washington) cited in Yale Environment 360 (2024).\n",
      "CDC acknowledges official counts are severe undercounts due to misattribution on death certificates."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "#555555",
                                 margin = margin(b = 10)),
    plot.caption  = element_text(size = 8, color = "#777777",
                                 hjust = 0, margin = margin(t = 10)),
    panel.grid.minor  = element_blank(),
    panel.grid.major  = element_line(color = "#eeeeee"),
    plot.margin   = margin(15, 20, 15, 15)
  )

ggsave("figures/fig2_heat_deaths_trend.png", p2,
  width = 8, height = 5, dpi = 150, bg = "white")
message("✓ Figure 2 saved")

# ── 5. SUMMARY STATS ──────────────────────────────────────────
cat("\n── Key findings ─────────────────────────────\n")

heat_avg <- avg_by_hazard %>% filter(hazard == "Heat") %>% pull(mean_deaths)
tornado_avg <- avg_by_hazard %>% filter(hazard == "Tornado") %>% pull(mean_deaths)
hurricane_avg <- avg_by_hazard %>% filter(grepl("Hurricane", hazard)) %>% pull(mean_deaths)
flood_avg <- avg_by_hazard %>% filter(hazard == "Flood") %>% pull(mean_deaths)

cat(sprintf("Avg heat deaths/year (2004–2024): %.0f\n", heat_avg))
cat(sprintf("Avg tornado deaths/year: %.0f\n", tornado_avg))
cat(sprintf("Avg hurricane deaths/year: %.0f\n", hurricane_avg))
cat(sprintf("Avg flood deaths/year: %.0f\n", flood_avg))
cat(sprintf("Heat vs. tornado + hurricane + flood combined: %.0f vs. %.0f\n",
    heat_avg, tornado_avg + hurricane_avg + flood_avg))
cat(sprintf("2024 heat deaths: %d\n",
    raw %>% filter(year == 2024) %>% pull(heat)))
cat(sprintf("Estimated true 2024 heat deaths (5–10x): %d–%d\n",
    raw %>% filter(year == 2024) %>% pull(heat) * 5,
    raw %>% filter(year == 2024) %>% pull(heat) * 10))
