* [5-CSRTT Data Preprocessor](#5-csrtt-data-preprocessor)
* [5-CSRTT Plot Generator](#5-csrtt-plot-generator)

# 5-CSRTT Data Preprocessor

Script for preprocessing the raw 5-CSRTT data from the system into the "analysis-friendly" format.

## Usage:

Terminal commands:

```bash
$ cd "path-to-the-script"
$ python fcsrtt_preprocessor.py
```

1. The first pop-up window will ask for the selection of the input file (the original csv file that comes from the system without any changes).

2. The second pop-up window will ask for the directory to save the resulted processed file. By default, the processed file will be called the same as the input file with a suffix "_PROCESSED".

3. If different ITIs were presented in the input file, script will return two files - main file with cleaned data and cleaned data by ITIs.

4. After setting up it up, the progress bars will appear for each subject ID. The message "`Output file was saved successfully!`" is an indicator that everything went right and the final file was saved. In a case of an error, please report.

## Overview of the Resulted File

The resulted file is a a csv file encoded using Unicode UTF-8 character set and separated by comma (`,`). Fields are:

* `IdRFID`;
* `IdLabel`;
* `session`: sessions count;
* `trial`: trials count by the session;
* `trial_total`: total trials count (disregarding the sessions);
* `trial_by_stimDur`: total trials count for a particular `stimulusDuration` value (disregarding the sessions);
* `trialStart`: time of the start of the trial;
* `stimulus`: presented stimulus window;
* `stimulusDuration`: duration of a stimulus, in milliseconds;
* `outcome`: the outcome of a trial. Possible values are `incorrect`, `correct`, `omission` and `undefined` (for the `undefined` definition refer to the [Notes](#notes) section);
* `responseLatency`: the time between the trial initialization and the window poking, in milliseconds. Only present for `correct` and `incorrect` outcomes;
* `rewardLatency`: time between the correct window poking and reward; collection, in milliseconds. Only present for `correct` outcomes. Some values can be "-1", refer to the [Notes](#notes) section for the clarification;
* `prematureNum`: amount of premature responses;
* `trialDuration`: duration of the trial, in milliseconds.

## Notes

* `undefined` outcome means that the session was ended after the trial initialization but before the decision making;
* `rewardLatency` = -1 means that the session was ended after the correct decision making but before the reward collection;
* in case when the file encoding or separating symbol were changed (by default file is encoded using UTF-16 set and separated by semicolon), you should change the arguments inside the `data_preprocessor.py` file, line 25: (`...input_encoding="utf_16", input_sep=";"...`).


# 5-CSRTT Plot Generator

Script for creating plots and aggregated csv files from prepossessed 5-CSRTT data.

## Usage:

Terminal commands:

```bash
$ cd "path-to-the-script"
$ python plot_generator.py
```

1. The first pop-up window will ask for the selection of the input file (should be **processed** file, not raw).

2. The second pop-up window will ask for the directory to save the resulted files. Two new folders (`csv`: folder for aggregated data and `jpg`: folder for plots) will be created in the selected directory.

3. The third pop-up window will ask for the `plot_parameters.json` file. Refer to the [Plot Parameters](#plot-parameters) section for clarification.

4. The message "`All data files were saved successfully!`" is an indicator that everything went right and the final files were saved. In a case of an error, please report.

## Plot Parameters

JSON file `plot_parameters.json` has 3 parameters that are used to create plots:

* `accuracy_threshold`: threshold value for the accuracy. Doesn't affect the calculations, just used for the horizontal line on accuracy plots;
* `min_trial_number`: lower number of trials to keep for the plots by stimulus duration.
* `max_trial_number`: upper number of trials to keep for the plots by stimulus duration. Note that both min and max values are included.

*This file have to be in the same folder as the script.*

## Overview of Resulted Files

`csv` folder consists of 3 files:

* `excluded_observations.csv`: observations, that had `outcome` = undefined or `responseLatency` = -1. Refer to the [Notes](https://github.com/ruslan-kl/5CSRTT-analysis/tree/master/data_preprocessor#notes) section of the Data Preprocessor documentation for clarification. These observations were excluded from the further analysis and plots;
* `totals_by_session.csv`: summary statistics for each session;
* `totals_by_stimulusDuration.csv`: summary statistics for each stimulus duration.

`jpg` folder consists of plots with self-explanatory names.
