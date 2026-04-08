# =========================
# 1. Libraries
# =========================
library(readxl)
library(dplyr)
library(igraph)
library(scales)
library(ggplot2)
library(RColorBrewer)
library(ggrepel)
library(tidyr)
# =========================
# 2. Load Data
# =========================
worldbank <- read_excel("API_IS.AIR.GOOD.MT.K1_DS2_en_excel_v2_1814.xls")
routes <- read.csv("routes.dat", header = FALSE)
airports <- read.csv("airports.dat", header = FALSE)

# =========================
# 3. Rename Columns
# =========================
colnames(routes) <- c(
  "Airline","AirlineID",
  "Source","SourceID",
  "Destination","DestID",
  "Codeshare","Stops","Equipment"
)

colnames(airports) <- c(
  "AirportID","Name","City","Country",
  "IATA","ICAO","Lat","Lon",
  "Altitude","Timezone","DST",
  "Tz","Type","Source"
)

# =========================
# 4. Route Aggregation 
# =========================
route_agg <- routes %>%
  group_by(Source, Destination) %>%
  summarise(
    total_flights = n(),
    airlines = n_distinct(Airline),
    .groups = "drop"
  )

# =========================
# 5. Filter HKG routes
# =========================
hkg_routes <- route_agg %>%
  filter(Source == "HKG" | Destination == "HKG")

hkg_out <- route_agg %>%
  filter(Source == "HKG")

# =========================
# 6. Join airport info
# =========================
hkg_out <- hkg_out %>%
  left_join(airports[, c("IATA","City","Country","Lat","Lon")],
            by = c("Destination" = "IATA"))

# =========================
# 7. Top destination countries
# =========================
top_dest <- hkg_out %>%
  count(Country, wt = total_flights, sort = TRUE)

head(top_dest, 10)

# =========================
# 8. Region classification
# =========================
hkg_out <- hkg_out %>%
  mutate(Region = case_when(
    Country %in% c("China","Japan","South Korea","Taiwan") ~ "East Asia",
    Country %in% c("Thailand","Vietnam","Malaysia","Indonesia","Singapore","Philippines") ~ "Southeast Asia",
    TRUE ~ "Other"
  ))

region_summary <- hkg_out %>%
  count(Region, sort = TRUE)

# =========================
# 9. Compare with SIN
# =========================
sin_out <- route_agg %>%
  filter(Source == "SIN") %>%
  left_join(airports[, c("IATA","Country")],
            by = c("Destination" = "IATA"))

sin_top <- sin_out %>%
  count(Country, wt = total_flights, sort = TRUE)

top_hkg <- top_dest %>% mutate(Hub = "HKG")
top_sin <- sin_top %>% mutate(Hub = "SIN")

compare_data <- bind_rows(top_hkg, top_sin)

top_compare <- compare_data %>%
  group_by(Country) %>%
  summarise(total = sum(n)) %>%
  arrange(desc(total)) %>%
  slice(1:10) %>%
  pull(Country)

plot_data <- compare_data %>%
  filter(Country %in% top_compare)

# =========================
# 10. Visualization - Country comparison
# =========================
ggplot(plot_data, aes(x = Country, y = n, fill = Hub)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(title = "HKG vs SIN Route Distribution",
       x = "Country", y = "Routes")
hkg_order <- plot_data %>%
  filter(Hub == "HKG") %>%
  arrange(desc(n)) %>%
  pull(Country)

plot_data$Country <- factor(plot_data$Country, levels = rev(hkg_order))

ggplot(plot_data, aes(x = Country, y = n, fill = Hub)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(title = "HKG vs SIN Route Distribution",
       x = "Country", y = "Routes")

# =========================
# 11. Network Graph 
# =========================
g <- graph_from_data_frame(route_agg, directed = TRUE)

E(g)$weight <- route_agg$total_flights

# Centrality
deg <- degree(g, mode = "all")
bet <- betweenness(g, weights = E(g)$weight)

top_nodes <- sort(deg, decreasing = TRUE)[1:10]
top_nodes

# =========================
# 12. Subgraph (Top destinations)
# =========================
top_airports <- hkg_out %>%
  arrange(desc(total_flights)) %>%
  slice(1:12) %>%
  pull(Destination)

hkg_small <- route_agg %>%
  filter(Source == "HKG") %>%
  arrange(desc(total_flights)) %>%
  slice(1:12)

g_small <- graph_from_data_frame(hkg_small, directed = TRUE)

E(g_small)$weight <- hkg_small$total_flights
edge.w <- E(g_small)$weight

cols <- colorRampPalette(brewer.pal(9, "Blues"))(100)
edge.col <- cols[as.numeric(cut(edge.w, breaks = 100))]

edge.width.scaled <- 1 + 4 * (edge.w / max(edge.w))

set.seed(123)

lay <- layout_with_fr(g_small) * 1.5

plot(g_small,
     layout = lay,
     edge.color = edge.col,
     edge.width = edge.width.scaled,
     edge.label = edge.w,
     edge.label.cex = 0.7,
     vertex.size = 6,
     vertex.label.cex = 1.2,
     vertex.label.dist = 0.6,
     main = "Top 12 HKG Routes (Weighted)")

# =========================
# 13. Map Data
# =========================
hkg_coord <- airports %>%
  filter(IATA == "HKG") %>%
  select(Lat, Lon)

hkg_map <- hkg_out %>%
  filter(!is.na(Lat), !is.na(Lon))
sin_coord <- airports %>%
  filter(IATA == "SIN") %>%
  select(Lat, Lon)

sin_map <- routes %>%
  filter(Source == "SIN") %>%
  left_join(airports, by = c("Destination" = "IATA"))
# =========================
# 14. Global Map
# =========================
ggplot() +
  borders("world", colour = "gray70", fill = "gray90") +
  
  geom_segment(data = hkg_map,
               aes(x = hkg_coord$Lon,
                   y = hkg_coord$Lat,
                   xend = Lon,
                   yend = Lat),
               alpha = 0.2) +
  
  geom_point(data = hkg_map,
             aes(x = Lon, y = Lat),
             alpha = 0.6) +
  
  geom_point(aes(x = hkg_coord$Lon, y = hkg_coord$Lat),
             size = 3) +
  
  labs(title = "Hong Kong Air Route Network")
ggplot() +
  borders("world", colour = "gray70", fill = "gray90") +
  
  geom_segment(data = sin_map,
               aes(x = sin_coord$Lon,
                   y = sin_coord$Lat,
                   xend = Lon,
                   yend = Lat),
               alpha = 0.2) +
  
  geom_point(data = sin_map,
             aes(x = Lon, y = Lat),
             alpha = 0.6) +
  
  geom_point(aes(x = sin_coord$Lon, y = sin_coord$Lat),
             size = 3) +
  
  labs(title = "Singapore Air Route Network")
# =========================
# 15. Weighted Map
# =========================
temp <- hkg_out %>%
  left_join(
    airports %>% select(IATA, Lat, Lon),
    by = c("Destination" = "IATA")
  )

head(temp)

hkg_map_weighted <- temp %>%
  mutate(
    Lat = Lat.y,
    Lon = Lon.y
  ) %>%
  filter(!is.na(Lat), !is.na(Lon))
hkg_top <- hkg_map_weighted %>%
  arrange(desc(total_flights)) %>%
  slice(1:15)
ggplot() +
  borders("world", colour = "gray70", fill = "gray90") +
  
  geom_segment(
    data = hkg_top,
    aes(x = 114.1095, y = 22.3964,
        xend = Lon, yend = Lat,
        size = total_flights,
        color = total_flights), 
    alpha = 0.5
  ) +
  
  geom_point(
    data = hkg_top,
    aes(x = Lon, y = Lat, size = total_flights, color = total_flights),
    alpha = 0.8
  ) +
  
  geom_point(aes(x = 114.1095, y = 22.3964),
             size = 2, color = "black") +
  
  geom_text_repel(
    data = hkg_top,
    aes(x = Lon, y = Lat, label = Destination, color = total_flights),
    size = 3.5,
    fontface = "bold",
    max.overlaps = Inf
  ) +
  
  scale_color_gradientn(colors = c("royalblue", "darkblue")) +
  
  scale_size_continuous(range = c(0.2, 1), guide = "none") +
  
  coord_fixed() +
  theme_minimal() +
  labs(title = "Top 15 Hong Kong Route Network") +
  theme(
    plot.title = element_text(size = 18, face = "bold")
  )

# =========================
# 16. Asia-only Map
# =========================
hkg_map_asia <- hkg_map_weighted %>%
  filter(Lon >= 60 & Lon <= 150,
         Lat >= -10 & Lat <= 60)

top10 <- hkg_map_asia %>%
  arrange(desc(total_flights)) %>%
  slice(1:10)

ggplot() +
  borders("world", colour = "gray70", fill = "gray90",
          xlim = c(60, 150),
          ylim = c(-10, 60)) +
  
  geom_segment(data = hkg_map_asia,
               aes(x = hkg_coord$Lon,
                   y = hkg_coord$Lat,
                   xend = Lon,
                   yend = Lat,
                   size = total_flights,
                   color = total_flights), 
               alpha = 0.5) +
  

  geom_point(data = hkg_map_asia,
             aes(x = Lon, y = Lat, size = total_flights, color = total_flights),
             alpha = 0.8) +
  
  geom_point(aes(x = hkg_coord$Lon, y = hkg_coord$Lat),
             size = 2, color = "black") +

  geom_text_repel(
    data = top10,
    aes(x = Lon, y = Lat, label = Destination, color = total_flights),
    size = 3.5,
    fontface = "bold"
  ) +
  
  scale_color_gradientn(colors = c("tomato", "darkred")) +
  
  scale_size_continuous(range = c(0.2, 1)) +
  
  coord_fixed() +
  theme_minimal() +
  labs(title = "HKG Flight Connectivity (Asia)")+
  theme(
    plot.title = element_text(size = 18, face = "bold"))
# =========================
# 17. Network Metrics Analysis
# =========================

g_full <- graph_from_data_frame(route_agg, directed = TRUE)

# Edge weights
E(g_full)$weight <- route_agg$total_flights

# -------------------------
# 17.2 Network-level metrics
# -------------------------

edge_density(g_full)
transitivity(g_full)
mean_distance(g_full, directed = TRUE)

# -------------------------
# 17.3 Centrality (FULL network, HKG included)
# -------------------------

deg_full <- degree(g_full, mode = "all")
bet_full <- betweenness(g_full, weights = E(g_full)$weight)

centrality_df <- data.frame(
  airport = names(deg_full),
  degree = deg_full,
  betweenness = bet_full
)

# Top hubs (overall)
top_hubs <- centrality_df %>%
  arrange(desc(betweenness)) %>%
  head(10)

top_hubs

# -------------------------
# 17.4 OPTIONAL: Remove HKG (sensitivity analysis)
# -------------------------

g_no_hkg <- delete_vertices(g_full, "HKG")

deg_no_hkg <- degree(g_no_hkg, mode = "all")
bet_no_hkg <- betweenness(g_no_hkg, weights = E(g_no_hkg)$weight)

centrality_no_hkg <- data.frame(
  airport = names(deg_no_hkg),
  degree = deg_no_hkg,
  betweenness = bet_no_hkg
)

top_hubs_no_hkg <- centrality_no_hkg %>%
  arrange(desc(betweenness)) %>%
  head(10)

top_hubs_no_hkg

# -------------------------
# 17.5 Combine ranking (structure importance)
# -------------------------

centrality_ranked <- centrality_df %>%
  mutate(score = scale(degree) + scale(betweenness)) %>%
  arrange(desc(score))%>%head(10)

# -------------------------
# 17.6 Prepare map data
# -------------------------

centrality_map <- centrality_df %>%
  left_join(airports[, c("IATA", "Lat", "Lon")],
            by = c("airport" = "IATA")) %>%
  filter(!is.na(Lat), !is.na(Lon))

# -------------------------
# 17.7 Top 10 subsets for mapping
# -------------------------

top10_degree <- centrality_map %>%
  arrange(desc(degree)) %>%
  slice(1:10)

top10_betweenness <- centrality_map %>%
  arrange(desc(betweenness)) %>%
  slice(1:10)

ggplot() +
  borders("world", colour = "gray70", fill = "gray90") +
  
  geom_point(
    data = top10_degree,
    aes(x = Lon, y = Lat, size = degree, color = degree), 
    alpha = 0.5
  ) +
  
  geom_text_repel(
    data = top10_degree,
    aes(x = Lon, y = Lat, label = airport, color = degree), 
    size = 3,
    fontface = "bold"
  ) +
  
  scale_size(range = c(0.5, 3)) +
  scale_color_gradientn(
    colors = c( "royalblue","darkblue")
  )  + 
  
  coord_fixed() +
  labs(title = "Top 10 Airports by Degree (Connectivity)")

ggplot() +
  borders("world", colour = "gray70", fill = "gray90") +
  
  geom_point(
    data = top10_betweenness,
    aes(x = Lon, y = Lat, size = betweenness, color = betweenness), 
    alpha = 0.8
  ) +
  
  geom_text_repel(
    data = top10_betweenness,
    aes(x = Lon, y = Lat, label = airport, color = betweenness), 
    size = 3,
    fontface = "bold"
  ) +
  scale_size(
    range = c(0.5, 2),
    labels = scales::number_format(accuracy =1, big.mark = ",")
  ) +
  scale_color_gradientn(
    colors = c( "red","darkred"),labels = scales::number_format(accuracy =1, big.mark = ",")
  )  + 
  
  coord_fixed() +
  
  scale_y_continuous(labels = scales::comma) +  
  scale_x_continuous(labels = scales::comma) +
  
  labs(title = "Top 10 Airports by Betweenness (Transfer Importance)")



top_label <- centrality_df %>%
  filter(degree > 350 | betweenness > 600000)

ggplot(centrality_df, aes(x = degree, y = betweenness)) +
  geom_point(alpha = 0.8) +
  geom_point(data = top_label, color = "red") + 
  geom_text_repel(
    data = top_label,
    aes(label = airport),
    size = 4,color="red"
  ) +
  scale_y_continuous(
    limits = c(0, 650000),            
    breaks = seq(0, 650000, by = 50000), 
    labels = function(x) paste0(x / 1000, "k") 
  ) +
  labs(title = "Degree vs Betweenness",
       x = "Degree",
       y = "Betweenness")+
  theme(
         plot.title = element_text(size = 18, face = "bold"), 
         axis.title = element_text(size = 14),               
         axis.text = element_text(size = 12)                
       )

# =========================
# 18. Route Concentration Analysis
# =========================

# Distribution of route frequencies
summary(hkg_out$total_flights)

quantile(hkg_out$total_flights)

# Pareto-style cumulative contribution
route_concentration <- hkg_out %>%
  arrange(desc(total_flights)) %>%
  mutate(
    cum_flights = cumsum(total_flights),
    cum_share = cum_flights / sum(total_flights)
  )
route_concentration <- route_concentration %>%
  mutate(rank = row_number())
# Top routes contribution
head(route_concentration, 10)

# Plot cumulative distribution
ggplot(route_concentration, aes(x = rank, y = cum_share)) +
  geom_line(size = 1) +
  
  geom_hline(yintercept = 0.8, linetype = "dashed", color = "red") +
  
  annotate("text",
           x = max(route_concentration$rank) * 0.3,
           y = 0.82,
           label = "80% of flights",
           color = "red") +
  
  labs(
    title = "Are Flights Concentrated in a Few Routes?",
    x = "Number of routes",
    y = "Share of total flights"
  )
pareto_point <- route_concentration %>%
  filter(cum_share >= 0.8) %>%
  slice(1)

paste0(
  "Top ", pareto_point$rank,
  " routes account for ",
  round(pareto_point$cum_share * 100, 1),
  "% of total flights."
)



# =========================
# 19. Region Analysis
# =========================

region_summary <- hkg_out %>%
  group_by(Region) %>%
  summarise(total_flights = sum(total_flights)) %>%
  mutate(pct = total_flights / sum(total_flights))

region_summary

# Visualization
ggplot(region_summary, aes(x = Region, y = pct, fill = Region)) +
  geom_bar(stat = "identity") +
  labs(title = "Regional Distribution of HKG Routes",
       x = "Region", y = "Proportion")

# =========================
# 20. Country-Level Concentration
# =========================

country_summary <- hkg_out %>%
  filter(!is.na(Country)) %>%
  group_by(Country) %>%
  summarise(total_flights = sum(total_flights)) %>%
  arrange(desc(total_flights))
# Top 10 countries
head(country_summary, 10)

# =========================
# 21. HKG vs SIN Network Comparison
# =========================

# Reuse SIN data
sin_routes <- route_agg %>%
  filter(Source == "SIN") %>%
  left_join(airports[, c("IATA","Country")],
            by = c("Destination" = "IATA"))
g_hkg <- graph_from_data_frame(hkg_routes, directed = TRUE)
E(g_hkg)$weight <- hkg_routes$total_flights
# Degree centrality for SIN
g_sin <- graph_from_data_frame(sin_routes, directed = TRUE)
E(g_sin)$weight <- sin_routes$total_flights

deg_sin <- degree(g_sin)

# Compare basic network size
network_stats <- data.frame(
  Hub = c("HKG", "SIN"),
  Nodes = c(vcount(g_hkg), vcount(g_sin)),
  Edges = c(ecount(g_hkg), ecount(g_sin)),
  Density = c(edge_density(g_hkg), edge_density(g_sin))
)

network_stats

# =========================
# 22. Top Hub Comparison
# =========================

# -------------------------
# HKG 2-step network
# -------------------------

hkg_lvl1 <- route_agg %>%
  filter(Source == "HKG") %>%
  pull(Destination)

hkg_2step <- route_agg %>%
  filter(Source %in% hkg_lvl1)

g_hkg_2 <- graph_from_data_frame(hkg_2step, directed = TRUE)

bet_hkg_2 <- betweenness(g_hkg_2)

top_hkg_hubs <- data.frame(
  airport = names(bet_hkg_2),
  betweenness = bet_hkg_2
) %>%
  arrange(desc(betweenness)) %>%
  slice(1:10)

top_hkg_hubs


# -------------------------
# SIN 2-step network
# -------------------------

sin_lvl1 <- route_agg %>%
  filter(Source == "SIN") %>%
  pull(Destination)

sin_2step <- route_agg %>%
  filter(Source %in% sin_lvl1)

g_sin_2 <- graph_from_data_frame(sin_2step, directed = TRUE)

bet_sin_2 <- betweenness(g_sin_2)

top_sin_hubs <- data.frame(
  airport = names(bet_sin_2),
  betweenness = bet_sin_2
) %>%
  arrange(desc(betweenness)) %>%
  slice(1:10)

top_sin_hubs
# =========================
# 23. Interpretation Summary Tables
# =========================

# Combine region + country insights
analysis_summary <- list(
  region = region_summary,
  top_countries = country_summary,
  network = network_stats,
  hkg_hubs = top_hkg_hubs,
  sin_hubs = top_sin_hubs
)

analysis_summary

hub_compare <- bind_rows(
  top_hkg_hubs %>% mutate(Hub = "HKG"),
  top_sin_hubs %>% mutate(Hub = "SIN")
)

ggplot(hub_compare, aes(x = reorder(airport, betweenness), y = betweenness, fill = Hub)) +
  geom_bar(stat = "identity", position = "dodge") +
  
  coord_flip() +
  
  labs(
    title = "Top Transfer Hubs: HKG vs SIN",
    x = "Airport",
    y = "Betweenness (Transfer Importance)"
  ) +
  
  theme_minimal()

network_long <- network_stats %>%
  pivot_longer(cols = -Hub, names_to = "Metric", values_to = "Value")

ggplot(network_long, aes(x = Hub, y = Value, fill = Hub)) +
  geom_bar(stat = "identity") +
  facet_wrap(~ Metric, scales = "free_y") +
  labs(title = "Network Comparison: HKG vs SIN") +
  theme_minimal()

# 24.1 Identify over-concentration risk
top3_share <- country_summary %>%
  slice(1:3) %>%
  summarise(share = sum(total_flights) / sum(country_summary$total_flights))

top3_share
country_summary %>%
  arrange(desc(total_flights)) %>%
  mutate(cum_share = cumsum(total_flights) / sum(total_flights)) %>%
  ggplot(aes(x = reorder(Country, -total_flights), y = cum_share)) +
  geom_line(group = 1) +
  
  geom_hline(yintercept = 0.8, linetype = "dashed", color = "red") +
  
  annotate("text",
           x = max(route_concentration$rank) * 0.3,
           y = 0.82,
           label = "80% of flights",
           color = "red") +
  geom_point() +
  labs(title = "Cumulative Market Share in HKG",
       x = "Country",
       y = "Cumulative Share") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 24.2 Compare regional focus
region_compare <- bind_rows(
  hkg_out %>% mutate(Hub = "HKG"),
  sin_routes %>% mutate(Hub = "SIN")
) %>%
  group_by(Hub, Country) %>%
  summarise(flights = sum(total_flights), .groups = "drop")
region_compare %>%
  filter(!is.na(Country), !is.na(flights)) %>%
  complete(Hub, Country, fill = list(flights = 0)) %>%
  ggplot(aes(x = reorder(Country, flights), y = flights, fill = Hub)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  scale_y_continuous(
    breaks = seq(0, max(region_compare$flights, na.rm = TRUE), by = 10)
  ) +
  labs(title = "HKG vs SIN Route Distribution",
       x = "Country",
       y = "Flights") +
  theme_minimal()

# 24.3 Diversification score（越平均越好）
diversification <- country_summary %>%
  mutate(p = total_flights / sum(total_flights)) %>%
  summarise(entropy = -sum(p * log(p)))

diversification


entropy_hkg <- hkg_out %>%
  filter(!is.na(Country), !is.na(total_flights)) %>%
  group_by(Country) %>%
  summarise(total_flights = sum(total_flights)) %>%
  mutate(p = total_flights / sum(total_flights)) %>%
  summarise(entropy = -sum(p * log(p))) %>%
  pull(entropy)

entropy_sin <- sin_routes %>%
  filter(!is.na(Country), !is.na(total_flights)) %>%
  group_by(Country) %>%
  summarise(total_flights = sum(total_flights)) %>%
  mutate(p = total_flights / sum(total_flights)) %>%
  summarise(entropy = -sum(p * log(p))) %>%
  pull(entropy)

div_df <- data.frame(
  Hub = c("HKG", "SIN"),
  Entropy = c(entropy_hkg, entropy_sin)
)
calc_top3_share <- function(df) {
  df %>%
    filter(!is.na(Country)) %>%
    group_by(Country) %>%
    summarise(total_flights = sum(total_flights)) %>%
    arrange(desc(total_flights)) %>%
    slice(1:3) %>%
    summarise(share = sum(total_flights) / sum(df$total_flights, na.rm = TRUE)) %>%
    pull(share)
}
top3_share_hkg <- calc_top3_share(hkg_out)
top3_share_sin <- calc_top3_share(sin_routes)
summary_df <- data.frame(
  Hub = c("HKG", "SIN"),
  Entropy = c(entropy_hkg, entropy_sin),
  Top3_Share = c(top3_share_hkg, top3_share_sin),
  Density = c(network_stats$Density[network_stats$Hub == "HKG"],
              network_stats$Density[network_stats$Hub == "SIN"])
)

summary_df
summary_long <- summary_df %>%
  pivot_longer(cols = -Hub, names_to = "Metric", values_to = "Value")
all_long <- bind_rows(network_long, summary_long)
ggplot(all_long, aes(x = Hub, y = Value, fill = Hub)) +
  geom_bar(stat = "identity") +
  facet_wrap(~ Metric, scales = "free_y") +
  labs(title = "Network & Market Structure Comparison: HKG vs SIN",
       x = "Hub",
       y = "Value") +
  theme_minimal() +
  theme(legend.position = "none")

##################
wb_step1 <- worldbank[-c(1:2), ]

header <- wb_step1[1, ]

colnames(wb_step1) <- as.character(header)

wb_clean <- wb_step1[-1, ]

colnames(wb_clean)
wb_clean <- wb_clean %>%
  rename(
    Country = `Country Name`,
    Country_Code = `Country Code`,
    Indicator_Name = `Indicator Name`,
    Indicator_Code = `Indicator Code`
  )


wb_long <- wb_clean %>%
  pivot_longer(
    cols = matches("^\\d{4}$"),
    names_to = "Year",
    values_to = "Value"
  ) %>%
  mutate(
    Year = as.numeric(Year),
    Value = as.numeric(Value)
  )


wb_air <- wb_long %>%
  filter(Indicator_Name == "Air transport, freight (million ton-km)")

wb_latest <- wb_air %>%
  filter(!is.na(Value)) %>%
  group_by(Country) %>%
  filter(Year == max(Year)) %>%
  ungroup() %>%
  select(Country, Value) %>%
  rename(air_freight = Value)

merge_data <- country_summary %>%
  left_join(wb_latest, by = "Country")


ggplot(merge_data, aes(x = total_flights, y = air_freight)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(
    title = "Air Connectivity vs Air Freight",
    x = "Total Flights (Network)",
    y = "Air Freight (World Bank)"
  )

correlation <- cor(merge_data$total_flights,
                   merge_data$air_freight,
                   use = "complete.obs")

correlation
# =========================
# 25. Network Robustness + Betweenness Analysis
# =========================


# -------------------------
# 25.1 Build Network
# -------------------------

g_full <- graph_from_data_frame(route_agg, directed = TRUE)
E(g_full)$weight <- route_agg$total_flights

# -------------------------
# 25.2 Basic Metrics Function
# -------------------------

calc_metrics <- function(g) {
  data.frame(
    nodes = vcount(g),
    edges = ecount(g),
    density = edge_density(g),
    avg_path = mean_distance(g, directed = TRUE),
    components = components(g)$no
  )
}

# -------------------------
# 25.3 Largest Component Ratio
# -------------------------

largest_component_ratio <- function(g) {
  comps <- components(g)
  max(comps$csize) / vcount(g)
}

# -------------------------
# 25.4 Baseline
# -------------------------

baseline <- calc_metrics(g_full)
baseline_lcc <- largest_component_ratio(g_full)

# -------------------------
# 25.5 Remove HKG
# -------------------------

g_no_hkg <- delete_vertices(g_full, "HKG")

hkg_removed <- calc_metrics(g_no_hkg)
hkg_lcc <- largest_component_ratio(g_no_hkg)

# -------------------------
# 25.6 Remove SIN
# -------------------------

g_no_sin <- delete_vertices(g_full, "SIN")

sin_removed <- calc_metrics(g_no_sin)
sin_lcc <- largest_component_ratio(g_no_sin)

# -------------------------
# 25.7 Combine Results
# -------------------------

robustness_df <- rbind(
  cbind(scenario = "Baseline", baseline, LCC = baseline_lcc),
  cbind(scenario = "Remove HKG", hkg_removed, LCC = hkg_lcc),
  cbind(scenario = "Remove SIN", sin_removed, LCC = sin_lcc)
)

print("=== Robustness Summary ===")
print(robustness_df)

# -------------------------
# 25.8 % Change Function
# -------------------------

calc_change <- function(base, new) {
  (new - base) / base * 100
}

change_hkg <- calc_change(baseline, hkg_removed)
change_sin <- calc_change(baseline, sin_removed)

change_df <- rbind(
  cbind(scenario = "HKG Removed", change_hkg),
  cbind(scenario = "SIN Removed", change_sin)
)

print("=== Percentage Change ===")
print(change_df)

# -------------------------
# 25.9 Betweenness Analysis
# -------------------------

message("Calculating betweenness (this may take time)...")

bet_before <- betweenness(g_full, weights = E(g_full)$weight)

bet_after_hkg <- betweenness(g_no_hkg, weights = E(g_no_hkg)$weight)

common_nodes <- intersect(names(bet_before), names(bet_after_hkg))

bet_diff <- data.frame(
  airport = common_nodes,
  before = bet_before[common_nodes],
  after = bet_after_hkg[common_nodes]
)

bet_diff <- bet_diff %>%
  mutate(change = after - before,
         pct_change = (after - before) / before * 100)

# -------------------------
# 25.10 Top Increased Importance
# -------------------------

top_increase <- bet_diff %>%
  arrange(desc(change)) %>%
  slice(1:15)

print("=== Top Airports Gaining Importance (After HKG Removal) ===")
print(top_increase)

# -------------------------
# 25.11 Visualization - Betweenness Change
# -------------------------

ggplot(top_increase, aes(x = reorder(airport, change), y = change)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "Top Airports Gaining Betweenness After HKG Removal",
    x = "Airport",
    y = "Betweenness Increase"
  ) +
  theme_minimal()

# -------------------------
# 25.12 Subnetwork Analysis (HKG Local Impact)
# -------------------------

hkg_neighbors <- unique(c(
  route_agg$Destination[route_agg$Source == "HKG"],
  route_agg$Source[route_agg$Destination == "HKG"]
))

sub_nodes <- unique(c("HKG", hkg_neighbors))

g_sub <- induced_subgraph(g_full, vids = sub_nodes)
g_sub_no_hkg <- delete_vertices(g_sub, "HKG")

sub_before <- calc_metrics(g_sub)
sub_after <- calc_metrics(g_sub_no_hkg)

sub_df <- rbind(
  cbind(scenario = "HKG Subnetwork", sub_before),
  cbind(scenario = "After Removing HKG", sub_after)
)

print("=== Local Subnetwork Impact ===")
print(sub_df)

# -------------------------
# 25.13 Visualization - Subnetwork Comparison
# -------------------------

sub_long <- sub_df %>%
  pivot_longer(cols = -scenario,
               names_to = "metric",
               values_to = "value")

ggplot(sub_long, aes(x = metric, y = value, fill = scenario)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(
    title = "Local Impact of Removing HKG (Subnetwork)",
    x = "Metric",
    y = "Value"
  ) +
  theme_minimal()
