import pandas as pd
import boto3

s3 = boto3.client('s3')
BUCKET = "retail-pulse-bucket-590183765270-ap-south-1-an"

files = [
    "raw/ecommerce/ecommerce_transactions.csv",
    "raw/pos/pos_transactions.csv"
]

for file_key in files:
    print(f"\nProcessing {file_key}")

    obj = s3.get_object(Bucket=BUCKET, Key=file_key)
    df = pd.read_csv(obj['Body'])

    # =========================
    # ECOMMERCE LOGIC
    # =========================
    if "ecommerce" in file_key:
        print("Applying ecommerce validation")

        df_clean = df[
            (df['quantity'] > 0) &
            (df['unit_price'] > 0) &
            (df['payment_status'] == "PAID") &
            (df['order_status'] != "CANCELLED")
        ]

    # =========================
    # POS LOGIC
    # =========================
    elif "pos" in file_key:
        print("Applying POS validation")

        df_clean = df[
            (df['quantity'] > 0) &
            (df['unit_price'] > 0)
        ]

    else:
        print("Unknown file type, skipping...")
        continue

    print(f"Rows before: {len(df)}, after cleaning: {len(df_clean)}")

    # Output path (processed layer)
    output_key = file_key.replace("raw/", "processed/")

    # Save locally
    temp_file = "/tmp/processed.csv"
    df_clean.to_csv(temp_file, index=False)

    # Upload to S3
    s3.upload_file(temp_file, BUCKET, output_key)

    print(f"Saved to {output_key}")

print("\nPipeline completed successfully ✅")