import os
import random
from datetime import datetime, timedelta
from pymongo import MongoClient
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/rescue_ride")
DB_NAME = os.getenv("DB_NAME", "rescue_ride")

print(f"Connecting to MongoDB at {MONGODB_URI}...")
client = MongoClient(MONGODB_URI)
db = client[DB_NAME]
requests_collection = db["requests"]

# Define Karachi key regions and their coordinate centers
KARACHI_ZONES = {
    "DHA": {"lat": 24.8016, "lng": 67.0681, "risk": "Medium", "weight": 0.15},
    "Clifton": {"lat": 24.8138, "lng": 67.0319, "risk": "Medium", "weight": 0.12},
    "Gulshan-e-Iqbal": {"lat": 24.9180, "lng": 67.0971, "risk": "Medium", "weight": 0.18},
    "Gulistan-e-Johar": {"lat": 24.9107, "lng": 67.1209, "risk": "High", "weight": 0.22},
    "Saddar": {"lat": 24.8614, "lng": 67.0261, "risk": "High", "weight": 0.20},
    "Korangi": {"lat": 24.8436, "lng": 67.1350, "risk": "Low", "weight": 0.08},
    "North Nazimabad": {"lat": 24.9372, "lng": 67.0425, "risk": "Low", "weight": 0.05},
}

SERVICES = [
    {"name": "Puncture", "base_price": 500, "multiplier": 1.0},
    {"name": "Fuel Delivery", "base_price": 800, "multiplier": 1.2},
    {"name": "Battery Jump", "base_price": 600, "multiplier": 1.1},
    {"name": "Minor Repair", "base_price": 1200, "multiplier": 1.5},
    {"name": "General Assistance", "base_price": 700, "multiplier": 1.3}
]

VEHICLES = [
    {"type": "Bike", "multiplier": 0.8},
    {"type": "Car", "multiplier": 1.0},
    {"type": "SUV", "multiplier": 1.4}
]

def generate_synthetic_data(num_records=2500):
    print(f"Generating {num_records} synthetic roadside requests for Karachi...")
    requests = []
    start_date = datetime.now() - timedelta(days=90) # Last 90 days of history

    for _ in range(num_records):
        # 1. Select Zone based on weights (higher weight = more frequent breakdowns)
        zone_name = random.choices(list(KARACHI_ZONES.keys()), weights=[z["weight"] for z in KARACHI_ZONES.values()])[0]
        zone = KARACHI_ZONES[zone_name]

        # Add small normal distribution offset to lat/lng to scatter requests around center
        lat = zone["lat"] + random.normalvariate(0, 0.012)
        lng = zone["lng"] + random.normalvariate(0, 0.012)

        # 2. Service and Vehicle type selection
        service = random.choice(SERVICES)
        vehicle = random.choice(VEHICLES)

        # 3. Date & Time generation
        delta_days = random.randint(0, 89)
        delta_hours = random.randint(0, 23)
        delta_minutes = random.randint(0, 59)
        timestamp = start_date + timedelta(days=delta_days, hours=delta_hours, minutes=delta_minutes)

        # 4. Price Calculation (based on base price, vehicle type, distance, and random variation)
        # Simulate a random distance between 1 km and 15 km
        distance_km = round(random.uniform(1.0, 15.0), 2)
        
        # Calculate fare
        base = service["base_price"]
        v_mult = vehicle["multiplier"]
        dist_cost = distance_km * 50 # 50 PKR per KM
        
        # Base fare calculation
        estimated_fare = int((base * v_mult) + dist_cost)
        
        # Random negotiation factor (offered vs accepted)
        offered_fare = int(estimated_fare * random.uniform(0.9, 1.1))
        # Round to nearest 50 PKR
        offered_fare = (offered_fare // 50) * 50
        if offered_fare < 500:
            offered_fare = 500 # minimum fare boundary

        # Status: mostly completed, some cancelled
        status = random.choices(["completed", "cancelled"], weights=[0.85, 0.15])[0]
        final_fare = offered_fare if status == "completed" else 0

        # Construct MongoDB Request Document
        doc = {
            "problemType": service["name"],
            "offeredFare": offered_fare,
            "finalFare": final_fare,
            "lat": lat,
            "lng": lng,
            "description": f"Vehicle breakdown assistance required for {vehicle['type']}.",
            "address": f"Near {zone_name}, Karachi",
            "vehicleType": vehicle["type"],
            "distance": distance_km,
            "status": status,
            "createdAt": timestamp,
            "updatedAt": timestamp + timedelta(minutes=random.randint(15, 60))
        }
        requests.append(doc)

    # Try inserting into MongoDB
    try:
        print("Deleting existing synthetic data from MongoDB if any...")
        requests_collection.delete_many({"description": {"$regex": "Vehicle breakdown assistance required"}})
        print(f"Inserting {len(requests)} records into MongoDB...")
        requests_collection.insert_many(requests)
        print("[SUCCESS] Synthetic data generated and inserted into MongoDB successfully!")
    except Exception as e:
        print(f"\n[WARNING] MongoDB connection failed: {e}")
        print("Falling back to saving dataset to a local JSON file...")
        
        # Serialise datetime objects for JSON saving
        import json
        
        class DateTimeEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj, datetime):
                    return obj.isoformat()
                return super(DateTimeEncoder, self).default(obj)
                
        fallback_path = os.path.join(os.path.dirname(__file__), "requests_fallback.json")
        try:
            with open(fallback_path, "w") as f:
                json.dump(requests, f, cls=DateTimeEncoder, indent=2)
            print(f"[SUCCESS] Synthetic data successfully saved locally to: {fallback_path}")
            print("You can run train_models.py which will automatically use this local file.")
        except Exception as file_err:
            print(f"[ERROR] Failed to write fallback file: {file_err}")

if __name__ == "__main__":
    generate_synthetic_data()
