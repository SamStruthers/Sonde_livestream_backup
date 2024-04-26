library(shiny)
library(tidyverse)
library(httr)
library(rvest)
library(tidyr)
library(plotly)

`%nin%` = Negate(`%in%`)

# Define UI
ui <- fluidPage(
  titlePanel("South Fork at Pingree Road WQ"),
  sidebarLayout(
    sidebarPanel(
      textOutput("status"),
      downloadButton("downloadData", "Download Data")
    ),
    mainPanel(
      plotlyOutput("dataPlot")
    )
  )
)

# Define server
server <- function(input, output) {
  # Function to fetch data from the API
  getAPIdata <- function() {
    sfm_urls <- read_csv("sfm_urls.csv")
    
    # Function to process a single URL
    process_url <- function(url_site, data_type) {
      response <- httr::GET(url = url_site)
      response_content <- rawToChar(response$content)
      lines <- strsplit(response_content, "\n")[[1]]
      data_rows <- lines[16:(length(lines) - 4)]
      
      df <- data.frame(data = data_rows) %>%
        separate(data, into = c("Date", "Time", data_type, "Raw", "Alarm"), sep = "\\s+", remove = FALSE) %>%
        mutate(DT = as.POSIXct(paste(Date, Time, sep = " "), format = "%m/%d/%Y %H:%M"),
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
      filter(DT_round > as.POSIXct("2024-04-25 10:00:00", format = "%Y-%m-%d %H:%M:%S"))%>%
      #only display key parameters
      filter(Measurement %in% c("Depth", "pH", "Turbidity", "Specific_Conductivity", "FDOM", "DO", "Chl-a", "Temperature"))%>%
      mutate(w_units = case_when(
        Measurement == "Depth" ~ "Depth (ft)",
        Measurement == "pH" ~ "pH",
        Measurement == "Turbidity" ~ "Turbidity (NTU)",
        Measurement == "Specific_Conductivity" ~ "Spec Cond (uS/cm)",
        Measurement == "FDOM" ~ "FDOM (RFU)",
        Measurement == "DO" ~ "DO (mg/L)",
        Measurement == "Chl-a" ~ "Chl-a (RFU)",
        Measurement == "Temperature" ~ "Water Temp (C)"))
    return(SF_long_data)
  }
  
  # Display status message
  output$status <- renderText({
    "Click the 'Download Data' button to fetch and download data."
  })
  
  # Download data as CSV
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("SFork_data_up_to_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      df <- getAPIdata()
      write_csv(df, file)
    }
  )
  
  # Plot the data using Plotly
  output$dataPlot <- renderPlotly({
    df <- getAPIdata()
    
    p <- ggplot(df, aes(x = DT_round, y = Value)) +
      geom_line() +
      theme_bw() +
      facet_wrap(~w_units, scales = "free_y")
    
    ggplotly(p)
  })
}

# Run the Shiny app
shinyApp(ui, server)
