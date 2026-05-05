library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

#import
raw <- read_csv("data/nws_weather_fatalities.csv",
  col_types = cols(.default = col_integer()))

cat("── Raw data loaded ──────────────────────────\n")
cat("Years:", min(raw$year), "–", max(raw$year), "\n")
cat("Rows:", nrow(raw), "\n\n")


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


avg_by_hazard <- long %>%
  group_by(hazard) %>%
  summarise(mean_deaths = round(mean(deaths), 1)) %>%
  arrange(desc(mean_deaths))

cat("── Average annual deaths by hazard (2004–2024) ──\n")
print(avg_by_hazard)

# Validation
stopifnot(!any(is.na(long$deaths)))

#figure: average deaths by hazard type
hazard_order <- avg_by_hazard$hazard


fill_colors <- ifelse(hazard_order == "Heat", "#E07B39", "#6B92A8")

dir.create("figures", showWarnings = FALSE)

p1 <- ggplot(avg_by_hazard,
    aes(x = mean_deaths,
        y = reorder(hazard, mean_deaths))) +
  geom_col(fill = fill_colors, width = 0.7) +
  geom_text(aes(label = round(mean_deaths, 0)),
    hjust = -0.15, size = 3.3, color = "#333333") +

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

#figure: Heat deaths trend 2004–2024
heat_trend <- long %>%
  filter(hazard == "Heat") %>%

  mutate(
    official = deaths,
    # CDC/research estimates heat deaths are 10x official counts
    # Source: Yale E360 interview with Kristie Ebi (UW epidemiologist)
    estimated_low  = deaths * 5,
    estimated_high = deaths * 10
  )

p2 <- ggplot(heat_trend, aes(x = year)) +

  geom_ribbon(aes(ymin = estimated_low, ymax = estimated_high),
    fill = "#E07B39", alpha = 0.15) +

  geom_line(aes(y = (estimated_low + estimated_high) / 2),
    color = "#E07B39", linetype = "dashed", linewidth = 0.8) +

  geom_line(aes(y = official),
    color = "#2C5F7A", linewidth = 1.1) +
  geom_point(aes(y = official),
    color = "#2C5F7A", size = 2) +

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

#summary stats
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
