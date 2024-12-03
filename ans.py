import requests
import pandas as pd
import os
import certifi
import pyodbc

API_KEY = '76d348d960b6ab75912301b307ab9f57ed82a3b8'

#acs 5 year survey link
BASE_URL = "https://api.census.gov/data/2022/acs/acs5"

GET_VARS = [
    "NAME", #geographic name
    "GEO_ID", #geographic ID
    "B01001_001E", #total pop
    "B01001_002E", #total male pop
    "B01001_026E" #total female pop
]

STATE = "12" #florida
COUNTY = "095" #orange county

GEO = "block group:*" #all block groups

params = {
    "get": ",".join(GET_VARS),
    "for": GEO,
    "in": f"state:{STATE} county:{COUNTY}",
    "key": API_KEY
}

response = requests.get(BASE_URL, params=params)



if response.status_code == 200:
    data = response.json()
    #convert data to pandas dataframe
    headers, *rows = data
    df = pd.DataFrame(rows, columns=headers)

    # specify directory and file name
    output_directory = r"C:\Users\HAN38975\OneDrive\test"
    output_file = "orlando_acs_age_sex_2022.csv"
    output_path = os.path.join(output_directory, output_file)

    #check path
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    #save to csv
    df.to_csv(output_path, index=False)
    print(f"Data saved to {output_path}")

    # upload to db
    # connection info
    server = "localhost"
    database = "testdb"
    table_name = "dbo.acs_block_groups"

    #connect to sql server
    connection_string = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"Trusted_Connection=yes;"  # Use this if connecting with Windows Authentication
    )
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    df.to_sql(table_name.split('.')[-1], con=conn, schema='dbo', if_exists='replace', index=False)

    print(f"csv uploaded to database: '{database}' in table: '{table_name}'")

    #close db connection
    conn.close()


else:
    print(f"Failed to fetch data. Status code: {response.status_code}")
    print(response.text)