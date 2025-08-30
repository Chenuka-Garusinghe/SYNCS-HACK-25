#!/usr/bin/env python3
import json
import os
import argparse

# ---------------------------
# Constants (fixed factors)
# ---------------------------
AVG_TRIP_DISTANCE_KM = 10
CAR_EFFICIENCY = {
    "petrol": 0.07,  # L/km
    "diesel": 0.06,  # L/km
    "ev": 0.18,      # kWh/km
}
EMISSION_FACTOR = {
    "petrol": 2.31,  # kgCO2e/L
    "diesel": 2.68,  # kgCO2e/L
    "ev": 0.70,      # kgCO2e/kWh
}
DIET_EMISSIONS_ANNUAL_PER_PERSON = {
    "meat_heavy": 3200,
    "normal": 2500,
    "flexitarian": 2000,
    "vegetarian": 1500,
    "vegan": 1000,
}
HOUSEHOLD_ELECTRICITY_USE = 4000  # kWh/year
ELECTRICITY_FACTOR = 0.70         # kgCO2e/kWh


# ---------------------------
# Local calculation
# ---------------------------
def calculate_annual_co2e(payload):
    adults = payload["adults"]
    cars = payload["cars"]
    fuel_type = payload["fuel_type"]
    trips_per_week = payload["trips_per_week"]
    diet = payload["diet"]
    solar = payload["solar"]

    # 1) Transport_per_week
    transport_per_week = (
        trips_per_week
        * AVG_TRIP_DISTANCE_KM
        * CAR_EFFICIENCY[fuel_type]
        * EMISSION_FACTOR[fuel_type]
    )

    # 2) Transport_annual
    transport_annual = cars * transport_per_week * 52

    # 3) Diet_annual
    diet_annual = adults * DIET_EMISSIONS_ANNUAL_PER_PERSON[diet]

    # 4) Electricity_annual
    if str(solar).lower() == "yes":
        electricity_annual = 0.0
    else:
        electricity_annual = HOUSEHOLD_ELECTRICITY_USE * ELECTRICITY_FACTOR

    # 5) Total_annual
    total_annual = transport_annual + diet_annual + electricity_annual
    return round(total_annual, 2)


# ---------------------------
# Main CLI
# ---------------------------
def main():
    parser = argparse.ArgumentParser(description="Household CO2e calculator")
    parser.add_argument("--input", "-i", required=True, help="Path to input JSON file")
    parser.add_argument("--output", "-o", required=True, help="Path to output JSON file")
    args = parser.parse_args()

    with open(args.input, "r", encoding="utf-8") as f:
        payload = json.load(f)

    value = calculate_annual_co2e(payload)
    out = {"annual_total_kgco2e": value}

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))

    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
