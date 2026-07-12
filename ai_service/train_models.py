import os
import joblib
import numpy as np
import pandas as pd
from pymongo import MongoClient
from dotenv import load_dotenv
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, mean_absolute_error, r2_score

# Load environment variables
load_dotenv()

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017/rescue_ride")
DB_NAME = os.getenv("DB_NAME", "rescue_ride")

def fetch_data_from_db():
    print(f"Fetching historical requests from database {DB_NAME}...")
    try:
        # Set a short timeout so it doesn't hang for 2 seconds if offline
        client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=2000)
        db = client[DB_NAME]
        collection = db["requests"]
        cursor = list(collection.find())
        
        if len(cursor) > 0:
            df = pd.DataFrame(cursor)
            print(f"Successfully loaded {len(df)} records from MongoDB.")
            return df
        else:
            print("No records found in MongoDB. Checking local fallback file...")
    except Exception as e:
        print(f"[WARNING] MongoDB connection failed: {e}. Checking local fallback file...")

    # Load from local JSON fallback
    fallback_path = os.path.join(os.path.dirname(__file__), "requests_fallback.json")
    if os.path.exists(fallback_path):
        print(f"Loading data from local fallback file: {fallback_path}...")
        df = pd.read_json(fallback_path)
        if len(df) > 0:
            print(f"Successfully loaded {len(df)} records from local JSON fallback file.")
            return df
            
    raise ValueError(
        "No historical request data found! Please make sure MongoDB is running or run generate_synthetic_data.py to create the fallback file."
    )

def train():
    df = fetch_data_from_db()
    
    # 1. PREPROCESSING & COMMON FEATURE ENGINEERING
    # Convert dates
    df['createdAt'] = pd.to_datetime(df['createdAt'])
    df['hour'] = df['createdAt'].dt.hour
    df['day_of_week'] = df['createdAt'].dt.dayofweek # Monday=0, Sunday=6
    
    # Fill missing values
    df['vehicleType'] = df['vehicleType'].fillna('Car')
    df['distance'] = df['distance'].fillna(5.0)
    
    # 2. FEATURE ENGINEERING FOR HOTSPOT CLASSIFICATION
    # We define grid cells by rounding coordinates to 2 decimal places (~1.1 km area)
    # to count request frequencies in each zone.
    df['grid_lat'] = df['lat'].round(2)
    df['grid_lng'] = df['lng'].round(2)
    
    # Count frequency of requests per grid
    grid_counts = df.groupby(['grid_lat', 'grid_lng']).size().reset_index(name='frequency')
    
    # Define risk boundaries based on percentiles
    low_cutoff = grid_counts['frequency'].quantile(0.3)
    high_cutoff = grid_counts['frequency'].quantile(0.7)
    
    def label_risk(freq):
        if freq >= high_cutoff:
            return "High"
        elif freq >= low_cutoff:
            return "Medium"
        else:
            return "Low"
            
    grid_counts['riskLevel'] = grid_counts['frequency'].apply(label_risk)
    
    # Merge risk levels back to the main dataframe
    df = df.merge(grid_counts[['grid_lat', 'grid_lng', 'riskLevel']], on=['grid_lat', 'grid_lng'], how='left')
    
    print("\nRisk Level Distribution in Dataset:")
    print(df['riskLevel'].value_counts())

    # 3. TRAIN HOTSPOT RISK CLASSIFIER
    print("\n--- Training Hotspot Risk Classifier ---")
    
    # Features for hotspot
    hotspot_features = ['lat', 'lng', 'hour', 'day_of_week']
    X_hotspot = df[hotspot_features]
    y_hotspot = df['riskLevel']
    
    # Encode target risk labels
    le_risk = LabelEncoder()
    y_hotspot_encoded = le_risk.fit_transform(y_hotspot)
    
    X_train_h, X_test_h, y_train_h, y_test_h = train_test_split(
        X_hotspot, y_hotspot_encoded, test_size=0.2, random_state=42, stratify=y_hotspot_encoded
    )
    
    hotspot_model = RandomForestClassifier(n_estimators=100, random_state=42)
    hotspot_model.fit(X_train_h, y_train_h)
    
    # Evaluate
    y_pred_h = hotspot_model.predict(X_test_h)
    print("Hotspot Model Evaluation:")
    print(classification_report(y_test_h, y_pred_h, target_names=le_risk.classes_))

    # 4. TRAIN PRICE REGRESSOR
    print("\n--- Training Service Price Regressor ---")
    
    # Only train on completed requests or requests with valid fares
    price_df = df[df['status'] == 'completed'].copy()
    if len(price_df) < 100:
        # Fallback to all requests if completed are too few
        price_df = df.copy()
        
    # Encoders for categorical features
    le_service = LabelEncoder()
    price_df['problemType_encoded'] = le_service.fit_transform(price_df['problemType'])
    
    le_vehicle = LabelEncoder()
    price_df['vehicleType_encoded'] = le_vehicle.fit_transform(price_df['vehicleType'])
    
    price_features = ['problemType_encoded', 'vehicleType_encoded', 'distance', 'lat', 'lng', 'hour', 'day_of_week']
    X_price = price_df[price_features]
    y_price = price_df['offeredFare']
    
    X_train_p, X_test_p, y_train_p, y_test_p = train_test_split(
        X_price, y_price, test_size=0.2, random_state=42
    )
    
    price_model = RandomForestRegressor(n_estimators=150, random_state=42)
    price_model.fit(X_train_p, y_train_p)
    
    # Evaluate
    y_pred_p = price_model.predict(X_test_p)
    mae = mean_absolute_error(y_test_p, y_pred_p)
    r2 = r2_score(y_test_p, y_pred_p)
    print(f"Price Model Evaluation:\nMean Absolute Error: {mae:.2f} PKR\nR2 Score: {r2:.4f}")

    # 5. SAVE MODELS & ENCODERS
    os.makedirs("models", exist_ok=True)
    
    joblib.dump(hotspot_model, "models/hotspot_classifier.joblib")
    joblib.dump(le_risk, "models/le_risk.joblib")
    
    joblib.dump(price_model, "models/price_regressor.joblib")
    joblib.dump(le_service, "models/le_service.joblib")
    joblib.dump(le_vehicle, "models/le_vehicle.joblib")
    
    print("\n[SUCCESS] All models and encoders successfully trained and saved under the 'models/' directory!")

if __name__ == "__main__":
    train()
