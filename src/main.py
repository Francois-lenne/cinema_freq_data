from boxoffice_api import BoxOffice 
import pandas as pd
import datetime as dt
from dotenv import load_dotenv
import os




# Get the date of the day before

day_before = (dt.datetime.now() - dt.timedelta(days=1)).strftime('%Y-%m-%d')



print(day_before)


print('test box office api')


def retrieve_dataframe_cinema_check_it(date:str) -> pd.DataFrame:

    load_dotenv()  # Load environment variables from .env file
    try:
        os.getenv('cinema_key')
    except:
        print('no API key found')
    
    try :

        box_office = BoxOffice(api_key=os.getenv('cinema_key'), outputformat="DF") # Get daily box office information for a specific date 

    except:
        print('can t access to the box office please check your API key')


    test_df = box_office.get_daily(date)


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

df = retrieve_dataframe_cinema_check_it(day_before)



