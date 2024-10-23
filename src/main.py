from boxoffice_api import BoxOffice 
import pandas as pd
import datetime as dt
from dotenv import load_dotenv
import os
import s3fs



# defined the date for the retrieving date
def get_previous_date(days: int = 2) -> str:
        """Get the date for n days before today."""
        return (dt.datetime.now() - dt.timedelta(days=days)).strftime('%Y-%m-%d')


# retrieve the dataframe from the cinema API and check if the columns are the same

def retrieve_dataframe_cinema_check_it(date:str) -> pd.DataFrame:

    load_dotenv()  # Load environment variables from .env file
    try:
        os.getenv('cinema_key')
        print('API key found')
    except:
        print('no API key found')
    
    try :

        box_office = BoxOffice(api_key=os.getenv('cinema_key'), outputformat="DF") # Get daily box office information for a specific date

    except:
        print('can t access to the box office please check your API key')


    test_df = box_office.get_daily(date = date)

    print(test_df)


    list_columns = ['TD', 'YD', 'Release', 'Daily', '%± YD', '%± LW', 'Theaters', 'Avg',
        'To Date', 'Days', 'Distributor', 'Title', 'Year', 'Rated', 'Released',
        'Runtime', 'Genre', 'Director', 'Writer', 'Actors', 'Plot', 'Language',
        'Country', 'Awards', 'Poster', 'Ratings', 'Metascore', 'imdbRating',
        'imdbVotes', 'imdbID', 'Type', 'DVD', 'BoxOffice', 'Production',
        'Website', 'Response', 'Error', 'totalSeasons']

    column_list = test_df.columns.tolist()



    if list_columns == column_list:
        print('columns corresponds')

    else :
        print('not corresponding')

    
    test_df.rename(columns={
        '%± YD': 'ev_YD',
        '%± LW': 'ev_LW',
        'To Date' : 'to_date'
    }, inplace=True)

    return test_df

df_cinema = retrieve_dataframe_cinema_check_it(get_previous_date())



# load to S3
def save_to_s3(df: pd.DataFrame, s3_path: str) -> bool:
        """Save DataFrame to S3 as CSV."""
        try:
            fs = s3fs.S3FileSystem()
            with fs.open(s3_path, 'w') as f:
                df.to_csv(f, index=False)
            print(f'DataFrame successfully saved to {s3_path}')
            return True
        except Exception as e:
            print(f"Error saving to S3: {str(e)}")
            return False


# save the csv file into the S3 bucket cinema-freq
save_to_s3(df_cinema, f's3://cinemafreq/box_office_{get_previous_date()}.csv')