import json
import boto3
import pandas as pd
import io
from datetime import datetime, timezone
from urllib.parse import unquote_plus

s3 = boto3.client("s3")
SILVER_BUCKET = "flight-silver-bucket-mm"

def lambda_handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        s3_info = json.loads(body["Message"]) if "Message" in body else body

        for s3_record in s3_info.get("Records", []):
            bucket = s3_record["s3"]["bucket"]["name"]
            key    = unquote_plus(s3_record["s3"]["object"]["key"])

            obj  = s3.get_object(Bucket=bucket, Key=key)
            data = json.loads(obj["Body"].read().decode("utf-8"))

            aircraft_list = data.get("ac", [])
            snapshot_ts   = datetime.fromtimestamp(
                data.get("now", 0) / 1000, tz=timezone.utc
            ).isoformat()

            rows = [extract_fields(ac, snapshot_ts) for ac in aircraft_list]

            if not rows:
                continue

            df = pd.DataFrame(rows)

            df["alt_baro"] = df["alt_baro"].replace("ground", 0)

            numeric_cols = [
                "alt_baro",
                "alt_geom",
                "baro_rate",
                "geom_rate",
                "gs",
                "ias",
                "tas",
                "mach",
                "latitude",
                "longitude"
            ]

            for col in numeric_cols:
                if col in df.columns:
                    df[col] = pd.to_numeric(df[col], errors="coerce")

            # Add derived columns right here in Lambda
            df["flight_phase"]   = df["alt_baro"].apply(classify_phase)
            df["vertical_trend"] = df["baro_rate"].apply(classify_vertical)
            df["speed_category"] = df["gs"].apply(classify_speed)
            df["is_heavy"]       = df["category"].isin(["A5"])
            df["grid_lat"]       = df["latitude"].apply(
                lambda x: int(x) if pd.notna(x) else None
            )
            df["grid_lon"]       = df["longitude"].apply(
                lambda x: int(x) if pd.notna(x) else None
            )
            df["grid_cell"]      = df["grid_lat"].astype(str) + "_" + \
                                   df["grid_lon"].astype(str)

            # Write parquet
            buf = io.BytesIO()
            df.to_parquet(buf, engine="pyarrow", index=False)
            buf.seek(0)

            now      = datetime.utcnow()
            out_key  = (
                f"year={now.year}/month={now.month:02d}/"
                f"day={now.day:02d}/"
                f"{key.split('/')[-1].replace('.json', '.parquet')}"
            )

            s3.put_object(Bucket=SILVER_BUCKET, Key=out_key, Body=buf.read())

    return {"statusCode": 200}


def extract_fields(ac, snapshot_ts):
    return {
        # --- Identity ---
        "hex":             ac.get("hex"),
        "flight":          (ac.get("flight") or "").strip() or None,
        "registration":    ac.get("r"),
        "aircraft_type":   ac.get("t"),
        "aircraft_desc":   ac.get("desc"),
        "category":        ac.get("category"),
        "adsb_type":       ac.get("type"),

        # --- Position ---
        "latitude":        ac.get("lat"),
        "longitude":       ac.get("lon"),
        "alt_baro":        ac.get("alt_baro"),
        "alt_geom":        ac.get("alt_geom"),

        # --- Speed & Movement ---
        "gs":              ac.get("gs"),        # ground speed (knots)
        "ias":             ac.get("ias"),        # indicated airspeed
        "tas":             ac.get("tas"),        # true airspeed
        "mach":            ac.get("mach"),
        "track":           ac.get("track"),      # heading degrees
        "baro_rate":       ac.get("baro_rate"),  # ft/min climb/descent
        "geom_rate":       ac.get("geom_rate"),
        "roll":            ac.get("roll"),

        # --- Atmospheric ---
        "wind_dir":        ac.get("wd"),
        "wind_speed":      ac.get("ws"),
        "oat":             ac.get("oat"),        # outside air temp °C
        "tat":             ac.get("tat"),        # total air temp °C

        # --- Navigation ---
        "squawk":          ac.get("squawk"),
        "emergency":       ac.get("emergency"),
        "nav_altitude":    ac.get("nav_altitude_mcp"),
        "nav_heading":     ac.get("nav_heading"),
        "nav_qnh":         ac.get("nav_qnh"),

        # --- Signal Quality ---
        "nic":             ac.get("nic"),        # navigation integrity
        "rssi":            ac.get("rssi"),       # signal strength
        "messages":        ac.get("messages"),   # total ADS-B messages
        "seen":            ac.get("seen"),       # seconds since last msg
        "seen_pos":        ac.get("seen_pos"),   # seconds since last pos

        # --- Distance from receiver ---
        "dst":             ac.get("dst"),        # distance (nm)
        "dir":             ac.get("dir"),        # direction from receiver

        # --- Snapshot metadata ---
        "snapshot_ts":     snapshot_ts,
        "processed_time":  datetime.utcnow().isoformat(),
    }


# --- Derived column helpers ---

# def classify_phase(alt):
#     if alt is None:              return "Unknown"
#     if alt < 1000:               return "Ground/Taxi"
#     if alt < 10000:              return "Climb/Descent"
#     if alt >= 10000:             return "Cruise"

# def classify_vertical(rate):
#     if rate is None:             return "Unknown"
#     if rate >  500:              return "Climbing"
#     if rate < -500:              return "Descending"
#     return "Level"

# def classify_speed(gs):
#     if gs is None:               return "Unknown"
#     if gs < 150:                 return "Slow (<150 kts)"
#     if gs < 350:                 return "Subsonic (150-350)"
#     return "High Speed (350+)"

def classify_phase(alt):
    # Handle string "ground" status and any other non-numeric values
    if alt is None:
        return "Unknown"
    if isinstance(alt, str):
        if alt.lower() == "ground":
            return "Ground/Taxi"
        try:
            alt = float(alt)
        except (ValueError, TypeError):
            return "Unknown"
    if alt < 1000:
        return "Ground/Taxi"
    elif alt < 10000:
        return "Climb/Descent"
    else:
        return "Cruise"

def classify_vertical(rate):
    if rate is None:
        return "Unknown"

    try:
        rate = float(rate)
    except (ValueError, TypeError):
        return "Unknown"

    if rate > 500:
        return "Climbing"
    elif rate < -500:
        return "Descending"
    else:
        return "Level"

def classify_speed(gs):
    if gs is None:
        return "Unknown"

    try:
        gs = float(gs)
    except (ValueError, TypeError):
        return "Unknown"

    if gs < 150:
        return "Slow (<150 kts)"
    elif gs < 350:
        return "Subsonic (150-350)"
    else:
        return "High Speed (350+)"