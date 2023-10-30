# Sonde_livestream_backup
This repo will grab sonde data from the South Fork site twice a day (8am and 8pm) and save it to a backup file

# Repo Structure

## Code
- `bi_daily_grab.R` grabs the data from the last 12 hours and then joins it to the archived dataset, then set this dataframe to the archived dataset. 
## Data
- The primary data file in this code is `SF_data_archive.csv`. This dataset is the WQ data collected at the South Fork of the Poudre River at the Pingree Bridge. This dataset is in long format and contains 15 min data for the following parameters: FDOM, chl-a, conductivity (specific and actual), temperature, DO and pH.
- The other csv file in this repo is `sfm_urls.csv`, this file contains the URLs and associated parameters for the WET API and is how we access the data to pull into this workflow. 
