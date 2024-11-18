---  create the database in aws athena

CREATE DATABASE CINEMA;



---- create the table wiht the files that are already load in the S3 


CREATE EXTERNAL TABLE IF NOT EXISTS bronze_cinema_ (
    TD string,
    YD string,
    `Release` string,
    Daily string,
    ev_YD string,
    ev_LW string,
    Theaters string,
    Avg string,
    to_date string,
    Days string,
    Distributor string,
    Title string,
    `Year` string,
    Rated string,
    Released string,
    Runtime string,
    Genre string,
    Director string,
    Writer string,
    Actors string,
    Plot string,
    `Language` string,
    Country string,
    Awards string,
    Poster string,
    Ratings string,
    Metascore string,
    imdbRating string,
    imdbVotes string,
    imdbID string,
    Type string,
    DVD string,
    BoxOffice string,
    Production string,
    Website string,
    Response string
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar' = '"',
    'escapeChar' = '\\'
)
STORED AS TEXTFILE
LOCATION 's3://cinemafreq/'
TBLPROPERTIES ('skip.header.line.count'='1');
