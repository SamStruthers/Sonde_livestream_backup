# Sonde_livestream_backup

This repo grabs sonde data from the South Fork site twice a day (8am and 8pm) and saves it to a backup file

# Repo Structure

## Code

-   `bi_daily_grab.R` grabs the data from the last 12 hours and then joins it to the archived dataset, then set this dataframe to the archived dataset.

## Data

-   The primary data file for this code are housed in the `data` folder.

-   This folder contains `SF_data_archive2024.csv` and `SF_data_archive2024.RDS`. These datasets are the WQ data collected at the South Fork of the Poudre River at the Pingree Bridge. This dataset is in long format and contains 15 min data for the following parameters: FDOM, chl-a, specific conductivity, turbidity, temperature, DO and pH.

-   Archived data from 2023 is housed in the `archive` folder. This data is in the same format as the primary data file.

-   The other csv file in this repo is `sfm_urls.csv`, this file contains the URLs for API access to the data to pulled in by this workflow.
