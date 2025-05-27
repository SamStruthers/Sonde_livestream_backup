# Prep for API data in QAQC system

# Load libraries
library(tidyverse)

SF_data_archive2024 <- readRDS("~/Documents/fork_yeah/Sonde_livestream_backup/data/SF_data_archive2024.RDS")
SF_data_archive2023 <- readRDS("~/Documents/fork_yeah/Sonde_livestream_backup/data/archive/SF_data_archive2023.RDS")


all_data <- bind_rows(SF_data_archive2023, SF_data_archive2024)

#make a plot
all_data %>%
  ggplot(aes(x = DT, y = Value)) +
  geom_point() +
  theme_minimal()+
  facet_wrap(~Measurement, scales = "free_y") 


#import hydrovu data for comparison
hydro_vu <- read_csv("~/Documents/fork_yeah/Sonde_livestream_backup/data/archive/SFM_2024-11-15_1010.csv")%>%
  mutate(DT = with_tz(timestamp, tzone = "MST"))

# get the parameter and unit combinations
unit_cor <- hydro_vu %>%
  select(parameter, units) %>%
  distinct()%>%
  mutate(Measurement = case_when(parameter == "% Saturation O₂" ~ "DO_Sat", 
                                 parameter == "Specific Conductivity" ~ "Specific_Conductivity",
                                 parameter == "Chl-a Fluorescence" ~ "Chl-a", 
                                 parameter == "Turbidity" ~ "Turbidity",
                                 parameter == "pH" ~ "pH",
                                 parameter == "DO" ~ "DO",
                                 parameter == "Depth" ~ "Depth",
                                 parameter == "Temperature" ~ "Temperature",
                                 parameter == "FDOM Fluorescence" ~ "FDOM"))%>%
  na.omit()


all_data_cleaned <- all_data%>%
  left_join(unit_cor, by = "Measurement")%>%
  mutate(site = "sfm", 
         name = "sfm - south fork at pingree rd", 
         id = 4645620000000001, 
         value = case_when(parameter == "Depth" ~ Value * 0.3048, 
                           TRUE ~ Value), 
         timestamp = format(with_tz(DT, tzone = "UTC"), "%Y-%m-%dT%H:%M:%SZ"))%>%
  select(site, id, name, timestamp, parameter, value, units)


write_csv(all_data_cleaned, "~/Documents/fork_yeah/Sonde_livestream_backup/data/archive/SFM_2024-12-10_1430.csv")

all_data_cleaned %>%
  filter(year(DT) == 2024)%>%
  ggplot(aes(x = DT, y = value)) +
  geom_point(color = "blue") +
  geom_point(data = hydro_vu%>%filter(parameter %in% unique(all_data_cleaned$parameter) & year(DT) == 2024), aes(x = DT, y = value), color = "grey", alpha = 0.5)+
  theme_minimal()+
  facet_wrap(~parameter, scales = "free_y") 


