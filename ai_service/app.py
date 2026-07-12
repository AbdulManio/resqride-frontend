import os
from datetime import datetime
import joblib
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Initialize FastAPI App
app = FastAPI(
    title="ResQRide AI Service",
    description="Machine Learning service for Breakdown Hotspot Prediction and Service Price Prediction in Karachi.",
    version="1.0.0"
)

# Enable CORS for local testing and flutter web/mobile requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Model paths
HOTSPOT_MODEL_PATH = "models/hotspot_classifier.joblib"
LE_RISK_PATH = "models/le_risk.joblib"
PRICE_MODEL_PATH = "models/price_regressor.joblib"
LE_SERVICE_PATH = "models/le_service.joblib"
LE_VEHICLE_PATH = "models/le_vehicle.joblib"

# Global variables for models and encoders
models = {}

# Predefined coordinates of major Karachi zones for batch hotspot querying
KARACHI_ZONES = [
    {"name": "DHA Phase 6", "latitude": 24.7950, "longitude": 67.0680},
    {"name": "DHA Phase 2", "latitude": 24.8210, "longitude": 67.0580},
    {"name": "Sea View Clifton", "latitude": 24.8010, "longitude": 67.0120},
    {"name": "Teen Talwar Clifton", "latitude": 24.8190, "longitude": 67.0320},
    {"name": "Gulshan-e-Iqbal Block 13", "latitude": 24.9180, "longitude": 67.0970},
    {"name": "Gulshan-e-Iqbal Block 3", "latitude": 24.9290, "longitude": 67.0850},
    {"name": "Gulistan-e-Johar Block 15", "latitude": 24.9120, "longitude": 67.1250},
    {"name": "Gulistan-e-Johar Block 1", "latitude": 24.9020, "longitude": 67.1120},
    {"name": "Saddar Empress Market", "latitude": 24.8614, "longitude": 67.0261},
    {"name": "I.I. Chundrigar Road", "latitude": 24.8510, "longitude": 67.0090},
    {"name": "Korangi Industrial Area", "latitude": 24.8436, "longitude": 67.1350},
    {"name": "North Nazimabad Block H", "latitude": 24.9372, "longitude": 67.0425},
    {"name": "Five Star Chowrangi", "latitude": 24.9450, "longitude": 67.0380},
    {"name": "Shahrah-e-Faisal (FTC)", "latitude": 24.8670, "longitude": 67.0560},
    {"name": "Shahrah-e-Faisal (Nursery)", "latitude": 24.8710, "longitude": 67.0700},
    {"name": "Civic Centre", "latitude": 24.9010, "longitude": 67.0780},
]

@app.on_event("startup")
def load_models():
    """Load scikit-learn models and encoders from the filesystem on startup."""
    print("Loading models and encoders...")
    try:
        if os.path.exists(HOTSPOT_MODEL_PATH):
            models["hotspot_classifier"] = joblib.load(HOTSPOT_MODEL_PATH)
            models["le_risk"] = joblib.load(LE_RISK_PATH)
            print("Successfully loaded hotspot classifier.")
        else:
            print("WARNING: Hotspot classifier model not found. Run train_models.py first.")

        if os.path.exists(PRICE_MODEL_PATH):
            models["price_regressor"] = joblib.load(PRICE_MODEL_PATH)
            models["le_service"] = joblib.load(LE_SERVICE_PATH)
            models["le_vehicle"] = joblib.load(LE_VEHICLE_PATH)
            print("Successfully loaded price regressor.")
        else:
            print("WARNING: Price regressor model not found. Run train_models.py first.")
    except Exception as e:
        print(f"Error loading models: {e}")

# Helper function to encode unseen labels safely
def safe_label_encode(encoder, value, default_val=0):
    try:
        if value in encoder.classes_:
            return int(encoder.transform([value])[0])
        else:
            # Look for case-insensitive match
            for idx, cls in enumerate(encoder.classes_):
                if str(cls).lower() == str(value).lower():
                    return idx
            return default_val
    except Exception:
        return default_val

# --- REQUEST SCHEMAS ---

class HotspotPredictRequest(BaseModel):
    latitude: float = Field(..., example=24.8607)
    longitude: float = Field(..., example=67.0011)
    timestamp: str = Field(None, description="ISO format date string (optional)")
    vehicleType: str = Field("Car", description="Vehicle type (optional)")
    serviceType: str = Field("General Assistance", description="Service type (optional)")

class PricePredictRequest(BaseModel):
    service_type: str = Field(..., alias="serviceType", example="Puncture")
    vehicle_type: str = Field(..., alias="vehicleType", example="Car")
    distance: float = Field(..., example=5.2)
    latitude: float = Field(24.8607, example=24.8607)
    longitude: float = Field(67.0011, example=67.0011)

    class Config:
        populate_by_name = True

# --- API ENDPOINTS ---

@app.get("/")
def read_root():
    return {
        "status": "online",
        "message": "Welcome to the ResQRide AI Service API",
        "models_loaded": list(models.keys())
    }

@app.post("/api/hotspot/predict")
def predict_hotspot(request: HotspotPredictRequest):
    """Predict risk level for a single lat/lng coordinate at a given time."""
    if "hotspot_classifier" not in models or "le_risk" not in models:
        raise HTTPException(
            status_code=503,
            detail="Hotspot classifier model is not available. Please train models first."
        )

    # 1. Parse date features
    dt = datetime.now()
    if request.timestamp:
        try:
            # Strip Z if present, replace timezone offset
            cleaned_timestamp = request.timestamp.replace("Z", "")
            dt = datetime.fromisoformat(cleaned_timestamp)
        except Exception:
            pass # fallback to current time on parse failure

    hour = dt.hour
    day_of_week = dt.weekday()

    # 2. Extract features
    features = np.array([[request.latitude, request.longitude, hour, day_of_week]])

    # 3. Predict
    prediction_idx = models["hotspot_classifier"].predict(features)[0]
    risk_level = models["le_risk"].inverse_transform([prediction_idx])[0]

    return {
        "riskLevel": risk_level,
        "latitude": request.latitude,
        "longitude": request.longitude
    }

@app.get("/api/hotspot/all")
def get_all_hotspots():
    """Predict and return risk levels for all pre-defined Karachi breakdown hotspots.
    Useful for rendering all zones on the Flutter Google Map in one call.
    """
    if "hotspot_classifier" not in models or "le_risk" not in models:
        raise HTTPException(
            status_code=503,
            detail="Hotspot classifier model is not available. Please train models first."
        )

    dt = datetime.now()
    hour = dt.hour
    day_of_week = dt.weekday()

    results = []
    for zone in KARACHI_ZONES:
        features = np.array([[zone["latitude"], zone["longitude"], hour, day_of_week]])
        prediction_idx = models["hotspot_classifier"].predict(features)[0]
        risk_level = models["le_risk"].inverse_transform([prediction_idx])[0]
        
        results.append({
            "name": zone["name"],
            "latitude": zone["latitude"],
            "longitude": zone["longitude"],
            "riskLevel": risk_level
        })

    return results

@app.post("/api/price/predict")
def predict_price(request: PricePredictRequest):
    """Predict estimated service fare in PKR based on input features."""
    if "price_regressor" not in models:
        raise HTTPException(
            status_code=503,
            detail="Price regressor model is not available. Please train models first."
        )

    # Clean/map service type to match trained categories
    service_type = request.service_type
    service_type_lower = service_type.lower()
    if "puncture" in service_type_lower:
        mapped_service = "Puncture"
    elif "fuel" in service_type_lower:
        mapped_service = "Fuel Delivery"
    elif "battery" in service_type_lower:
        mapped_service = "Battery Jump"
    elif "repair" in service_type_lower:
        mapped_service = "Minor Repair"
    else:
        mapped_service = "General Assistance"

    # Clean/map vehicle type to match trained categories
    vehicle_type = request.vehicle_type
    vehicle_type_lower = vehicle_type.lower()
    if "bike" in vehicle_type_lower:
        mapped_vehicle = "Bike"
    elif "suv" in vehicle_type_lower:
        mapped_vehicle = "SUV"
    else:
        mapped_vehicle = "Car"

    # 1. Encode categorical variables safely
    service_encoded = safe_label_encode(models["le_service"], mapped_service, default_val=0)
    vehicle_encoded = safe_label_encode(models["le_vehicle"], mapped_vehicle, default_val=0)

    # 2. Parse time features
    dt = datetime.now()
    hour = dt.hour
    day_of_week = dt.weekday()

    # 3. Assemble features
    # Order must match the train_models.py features:
    # ['problemType_encoded', 'vehicleType_encoded', 'distance', 'lat', 'lng', 'hour', 'day_of_week']
    features = np.array([[
        service_encoded,
        vehicle_encoded,
        request.distance,
        request.latitude,
        request.longitude,
        hour,
        day_of_week
    ]])

    # 4. Predict and round to nearest 50 PKR
    predicted_fare = float(models["price_regressor"].predict(features)[0])
    rounded_fare = int((predicted_fare // 50) * 50)
    
    # Cap minimum fare at 500 PKR as per requirement
    if rounded_fare < 500:
        rounded_fare = 500

    return {
        "estimatedPrice": rounded_fare
    }

if __name__ == "__main__":
    import uvicorn
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    print(f"Starting FastAPI server on {host}:{port}...")
    uvicorn.run("app:app", host=host, port=port, reload=True)
