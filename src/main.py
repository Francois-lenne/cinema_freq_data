# lambda_function.py
from boxoffice_api import BoxOffice 
import pandas as pd
import datetime as dt
import json
import s3fs
import boto3
from botocore.exceptions import ClientError

def get_secret(secret_name):
    """Retrieve secret from AWS Secrets Manager."""
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager'
    )
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e
    else:
        if 'SecretString' in get_secret_value_response:
            return json.loads(get_secret_value_response['SecretString'])

def get_previous_date(days: int = 2) -> str:
    """Get the date for n days before today."""
    return (dt.datetime.now() - dt.timedelta(days=days)).strftime('%Y-%m-%d')

def retrieve_dataframe_cinema_check_it(date:str) -> pd.DataFrame:
    """Retrieve cinema data and perform column checks."""
    try:
        # Get API key from Secrets Manager
        secrets = get_secret('cinema_key')
        api_key = secrets['cinema_key']
        print('API key retrieved from Secrets Manager')
    except Exception as e:
        print(f'Error retrieving API key: {str(e)}')
        raise
    
    try:
        box_office = BoxOffice(api_key=api_key, outputformat="DF")
    except Exception as e:
        print(f'Cannot access box office: {str(e)}')
        raise

    test_df = box_office.get_daily(date=date)
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
    else:
        print('not corresponding')
    
    test_df.rename(columns={
        '%± YD': 'ev_YD',
        '%± LW': 'ev_LW',
        'To Date': 'to_date'
    }, inplace=True)

    return test_df

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

def lambda_handler(event,context):
    """AWS Lambda handler function."""
    try:
        df = retrieve_dataframe_cinema_check_it(get_previous_date())
        success = save_to_s3(df, f's3://cinemafreq/box_office_{get_previous_date()}.csv')
        
        if success:
            return {
                'statusCode': 200,
                'body': json.dumps('Successfully processed cinema data')
            }
        else:
            return {
                'statusCode': 500,
                'body': json.dumps('Failed to save data to S3')
            }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }


if __name__ == '__main__':
    lambda_handler()