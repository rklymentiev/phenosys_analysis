# 2VDLR Data Preprocessor

Script for preprocessing the raw 2VDLR data from the system into the "analysis-friendly" format.

## Usage:

Terminal commands:

```bash
$ cd "path-to-the-script"
$ python tvdlr_preprocessor.py
```

1. The first pop-up window will ask for the selection of the input file (the original csv file that comes from the system without any changes). Several files could be chosen at once.

2. The second pop-up window will ask for the directory to save the resulted processed file.

3. Type in the name of the resulted file (without ".csv") and press [Enter].

4. Animal IDs that are present in the `params.json` file (under the `animals_to_ignore`) will be ignored for cleaning.

## Overview of the Resulted File

The resulted file is a a csv file encoded using Unicode UTF-8 character set and separated by comma (`,`). Fields are:

* `fileName`: file name the observation was taken from;
* `IdRFID`;
* `IdLabel`;
* `session`: session count;
* `trial`: trials count by the session;
* `trialTotal`: total trials count (disregarding the sessions);
* `correctionTrial`: if trial was a correction trial (`TRUE`/`FALSE`)
* `trialStart`: time of the start of the trial;
* `trialDuration`: duration of the trial, in milliseconds;
* `stimulusCorrect`: label of the correct stimulus;
* `stimulusIncorrect`: label of the incorrect stimulus;
* `windowCorrect`: window that was correct;
* `windowPressed`: window that an animal pressed;
* `imagePressed`: image that an animal pressed;
* `outcome`: the outcome of a trial. Possible values are `incorrect`, `correct` and `undefined` (for the `undefined` definition refer to the [Notes](#notes) section);
* `startLatency`: time between the end of ITI and trial initialization;
* `responseLatency`: time between the trial initialization and the window poking.
* `rewardLatency`: time between the correct window poking and reward; collection, in seconds. Only present for `correct` outcomes. Some values can be "-1", refer to the [Notes](#notes) section for the clarification;
* `nPremature`: amount of premature responses (pokes before the end of iti);
* `nPreservative`: amount of preservative responses (window pokes without the trial initialization).


## Notes

* `undefined` outcome means that the session was ended after the trial initialization but before the decision making;
* `rewardLatency` = -1 means that the session was ended after the correct decision making but before the reward collection.
