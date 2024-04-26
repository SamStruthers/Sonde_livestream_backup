library(tidyverse)
library(httr)
library(rvest)
library(tidyr)


#Set ENVIRO timezone
#?Sys.setlocale()

`%nin%` = Negate(`%in%`)

  getnewdata <- function() {
    sfm_urls <- read_csv("data/sfm_urls.csv", show_col_types = FALSE)
    # 48 samples is 12 hours of data
    
    # Function to process a single URL
    process_url <- function(url_site, data_type) {
      response <- httr::GET(url = url_site)
      response_content <- rawToChar(response$content)
      lines <- strsplit(response_content, "\n")[[1]]
      data_rows <- lines[16:(length(lines) - 4)]
      
      df <- data.frame(data = data_rows) %>%
        separate(data, into = c("Date", "Time", data_type, "Raw", "Alarm"), sep = "\\s+", remove = FALSE) %>%
        mutate(DT = as.POSIXct(paste(Date, Time, sep = " "), tz = "America/Denver", format = "%m/%d/%Y %H:%M"),
               DT_round = floor_date(DT, "15 minutes")) %>%
        select(-c(Date, Time, data, Raw, Alarm, DT))
      
      return(df)
    }
    
    # map process_url over each row in sfm_urls
    SF_data_list <- map2(sfm_urls$site_url, sfm_urls$data_type, process_url)
    
    # Merge the data frames in the list into a single data frame
    SF_data <- reduce(SF_data_list, left_join, by = "DT_round")
    
    #pivot to longer after joining all datasets
    SF_long_data <- SF_data %>%
      pivot_longer( cols = -DT_round, names_to = "Measurement", values_to = "Value" )%>%
      #make numeric
      mutate(Value = as.numeric(Value))%>%
      #remove all -9999 values
      filter(Value %nin% c(-9999, 638.30))%>%
      #filter for deployed date
      filter(DT_round > as.POSIXct("2024-04-25 10:00:00", format = "%Y-%m-%d %H:%M:%S"))
    
    return(SF_long_data)
  }

  #grab data from the last 12 hours
new_data <- getnewdata()


#grab archived dataset 
old_data <- read_csv("data/SF_data_archive2024.csv")%>%
  mutate(DT_round = with_tz(DT_round, tzone = "America/Denver"))

#join archive dataset with new dataset
all_data <- rbind(old_data, new_data)%>%
  dplyr::distinct()



#write to CSV and RDS 
write_csv(all_data, "data/SF_data_archive2024.csv")
saveRDS(all_data, file = "data/SF_data_archive2024.RDS")
