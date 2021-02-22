# Dashboard

RShiny Application for visualization the experiment results.

* [Requirements](#requirements)
* [Usage](#usage)
  * [Sidebar Panel](#sidebar-panel)

## Requirements

1. R (https://www.r-project.org/);
2. RStudio (https://rstudio.com/).

**List of packages used**:

* `shinythemes`
* `shiny`
* `tidyverse`
* `lubridate`
* `plotly`
* `DT`
* `plyr`

## Usage

1. Open `app.R` using RStudio;
2. Press "Run App" button and the pop-up application window will appear;
3. Plots and table outputs are divided by self-explanatory tabs.

### Sidebar Panel

1. `Choose Main File(s)` button is for the file input. File should be **prepossessed**, in .csv format and separated by comma. You can select multiple files at once. However, if two files have the same animal ID and session numbers, that will lead to problems.
2. `Choose File(s) with ITI's Data` is not supported at the moment.
3. `Accuracy Threshold` slider allows to choose threshold values for accuracy plots. Draws a horizontal red line throughout the plot and marks points green if they are above it, and red if they are under it.
4. `Trial by Stimulus Duration Window` are used for the plots by stimulus duration.
  1. `Upper Window` is the upper threshold of trial numbers you want to keep. The maximum possible value is calculated from the data. This value is the highest number of trials by an individual subject for any stimulus duration rounded up to the closest value that is divisible by 50. *For example, if the longest amount of trials is 322 (for some subject [x] for stimulus duration [y]), than maximum possible value will be 350.*
  2. `Lower Window` is the lower threshold of trial numbers you want to keep. Always is less than selected `Upper Window` by 50.
  3. For example, `Upper Window` = 300, `Lower Window` = 100. Trials that will be kept: 300-100 = 200. Meaning that for each trial you will sample only 200 trials starting with 101 and finishing with 300. Keep in mind, that not all subjects might have performed 300 trials for particular stimulus duration, that might result is different amount of trials for each subject (for example, 200, 143 and 65).
