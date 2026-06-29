import json
import boto3
import urllib.request
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed

s3 = boto3.client("s3")

BUCKET = "raw-flight-data-mm"

# Multiple points to cover all of India — each within the 250nm API limit
POLL_POINTS = [
    {"lat": 28.6139, "lon": 77.2090, "name": "delhi"},
    {"lat": 19.0760, "lon": 72.8777, "name": "mumbai"},
    {"lat": 13.0827, "lon": 80.2707, "name": "chennai"},
    {"lat": 12.9716, "lon": 77.5946, "name": "bangalore"},
    {"lat": 22.5726, "lon": 88.3639, "name": "kolkata"},
    {"lat": 23.0225, "lon": 72.5714, "name": "ahmedabad"},
    {"lat": 17.3850, "lon": 78.4867, "name": "hyderabad"},
]


def fetch_point(point):
    url = f"https://api.airplanes.live/v2/point/{point['lat']}/{point['lon']}/250"

    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0"
        }
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            data = json.loads(response.read().decode("utf-8"))
            return data.get("ac", [])
    except Exception as e:
        print(f"Failed for {point['name']}: {str(e)}")
        return []


def lambda_handler(event, context):

    all_aircraft = {}  # dedupe by hex across overlapping city radii

    with ThreadPoolExecutor(max_workers=7) as executor:
        futures = {executor.submit(fetch_point, p): p for p in POLL_POINTS}
        for future in as_completed(futures):
            aircraft_list = future.result()
            for ac in aircraft_list:
                hex_id = ac.get("hex")
                if hex_id:
                    all_aircraft[hex_id] = ac

    merged_data = {
        "ac": list(all_aircraft.values()),
        "total": len(all_aircraft),
        "now": int(datetime.utcnow().timestamp() * 1000)
    }

    now = datetime.utcnow()

    key = (
        f"year={now.year}/"
        f"month={now.month:02d}/"
        f"day={now.day:02d}/"
        f"flight_data_{now.strftime('%Y%m%d_%H%M%S')}.json"
    )

    s3.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=json.dumps(merged_data)
    )

    return {
        "statusCode": 200,
        "aircraft_count": len(all_aircraft),
        "points_polled": len(POLL_POINTS),
        "file": key
    }