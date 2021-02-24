import sys
sys.path.append('../')
import json
import pandas as pd
import numpy as np
from tqdm import tqdm
from datetime import datetime, timedelta
from tkinter import Tk, filedialog
import helper_functions


def tvdlr_data_cleaner(input_file_paths, params, input_encoding="utf_16", input_sep=";"):
    # resulted data is encoded to 'utf_16', change if different
    input_df = pd.DataFrame({})
    for fpath in input_file_paths:
        try:
            df = pd.read_csv(fpath, encoding=input_encoding, sep=input_sep)
            len(df['DateTime']) # check whether the `sep` was chosen right

            # drop first rows from the data with the technical info
            df = df[~df['DateTime'].astype(str).apply(lambda x: x.startswith('#'))]
            # remove extra columns with additional information
            df = df.loc[:, :"MsgValue3"]
            df['fname'] = fpath.split('/')[-1]
            input_df = input_df.append(df)
        except:
            # exit the function if the input file cannot be opened
            print("\nError while reading the input file. Change the `encoding` or `sep` parameters in the script.")
            return None

    # sort the values since for some reason observations sometimes mixed in time
    input_df['DateTime'] = input_df['DateTime'].astype(float)
    input_df.sort_values(by=['fname', 'DateTime'], inplace=True)
    input_df.reset_index(drop=True, inplace=True)

    # some datetime manipulations
    input_df['Timestamp'] = input_df['DateTime'].apply(
        lambda x: datetime.timestamp(helper_functions.from_ordinal(x)))
    input_df['DateTime'] = input_df['Timestamp'].apply(
        lambda x: datetime.fromtimestamp(x))

    # select all possible animal IDs
    ids = input_df['IdLabel'][~input_df['IdLabel'].isnull()].unique()
    ids.sort()
    ids_dict = dict(input_df[['IdLabel','IdRFID']].drop_duplicates().dropna().values)

    # the final files templates
    final_output = pd.DataFrame({})

    for animal_id in ids: # iterating over all animals
        if animal_id in params['animals_to_ignore']:
            print(f"\nAnimal {animal_id} is ignored.")
            continue

        print(f"\nGathering data for the animal {animal_id}...")

        # select the first session by the 'SystemMsg' variable
        # session = observations between 'start exp' and 'end exp'
        indices_start = input_df[(input_df['IdLabel'] == animal_id) & (input_df['SystemMsg'] == 'start exp')].index
        indices_end = input_df[(input_df['IdLabel'] == animal_id) & (input_df['SystemMsg'] == 'end exp')].index

        try:
            # check whether there are sessions for the animal
            indices_start[0]
            # check whether amount of 'start exp' equals to 'end exp'
            # if len(indices_start) != len(indices_end):
            #     raise Exception
        except:
            # if either of the above conditions don't hold no further data
            # manipulations will be done with that animal
            print(f"No sessions were found for the animal {animal_id}.")
            continue

        for session_i in range(len(indices_start)): # iterating over all sessions
            ind_start = indices_start[session_i]
            try:
                ind_end = indices_end[session_i]
                session_df = input_df.iloc[ind_start:ind_end+1, :].reset_index(drop=True)
            except:
                continue

            # trials start with the 'wait poke' system message
            trial_indx = session_df['SystemMsg'][session_df['SystemMsg'] == 'wait poke'].index

            animal_out = pd.DataFrame({})

            for i in tqdm(range(len(trial_indx)), desc=f'Session {session_i+1}'): # iterating over all trials
                if i != len(trial_indx)-1:
                    trial_df = session_df.iloc[trial_indx[i]:trial_indx[i+1],:]
                else:
                    trial_df = session_df.iloc[trial_indx[i]:,:]

                trial_start = trial_df['DateTime'].to_list()[0]
                trial_start_ts = trial_df['Timestamp'].to_list()[0]
                trial_duration = trial_df['Timestamp'].to_list()[-1] - trial_start_ts

                # check if animal initialized the stimulus presentation
                mask = trial_df['SystemMsg'].apply(lambda x: x.startswith('start run') if type(x) == str else False)
                if True in mask.unique():
                    poke_time = trial_df[mask]['Timestamp'].values[0]
                    stim_correct = trial_df[mask]['MsgValue1'].values[0]
                    stim_incorrect = trial_df[mask]['MsgValue2'].values[0]
                    start_latency = poke_time - trial_start_ts

                    if 'cr' in trial_df['MsgValue3'].unique(): # check if a correction trial
                        correction_trial = 1
                    else:
                        correction_trial = 0

                    # premature number - amount of pokes before the end of iti
                    n_premature = trial_df['unitLabel'][trial_df['Timestamp'] < poke_time]
                    n_premature = n_premature.apply(lambda x: x.startswith('W')).sum()

                else:
                    poke_time = np.NaN
                    stim_correct = ''
                    stim_incorrect = ''
                    start_latency = np.NaN
                    correction_trial = np.NaN
                    n_premature = 0


                if stim_correct.find('+') == 2:
                    window_correct = int(stim_correct.split(' ')[1][1])
                elif stim_incorrect.find('+') == 2:
                    window_correct = int(stim_incorrect.split(' ')[1][1])
                else:
                    window_correct = np.NaN

                # check if mice made a decision
                mask = (trial_df['unitLabel'].apply(lambda x: x.startswith('W'))) \
                    & (trial_df['Timestamp'] > poke_time)
                decision = trial_df[mask].head(1)

                if len(decision) != 0:
                    window_pressed = int(decision['unitLabel'].values[0][1])
                    response_latency = decision['Timestamp'].values[0] - poke_time
                    if window_pressed == window_correct:
                        outcome = "correct"
                        if 'positive' in trial_df['outLabel'].unique():
                            reward_latency = trial_df[trial_df['outLabel'] == 'positive']['Timestamp'].values[0] \
                            - decision['Timestamp'].values[0]
                        else:
                            outcome = 'undefined'
                            reward_latency = -1
                    else:
                        outcome = "incorrect"
                        reward_latency = np.NaN

                    if window_pressed == int(stim_correct[5]):
                        img_pressed = int(stim_correct[-1])
                    elif window_pressed == int(stim_incorrect[5]):
                        img_pressed = int(stim_incorrect[-1])
                    else:
                        img_pressed = np.NaN

                    n_preservative = trial_df['unitLabel'][trial_df['Timestamp'] > poke_time]
                    n_preservative = n_preservative.apply(lambda x: x.startswith('W')).sum() - 1

                    # if (outcome == "correct") & ('positive' in trial_df['outLabel'].unique()):
                    #
                    # else:
                    #     # outcome = "undefined"
                    #     reward_latency = -1

                else:
                    outcome = "undefined"
                    window_pressed = np.NaN
                    response_latency = np.NaN
                    img_pressed = np.NaN
                    n_preservative = 0



                animal_out = animal_out.append(
                    {'session': session_i+1, 'trialStart': trial_start,
                     'trialDuration': trial_duration,
                     'correctionTrial': correction_trial, 'imagePressed': img_pressed,
                     'stimulusCorrect': stim_correct, 'stimulusIncorrect': stim_incorrect,
                     'windowCorrect': window_correct, 'windowPressed': window_pressed,
                     'outcome': outcome, 'responseLatency': response_latency,
                     'rewardLatency': reward_latency, 'startLatency': start_latency,
                     'nPremature': n_premature, 'nPreservative': n_preservative
                    },
                    ignore_index=True)

            animal_out['trial'] = np.arange(1, len(animal_out)+1) # trial indeces
            animal_out['IdLabel'] = animal_id
            animal_out['fileName'] = session_df['fname'][session_df['IdLabel'] == animal_id].values[0]

            final_output = final_output.append(animal_out)

    final_output['IdRFID'] = final_output['IdLabel'].apply(lambda x: ids_dict[x])
    final_output.sort_values(by=['IdLabel', 'session', 'trial'], inplace=True)
    final_output['trialTotal'] = final_output.groupby('IdLabel').cumcount()+1

    final_output['correctionTrial'] = final_output['correctionTrial'].apply(
        lambda x: np.NaN if np.isnan(x) else bool(x))
    final_output['windowCorrect'] = final_output['windowCorrect'].apply(
        lambda x: np.NaN if np.isnan(x) else int(x))

    clmns = ['session', 'nPremature', 'nPreservative']
    final_output[clmns] = final_output[clmns].astype(int)

    clmns = ['responseLatency', 'rewardLatency', 'startLatency', 'trialDuration']
    final_output[clmns] = final_output[clmns].round(2)

    final_output = final_output[['fileName','IdRFID', 'IdLabel', 'session', 'trial', 'trialTotal', 'correctionTrial',
                                 'trialStart', 'trialDuration', 'stimulusCorrect', 'stimulusIncorrect',
                                 'windowCorrect', 'windowPressed', 'imagePressed', 'outcome', 'startLatency',
                                 'responseLatency', 'rewardLatency', 'nPremature', 'nPreservative']]

    return final_output



if __name__ == "__main__":

    # interactive selection of an input file and output folder
    # ooutput file will be saved with the current time in a name
    root = Tk()
    root.withdraw()
    input_files = filedialog.askopenfilenames(title='Choose the input files')
    output_path = filedialog.askdirectory(title='Choose the directory for the output files')

    # specification of an output file name
    output_name = ''
    while output_name == '':
        output_name = input('Enter the output file name: ')

    output_file = f"{output_path}/{output_name}.csv"

    try:
        with open("2vdlr/params.json", "r") as f:
            params = json.load(f)
    except:
        with open("params.json", "r") as f:
            params = json.load(f)
    else:
        print("No parameters file found. Using default values.")
        params = {'animals_to_ignore': []}


    final_output = tvdlr_data_cleaner(input_file_paths=input_files, params=params)

    if not final_output.empty:
        final_output.to_csv(output_file, index=False)
        print("\nOutput file was saved successfully!")
