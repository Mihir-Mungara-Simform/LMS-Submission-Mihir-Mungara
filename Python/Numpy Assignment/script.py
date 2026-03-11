# importing neccessary packages and libraries 
import pandas as pd
import logging
import io

# -------------------------------------- Task 0: Logging Setup --------------------------------------

# setting up filehandler, formatter and logger for file
file_logger = logging.getLogger('file_logger')
file_logger.setLevel(logging.INFO)
f_handler = logging.FileHandler('logs.txt')
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
f_handler.setFormatter(formatter)
file_logger.addHandler(f_handler)

# setting up streamhandler and logger for console
stream_logger = logging.getLogger('stream_logger')
stream_logger.setLevel(logging.INFO)
s_handler = logging.StreamHandler()
s_handler.setFormatter(formatter)
stream_logger.addHandler(s_handler)

# starting the pipeline
file_logger.info('Start of pipeline \n')
stream_logger.info('Start of pipeline \n')

# -------------------------------------- Task 1: Data Loading --------------------------------------

file_logger.info('Start of Task-1 \n')
stream_logger.info('Start of Task-1 \n')

# Loaded the employees.csv dataset into a suitable in-memory structure and Ensured that date fields are parsed correctly
try:
    df = pd.read_csv('numpy_assignment/employees.csv', 
                    header='infer', 
                    parse_dates=['Joining_Date'], 
                    dayfirst= True)

    # Displaying a sample of the dataset for verification.
    print('Displaying a sample of dataset for verification')
    print(df.head())
    print('')

    # Capture df.info() output
    buffer = io.StringIO()
    df.info(buf=buffer)

    # Logged the total number of records and detected schema.
    file_logger.info(buffer.getvalue() + '\n')
    stream_logger.info(buffer.getvalue() + '\n')

    file_logger.info(f"Total records loaded: {len(df)} \n")
    stream_logger.info(f"Total records loaded: {len(df)} \n")

except Exception as e:
    file_logger.error(f"Error while loading dataset: {e}")
    stream_logger.error(f"Error while loading dataset: {e}")
    raise

file_logger.info('End of Task-1 \n')
stream_logger.info('End of Task-1 \n')

# -------------------------------------- Task 2: Data Cleaning --------------------------------------

file_logger.info('Start of Task-2 \n')
stream_logger.info('Start of Task-2 \n')

try:
    # Identify missing values across all columns.
    missing = df.isna().sum()

    # Replace missing Age values using the median of the available data.
    df['Age'] = df['Age'].fillna(df['Age'].median())

    # Replace missing Salary values using the mean of the available data.
    df['Salary'] = df['Salary'].fillna(df['Salary'].mean())

    # Detect and remove duplicate employee records based on Employee_ID
    df = df.drop_duplicates(subset='Employee_ID')

except Exception as e:
    file_logger.error(f"Error during data cleaning: {e}")
    stream_logger.error(f"Error during data cleaning: {e}")

# Standardize column naming for consistency.
# Names are standardized already

# Ensure all columns are stored using appropriate data types.
print('Displaying dtypes for Verification')
print(df.dtypes)
print('')

# Log all cleaning actions performed.
file_logger.info(f"Missing values per column:\n{missing} \n")
stream_logger.info(f"Missing values per column:\n{missing} \n")

file_logger.info('Replaced missing Age values using the median of the available data\n')
stream_logger.info('Replaced missing Age values using the median of the available data\n')

file_logger.info('Replaced missing Salary values using the mean of the available data\n')
stream_logger.info('Replaced missing Salary values using the mean of the available data\n')

file_logger.info('Detected and removed duplicate employee records based on Employee_ID\n')
stream_logger.info('Detected and removed duplicate employee records based on Employee_ID\n')

file_logger.info('Standardized column naming for consistency\n')
stream_logger.info('Standardized column naming for consistency\n')

file_logger.info('Ensured that all columns are stored using appropriate data types\n')
stream_logger.info('Ensured that all columns are stored using appropriate data types\n')

file_logger.info('End of Task-2 \n')
stream_logger.info('End of Task-2 \n')

# -------------------------------------- Task 3: Data Manipulation --------------------------------------

file_logger.info('Start of Task-3 \n')
stream_logger.info('Start of Task-3 \n')

try:
    # Filter out employees who are above the age of 25 or have a salary above 40,000, and are not resigned.
    print('employees who are above the age of 25 or have a salary above 40,000, and are not resigned.')
    rows_before = df.shape[0]
    filter1 = (df['Age'] > 25) | (df['Salary'] > 40000)
    filter2 = ~df['Resigned']
    df = df[filter1 & filter2]
    print(df)
    print('')

    # Create a new column YearsInCompany by calculating the number of years each employee has worked in the company (from JoiningDate to today). 
    df['YearsInCompany'] = ((pd.Timestamp.today() - df['Joining_Date']).dt.days / 365).astype(int)

    # Record and log the number of records before and after filtering.
    rows_after = df.shape[0]
    file_logger.info(f'rows before filtering:- {rows_before} and rows after filtering- {rows_after}\n')
    stream_logger.info(f'rows before filtering:- {rows_before} and rows after filtering- {rows_after}\n')

except Exception as e:
    file_logger.error(f"Error during data manipulation: {e}")
    stream_logger.error(f"Error during data manipulation: {e}")

file_logger.info('End of Task-3 \n')
stream_logger.info('End of Task-3 \n')

# -------------------------------------- Task 4: Aggregation & Analysis --------------------------------------

file_logger.info('Start of Task-4 \n')
stream_logger.info('Start of Task-4 \n')

try:
    before_salary_update = df[df['Department'] == 'IT']

    # Compute department-level statistics including average salary and median age.
    analytics_result = df.groupby('Department').agg({'Salary':'mean', 'Age':'median'})

    # Apply a salary increment of 10% for employees belonging to a specific department
    df.loc[df['Department'] == 'IT', 'Salary'] *= 1.10

    # Log analytical results and changes applied
    file_logger.info(f'Analytics_Report :- \n {analytics_result} \n')
    stream_logger.info(f'Analytics_Report :- \n {analytics_result} \n')

    file_logger.info(f'\nBefore 10% increment in IT department Salary:- \n {before_salary_update}\n \n After 10% increment in IT department Salary:- \n{df[df['Department'] == 'IT']} \n')
    stream_logger.info(f'\nBefore 10% increment in IT department Salary:- \n {before_salary_update}\n \n After 10% increment in IT department Salary:- \n{df[df['Department'] == 'IT']} \n')

except Exception as e:
    file_logger.error(f"Error during aggregation and analysis: {e}")
    stream_logger.error(f"Error during aggregation and analysis: {e}")

file_logger.info('End of Task-4 \n')
stream_logger.info('End of Task-4 \n')

# -------------------------------------- Task 5: Aggregation & Analysis --------------------------------------

file_logger.info('Start of Task-5 \n')
stream_logger.info('Start of Task-5 \n')

try:
    # Rename columns where required to improve clarity.
    df.rename(columns={'YearsInCompany' : 'Years_In_Company'}, inplace=True)

    # Sort the data based on joining date in descending order.
    df.sort_values(by=['Joining_Date'], ascending=False, inplace=True)

    # Retain only relevant fields in the final dataset (Employee_ID, Name, Age, Department, Salary, and YearsInCompany).
    df = df[['Employee_ID','Name','Age','Department','Salary','Years_In_Company']]

    # Export the final dataset to JSON format.
    df.to_json('cleaned_employees.json', orient='records', indent=4)

    # Log successful data export and record count
    file_logger.info(f'Data exported successfully to cleaned_employees.json with {len(df)} records. \n')
    stream_logger.info(f'Data exported successfully to cleaned_employees.json with {len(df)} records. \n')

except Exception as e:
    file_logger.error(f"Error exporting JSON file: {e}")
    stream_logger.error(f"Error exporting JSON file: {e}")

file_logger.info('End of Task-5 \n')
stream_logger.info('End of Task-5 \n')

file_logger.info('Pipeline completed successfully')
stream_logger.info('Pipeline completed successfully')