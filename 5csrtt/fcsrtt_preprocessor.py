import os
import pandas as pd
import numpy as np
from tqdm import tqdm
from datetime import datetime, timedelta
from tkinter import Tk, filedialog
import sys
sys.path.append('../')
import helper_functions


def fcsrtt_data_cleaner(input_file_path, input_encoding="utf_16", input_sep=";", by_iti=False):
    """Performs data maipulation from the raw csv file. Transform data in a way
    that 1 row represents the single trial.

    Parameters
    ----------
    input_file_path : str
        Path to the csv file with the raw data.

    input_encoding : str
        Encoding of an input file.

    input_sep : str
        Delimiter to use for an input file.

    Returns
    ----------
    final_output : DataFrame
        Resulted DataFrame object.
    """

    # resulted data is encoded to 'utf_16', change if different
    try:
        input_df = pd.read_csv(input_file_path, encoding=input_encoding, sep=input_sep)
        len(input_df['DateTime']) # check whether the `sep` was chosen right
    except:
        # exit the function if the input file cannot be opened
        print("\nError while reading the input file. Change the `encoding` or `sep` parameters in the script.")
        return None

    # drop first rows from the data with the technical info
    input_df = input_df[~input_df['DateTime'].astype(str).apply(lambda x: x.startswith('#'))]
    # remove extra columns with additional information
    input_df = input_df.loc[:, :"MsgValue3"]

    # # sort the values since for some reason observations sometimes mixed in time
    # input_df['DateTime'] = input_df['DateTime'].astype(float)
    # input_df.sort_values(by='DateTime', inplace=True)
    # input_df.reset_index(drop=True, inplace=True)
    #
    # # some datetime manipulations
    # input_df['Timestamp'] = input_df['DateTime'].apply(lambda x: datetime.timestamp(from_ordinal(x)))
    # input_df['DateTime'] = input_df['Timestamp'].apply(lambda x: datetime.fromtimestamp(x))

    input_df = helper_functions.initial_cleaning(input_df)

    # select all possible animal IDs
    ids = input_df['IdLabel'][~input_df['IdLabel'].isnull()].unique()
    ids.sort()
    ids_dict = dict(input_df[['IdLabel','IdRFID']].drop_duplicates().dropna().values)

    # the final files templates
    final_output = pd.DataFrame({})
    final_iti_output = pd.DataFrame({})

    for animal_id in ids: # iterating over all animals

        print(f"\nGathering data for the animal {animal_id}...")

        # select the first session by the 'SystemMsg' variable
        # session = observations between 'start exp' and 'end exp'
        indices_start = input_df[(input_df['IdLabel'] == animal_id) & (input_df['SystemMsg'] == 'start exp')].index
        indices_end = input_df[(input_df['IdLabel'] == animal_id) & (input_df['SystemMsg'] == 'end exp')].index
        try:
            # check whether there are sessions for the animal
            indices_start[0]
            # check whether amount of 'start exp' equals to 'end exp'
            if len(indices_start) != len(indices_end):
                raise Exception
        except:
            # if either of the above conditions don't hold no further data
            # manipulations will be done with that animal
            print(f"No sessions were found for the animal {animal_id}.")
            continue

        for session_i in range(len(indices_start)): # iterating over all sessions
            # slice the session
            ind_start = indices_start[session_i]
            ind_end = indices_end[session_i]
            subj_data = input_df.iloc[ind_start:ind_end+1, :].reset_index(drop=True)

            # template for data of a single animal
            animal_out = pd.DataFrame({})

            # indeces of all trial start times
            trial_indx = subj_data['SystemMsg'][subj_data['SystemMsg'] == 'symbol to touch'].index

            for i in tqdm(range(len(trial_indx)), desc=f'Session {session_i+1}'): # iterating over all trials

                # trial = observations between 'symbol to touch' values
                # for the last trial it's from symbol to touch' to 'end exp'
                if i != len(trial_indx)-1:
                    trial_df = subj_data.iloc[trial_indx[i]:trial_indx[i+1],:]
                else:
                    trial_df = subj_data.iloc[trial_indx[i]:,:]

                # all possible outcomes
                outcome_list = trial_df['SystemMsg'].unique()
                # start of the trial
                trial_start = trial_df['DateTime'].to_list()[0]
                trial_start_ts = trial_df['Timestamp'].to_list()[0]
                trial_duration = trial_df['Timestamp'].to_list()[-1] - trial_start_ts

                # response time = time between 'incorrect'/'correct' and trial_start, in ms
                # reward_latency = time between 'positive' and 'correct', in ms
                response_time = np.NaN
                reward_latency = np.NaN

                if 'omission' in outcome_list:
                    outcome = 'omission'
                elif 'incorrect' in outcome_list:
                    outcome = 'incorrect'
                    response_time = trial_df[trial_df['SystemMsg'] == 'incorrect']['Timestamp'].values[0] - trial_start_ts
                elif 'correct' in outcome_list:
                    outcome = 'correct'
                    response_time = trial_df[trial_df['SystemMsg'] == 'correct']['Timestamp'].values[0] - trial_start_ts
                    try:
                        reward_latency = trial_df[trial_df['outLabel'] == 'positive']['Timestamp'].values[0] \
                        - trial_df[trial_df['SystemMsg'] == 'correct']['Timestamp'].values[0]
                    except:
                        # if the animal didn't get the reward rewardLatency will be -1
                        reward_latency = -1
                else:
                    outcome = 'undefined'

                # amount of premature events per trial
                if 'premature' in outcome_list:
                    premature_n = trial_df['SystemMsg'].value_counts()['premature']
                else:
                    premature_n = 0

                # the id of a stimulus and its duration (based on a raw data)
                stimulus = trial_df[trial_df['SystemMsg'] == 'symbol to touch']['MsgValue1']
                stim_time = trial_df[trial_df['SystemMsg'] == 'present time']['MsgValue1']

                if stimulus.empty:
                    stimulus = np.NaN
                else:
                    stimulus = stimulus.values[0]

                if stim_time.empty:
                    cndt = (subj_data['DateTime'] == trial_df['DateTime'][trial_df['SystemMsg'] == 'symbol to touch'].values[0])
                    stim_time = subj_data['MsgValue1'][cndt & (subj_data['SystemMsg'] == 'present time')].values[0]
                else:
                    stim_time = stim_time.values[0]

                animal_out = animal_out.append(
                    {'outcome': outcome, 'trialDuration': trial_duration,
                     'stimulus': stimulus, 'stimulusDuration': stim_time,
                     'trialStart': trial_start, 'nPremature': premature_n,
                     'responseLatency': response_time, 'rewardLatency': reward_latency,
                     'session': session_i+1
                    },
                    ignore_index=True)

            animal_out['trial'] = np.arange(1, len(animal_out)+1) # trial indeces
            animal_out['IdLabel'] = animal_id
            animal_out['IdRFID'] = animal_out['IdLabel'].apply(lambda x: ids_dict[x])
            animal_out = animal_out[['IdRFID', 'IdLabel', 'session', 'trial', 'trialStart', 'stimulus',
                                 'stimulusDuration', 'outcome', 'responseLatency', 'rewardLatency',
                                 'nPremature', 'trialDuration']]

            # rounding up some values to 3 digits after comma
            animal_out['responseLatency'] = animal_out['responseLatency'].apply(lambda x: np.round(x, 3))
            animal_out['rewardLatency'] = animal_out['rewardLatency'].apply(lambda x: np.round(x, 3))
            animal_out['trialDuration'] = animal_out['trialDuration'].apply(lambda x: np.round(x, 3))

            final_output = final_output.append(animal_out)

            iti_df = None

            if by_iti:
                iti_indx = subj_data['SystemMsg'][subj_data['SystemMsg'] == 'iti'].index

                subj_iti_out = pd.DataFrame({})

                for i in tqdm(range(len(iti_indx)), desc=f'Session {session_i+1} (by ITI)'):
                    # iterating over all ITI-trials
                    if i != len(iti_indx)-1:
                        iti_df = subj_data.iloc[iti_indx[i]:iti_indx[i+1],:]
                    else:
                        iti_df = subj_data.iloc[iti_indx[i]:,:]

                    iti_trial_df = pd.DataFrame({})
                    iti_trial_df['iti'] = [iti_df['MsgValue1'][iti_df['SystemMsg'] == 'iti'].values[0]]
                    iti_trial_df['nPremature'] = iti_df['SystemMsg'].to_list().count('premature')

                    subj_iti_out = subj_iti_out.append(iti_trial_df)

                if iti_df is not None:
                    subj_iti_out['trial'] = np.arange(1, len(subj_iti_out)+1) #iti  trial indeces
                    subj_iti_out['session'] = session_i+1
                    subj_iti_out['IdLabel'] = animal_id
                    subj_iti_out['IdRFID'] = subj_iti_out['IdLabel'].apply(lambda x: ids_dict[x])
                    subj_iti_out['sessionStart'] = iti_df['DateTime'].to_list()[0]


            if by_iti & (iti_df is not None):
                subj_iti_out = subj_iti_out[['IdRFID', 'IdLabel', 'session', 'sessionStart', 'trial', 'iti', 'nPremature']]
                final_iti_output = final_iti_output.append(subj_iti_out)

    final_output.sort_values(by=['IdLabel', 'session', 'trial'], inplace=True)
    final_output.insert(4, 'trialTotal', np.NaN)
    final_output.insert(5, 'trialByStimDuration', np.NaN)
    final_output['trialTotal'] = final_output.groupby('IdLabel').rank(method="first", ascending=True)
    final_output['trialByStimDuration'] = final_output.groupby(['IdLabel', 'stimulusDuration']).cumcount()+1

    clmns_to_cnvt = ['session', 'trial', 'trialTotal', 'trialByStimDuration', 'nPremature']
    final_output[clmns_to_cnvt] = final_output[clmns_to_cnvt].astype(int)

    if (by_iti) & (not final_iti_output.empty):
        final_iti_output.sort_values(by=['IdLabel', 'session', 'trial'], inplace=True)
        final_iti_output.insert(4, 'trialTotal', np.NaN)
        final_iti_output.insert(5, 'trialByITI', np.NaN)
        final_iti_output['trialTotal'] = final_iti_output.groupby('IdLabel').rank(method="first", ascending=True)
        final_iti_output['trialByITI'] = final_iti_output.groupby(['IdLabel', 'iti']).cumcount()+1
        final_iti_output.reset_index(drop=True, inplace=True)
        final_iti_output['iti'] = final_iti_output['iti'].astype(float)
        final_iti_output['trialTotal'] = final_iti_output['trialTotal'].astype(int)
        return final_output, final_iti_output
    else:
        return final_output, pd.DataFrame()


if __name__ == "__main__":

    # interactive selection of an input file and output folder
    # ooutput file will be saved with the current time in a name
    root = Tk()
    root.withdraw()
    input_file = filedialog.askopenfilename(title='Choose the input file')
    output_path = filedialog.askdirectory(title='Choose the directory for the output files')

    by_iti = True
#     by_iti = input('\nInclude preprocessing by ITI? [Y/n]: ')

#     while by_iti not in [True, False]:
#         if by_iti in ['y', 'Y', '']:
#             by_iti = True
#         elif by_iti in ['n', 'N']:
#             by_iti = False
#         else:
#             by_iti = input('Sorry, I didn\'t understand [Y/n]: ')

    # specification of an output file name
    output_name = input_file.split('/')[-1].replace(' ', '_').replace('.csv', '_PROCESSED.csv')
    output_iti_name = input_file.split('/')[-1].replace(' ', '_').replace('.csv', '_PROCESSED_ITI.csv')
    # name_change = input(f"Output file name will be {output_name}.\nEnter a new name to change it" +
    #     " or press [Enter] to skip.\n")
    # if name_change != '':
    #     output_name = name_change + '.csv'

    output_file = f"{output_path}/{output_name}"
    output_iti_file = f"{output_path}/{output_iti_name}"

    # if os.path.exists(output_file):
    #     rewrite_file = input("File already exists. "+
    #                          "Enter a new file name or press [Enter] to rewrite the existing file.\n")
    #     if rewrite_file != '':
    #         output_file = f"{output_path}/{rewrite_file}.csv"

    # just a fancy output of the file paths
    print("\n" + "="*40)
    print(f"INPUT FILE: {input_file}")
    print(f"OUTPUT FOLDER: {output_path}")
    print("="*40)

    if by_iti:
        final_output, final_iti_output = fcsrtt_data_cleaner(input_file_path=input_file, by_iti=by_iti)

        if not final_iti_output.empty:
            final_iti_output.to_csv(output_iti_file, index=False)
            print("\nOutput file by ITI was saved successfully!")
            print(f"File Path: {output_iti_file}")

    else:
        final_output = fcsrtt_data_cleaner(input_file_path=input_file, by_iti=by_iti)

    if not final_output.empty:
        final_output.to_csv(output_file, index=False)
        print("\nOutput file was saved successfully!")
        print(f"File Path: {output_file}")
