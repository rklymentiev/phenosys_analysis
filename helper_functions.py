import pandas as pd
from datetime import datetime, timedelta


def from_ordinal(ordinal, _epoch=datetime(1899, 12, 30)):
    """Converts serial date-time to DateTime object.

    Parameters
    ----------
    ordinal : float or int
        Original serial date-time.

    _epoch : datetime
        Start of the count.
        NOTE: for some reason timestamp is shifted by 2 days
        backwards from 01-01-1900, that is why default value
        is set to 30-12-1899.
    """
    return _epoch + timedelta(days=ordinal)


def initial_cleaning(input_df):
    # sort the values since for some reason observations sometimes mixed in time
    input_df['DateTime'] = input_df['DateTime'].astype(float)
    input_df.sort_values(by='DateTime', inplace=True)
    input_df.reset_index(drop=True, inplace=True)

    # some datetime manipulations
    input_df['Timestamp'] = input_df['DateTime'].apply(lambda x: datetime.timestamp(from_ordinal(x)))
    input_df['DateTime'] = input_df['Timestamp'].apply(lambda x: datetime.fromtimestamp(x))

    return input_df
