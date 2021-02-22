import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import json
from tkinter import Tk, filedialog
from functools import partial
from tqdm import tqdm

plt.switch_backend('agg')


def boxplot_totals(data, x, y, path=None, xname=None, yname=None,
                   add_hline=False, show=False, uniform_color=False,
                   by_session=True):
    """Boxplot function

    Parameters
    ----------
    data : pandas.DataFrame
        Data used for plots.

    x : str
        Name of the column used for the x axis.

    y: str
        Name of the column used for the y axis.

    path : str
        Path for the output plots.

    xname : str
        Custom name for the x axis. The default is `None`; if not provided,
        then name will be taken from the column name, replacing underscores
        by spaces and capitalizing the first letters. For example,
        "time_variable" -> "Time Variable"

    yname : str
        The same idea as for the xname argument.

    add_hline : bool, float or int
        Default value is `False`, meaning that no horizontal line will be added
        to the plot. In order to add it, set argument to the desired numerical value.

    show : bool
        Whether to show the plots on the screen. Default is `False`.

    uniform_color : bool
        Default if `False`, meaning that all boxplots will be drawn in the same color.
        If `True`, color for each boxplot will be different.

    by_session : bool
        Whether plot represents data from all sessions by each subject.
        Affects only output file name. Default if `True`.
        When `False`, data is aggregated from all Stimulus Durations by each subject.

    """
    # set the suffix of the output file name
    if x == 'IdLabel':
        if by_session:
            suffix = 'by IDs (all Sessions)'
        else:
            suffix = 'by IDs (all Stimulus Durations)'
    elif x == 'stimulusDuration':
        suffix = 'by Stimulus Duration (all IDs)'
    else:
        suffix = 'by Session (all IDs)'

    if xname == None:
        xname = x.replace('_', ' ').title()

    if yname == None:
        yname = y.replace('_', ' ').title()

    if add_hline:
        plt.axhline(y=add_hline, color='red', linestyle='--', linewidth=1, alpha=.5)

    if uniform_color:
        color = "skyblue"
    else:
        color = None

    sns.boxplot(data=data, x=x, y=y, color=color)
    sns.stripplot(data=data, x=x, y=y, color=color, linewidth=3)
    plt.xlabel(xname)
    plt.ylabel(yname)
    plt.title(f"{yname} {suffix}")
    plt.savefig(f"{path}/{yname.lower().replace(' ', '_')}_{suffix.lower().replace(' ', '_')}.jpg")

    if show:
        plt.show()
    plt.close()


def relplot(data, x, y, path=None, xname=None, yname=None,
            add_yline=False, by_phase=False, show=False, ylim=None):

    if by_phase:
        height, aspect = (2, 4)
        col = "phase"
        fname_suffix = f"{x}_and_phase"
    else:
        height, aspect = (2, 8)
        col = None
        fname_suffix = x

    if xname == None:
        xname = x.replace('_', ' ').title()

    if yname == None:
        yname = y.replace('_', ' ').title()

    img = sns.relplot(
        data=data, x=x, y=y, row="IdLabel",
        hue="IdLabel", marker="o",  markersize=12, col=col,
        kind="line", height=height, aspect=aspect, legend=False)

    if add_yline:
        try:
            for ax in img.axes[:,0]:
                ax.axhline(y=add_yline, color='red', linestyle='--', linewidth=1, alpha=.7)
            if by_phase:
                for ax in img.axes[:,1]:
                    ax.axhline(y=add_yline, color='red', linestyle='--', linewidth=1, alpha=.7)
        except:
            pass

#     img.set(ylabel=f"{y}")
    if ylim:
        img.set(ylim=ylim)

    img.set(xticks=data[x].unique())
    img.fig.suptitle(f"{yname} by {xname}", y=1.02, fontsize=20)
    img.savefig(f"{path}/{yname.lower().replace(' ', '_')}_by_{fname_suffix}.jpg")

    if show:
        plt.show()
    plt.close()


def aggregated_table(df, by1='IdLabel', by2='session', by_phase=False):
    """

    """

    agg_df = df.groupby(by=[by1, by2, 'outcome'], as_index=False)[['trial']].count()
    agg_df = pd.pivot_table(data=agg_df, index=[by1, by2], columns='outcome',
                            values='trial', aggfunc='sum')
    agg_df.reset_index(drop=False, inplace=True)
    agg_df.rename_axis('', axis='columns', inplace=True)

    if by_phase:
        agg_df = pd.merge(left=agg_df,
                          right=df[[by1, 'session',
                                    'session_start', 'phase']].drop_duplicates(),
                          on=[by1, 'session'])

        col =  agg_df.pop("session_start")
        agg_df.insert(2, col.name, col)
        col =  agg_df.pop("phase")
        agg_df.insert(3, col.name, col)

    agg_df[["correct", "incorrect", "omission"]] = agg_df[["correct", "incorrect", "omission"]].fillna(0).astype(int)

    agg_df['trial_count'] = agg_df['correct'] + agg_df['incorrect'] + agg_df['omission']
    agg_df['total_count_wo_omit'] = agg_df['correct'] + agg_df['incorrect']

    agg_df = pd.merge(left=agg_df,
                      right=df.groupby(by=[by1, by2],
                                       as_index=False)[['nPremature']].sum(),
                      on=[by1, by2])

    agg_df['accuracy'] = agg_df['correct'] * 100 / agg_df['total_count_wo_omit']
    agg_df['omit_ratio'] = agg_df['omission'] * 100 / agg_df['trial_count']
    agg_df['premature_ratio'] = agg_df['nPremature'] * 100 / (agg_df['nPremature'] + agg_df['trial_count'])
    agg_df[['accuracy', 'omit_ratio', 'premature_ratio']] = agg_df[['accuracy', 'omit_ratio', 'premature_ratio']].round(2)

    # latencies
    latencies_df = df.groupby(
        by=[by1, by2, 'outcome'],
        as_index=False)
    latencies_df = latencies_df[['responseLatency', 'rewardLatency']].mean()
    latencies_df = pd.pivot_table(data=latencies_df, index=[by1, by2], columns='outcome',
                                  values=['responseLatency','rewardLatency'], aggfunc='sum')
    latencies_df.reset_index(drop=False, inplace=True)
    latencies_df.columns = ['_'.join(col) for col in latencies_df.columns]
    latencies_df.rename(columns={by1+'_': by1,
                                 by2+'_': by2,
                                 'responseLatency_correct': 'correct_latency',
                                 'responseLatency_incorrect': 'incorrect_latency',
                                 'rewardLatency_correct': 'reward_latency'},
                        inplace=True)
#     latencies_df = latencies_df[[by1, by2, 'correct_latency', 'incorrect_latency', 'reward_latency']].fillna(0)

    agg_df = pd.merge(left=agg_df.round(3),
                      right=latencies_df.round(3),
                      on=[by1, by2])


    return agg_df


if __name__ == '__main__':

    view_params = {'legend.fontsize': 'large',
                   'figure.figsize': (15, 5),
                   'axes.labelsize': 'large',
                   'axes.labelweight': 'bold',
                   'axes.titlesize':'x-large',
                   'axes.titleweight': 'bold',
                   'xtick.labelsize':'large',
                   'ytick.labelsize':'large'}
    plt.rcParams.update(view_params)
    sns.set_style("whitegrid")

    root = Tk()
    root.withdraw()
    input_file = filedialog.askopenfilename(title='Choose the input file')
    output_path = filedialog.askdirectory(title='Choose the folder for output files')

    if os.path.exists('plot_parameters.json'):
        with open("plot_parameters.json", 'r') as f:
            params = json.load(f)
    elif os.path.exists('plot_generator/plot_parameters.json'):
        with open("plot_generator/plot_parameters.json", 'r') as f:
            params = json.load(f)
    else:
        params = {"accuracy_threshold": 80,
                  "min_trial_number": 0,
                  "max_trial_number": 50
                 }
        print("File with plot parameters wasn't found. Using default values.")

    JPG_PATH = os.path.join(output_path, "jpg")
    CSV_PATH = os.path.join(output_path, "csv")

    relplot = partial(relplot, path=JPG_PATH)
    boxplot_totals = partial(boxplot_totals, path=JPG_PATH)

    try:
        os.mkdir(JPG_PATH)
    except FileExistsError:
        pass

    try:
        os.mkdir(CSV_PATH)
    except FileExistsError:
        pass

    # data load
    print("Loading the data...")
    experiment_df = pd.read_csv(input_file)
    experiment_df['trialStart'] = pd.to_datetime(experiment_df['trialStart'])
    experiment_df[['session', 'nPremature']] = experiment_df[['session', 'nPremature']].astype(int)
    print("Done")

    # exclude observations
    excld_df = experiment_df[(experiment_df['outcome'] == 'undefined') | (experiment_df['rewardLatency'] == -1)]
    excld_df.to_csv(f"{CSV_PATH}/excluded_observations.csv", index=False)
    experiment_df = experiment_df[~((experiment_df['outcome'] == 'undefined') | (experiment_df['rewardLatency'] == -1))]
    experiment_df.reset_index(drop=True, inplace=True)

    # add start time to each session
    session_phase_df = experiment_df.groupby(by=['IdLabel', 'session'], as_index=False)[['trialStart']].min()
    session_phase_df.rename(columns={'trialStart': 'session_start'}, inplace=True)
    session_phase_df['phase'] = session_phase_df['session_start'].apply(
        lambda x: "light" if (x.hour >= 6) & (x.hour < 18) else "dark")

    experiment_df = pd.merge(
        left=experiment_df,
        right=session_phase_df,
        on=['IdLabel','session'])

    ################
    ## BY SESSION ##
    ################

    print("Creating plots by sessions...")
    totals_by_session = aggregated_table(df=experiment_df, by1='IdLabel', by2='session', by_phase=True)
    totals_by_session.to_csv(f"{CSV_PATH}/totals_by_session.csv", index=False)

    metrics = ['accuracy', 'omit_ratio', 'premature_ratio',
               'correct_latency', 'incorrect_latency', 'reward_latency']

    for metric in tqdm(metrics):

        if metric == 'accuracy':
            add_yline = params['accuracy_threshold']
        else:
            add_yline = False

        relplot(data=totals_by_session, add_yline=add_yline,
                x='session', y=metric)

        relplot(data=totals_by_session, x='session', y=metric,
                by_phase=True, add_yline=add_yline)

        boxplot_totals(data=totals_by_session, add_hline=add_yline,
                       x='session', y=metric, uniform_color=True)

        boxplot_totals(data=totals_by_session, add_hline=add_yline,
                       x='IdLabel', y=metric, uniform_color=False)

    ##########################
    ## BY STIMULUS DURATION ##
    ##########################

    print("Creating plots by the stimulus duration...")

    sample_df_by_trials = experiment_df[experiment_df['trialByStimDuration'].between(params['min_trial_number'],
                                                                                  params['max_trial_number'])]
    # sample_df_by_trials = experiment_df.groupby(by=['IdLabel', 'stimulusDuration'],
    #                                             as_index=False).head(params['trials_to_keep'])

    totals_by_stimulusDuration = aggregated_table(
        df=sample_df_by_trials,
        by1='IdLabel',
        by2='stimulusDuration')

    totals_by_stimulusDuration.to_csv(f"{CSV_PATH}/totals_by_stimulusDuration.csv", index=False)

    for metric in tqdm(metrics):

        if metric == 'accuracy':
            add_yline = params['accuracy_threshold']
        else:
            add_yline = False

        relplot(data=totals_by_stimulusDuration, x='stimulusDuration', y=metric,
                xname='Stimulus Duration', add_yline=add_yline)

        boxplot_totals(data=totals_by_stimulusDuration, add_hline=add_yline,
                       x='stimulusDuration', xname='Stimulus Duration', y=metric,
                       uniform_color=True, by_session=False)

        boxplot_totals(data=totals_by_stimulusDuration, add_hline=add_yline,
                       x='IdLabel', y=metric, uniform_color=False, by_session=False)

    print("All data files were saved successfully!")
