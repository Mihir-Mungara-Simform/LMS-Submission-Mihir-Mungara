import pandas as pd
import boto3
import psycopg2
from io import StringIO

# SNS
sns = boto3.client('sns')
TOPIC_ARN = "arn:aws:sns:ap-south-1:590183765270:pipeline-alerts"

# S3
s3 = boto3.client('s3')
BUCKET = "retail-pulse-bucket-590183765270-ap-south-1-an"

try:
    # DB connection
    conn = psycopg2.connect(
        host="database-1-retail-pulse.cbecueicwu8l.ap-south-1.rds.amazonaws.com",
        database="postgres",
        user="postgres",
        password="postgres#1234",
        port="5432"
    )
    cursor = conn.cursor()

    files = [
        ("processed/ecommerce/ecommerce_transactions.csv", "ecommerce_transactions"),
        ("processed/pos/pos_transactions.csv", "pos_transactions")
    ]

    for file_key, table_name in files:
        print(f"Processing {file_key}")

        try:
            # Read from S3
            obj = s3.get_object(Bucket=BUCKET, Key=file_key)
            df = pd.read_csv(obj['Body'])

            buffer = StringIO()
            df.to_csv(buffer, index=False, header=False)
            buffer.seek(0)

            cursor.copy_expert(
                f"COPY {table_name} FROM STDIN WITH CSV",
                buffer
            )

            conn.commit()
            print(f"Inserted into {table_name}")

        except Exception as db_error:
            # 🔥 DATABASE FAILURE ALERT
            error_msg = f"DB Insert Failed for {table_name}\nError: {str(db_error)}"
            print(error_msg)

            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject="RDS Insert Failed ❌",
                Message=error_msg
            )

    cursor.close()
    conn.close()

    print("Pipeline completed successfully ✅")

except Exception as e:
    # 🔥 SCRIPT FAILURE ALERT
    error_msg = f"Pipeline Execution Failed\nError: {str(e)}"
    print(error_msg)

    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject="Pipeline Failed ❌",
        Message=error_msg
    )