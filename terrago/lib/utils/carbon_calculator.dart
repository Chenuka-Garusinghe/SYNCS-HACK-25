import 'dart:convert';

/// Carbon Calculator for Household Environmental Impact Assessment
///
/// This utility calculates annual CO2 equivalent emissions based on:
/// - Transportation (cars, fuel type, trips)
/// - Diet (dietary preferences)
/// - Electricity usage (with solar panel consideration)
class CarbonCalculator {
  // ---------------------------
  // Constants (fixed factors)
  // ---------------------------

  /// Average trip distance in kilometers
  static const double avgTripDistanceKm = 10.0;

  /// Car efficiency by fuel type (consumption per km)
  static const Map<String, double> carEfficiency = {
    'petrol': 0.07, // L/km
    'diesel': 0.06, // L/km
    'ev': 0.18, // kWh/km
  };

  /// Emission factors by fuel type (kgCO2e per unit)
  static const Map<String, double> emissionFactor = {
    'petrol': 2.31, // kgCO2e/L
    'diesel': 2.68, // kgCO2e/L
    'ev': 0.70, // kgCO2e/kWh
  };

  /// Annual diet emissions per person (kgCO2e/year)
  static const Map<String, double> dietEmissionsAnnualPerPerson = {
    'meat_heavy': 3200.0,
    'normal': 2500.0,
    'flexitarian': 2000.0,
    'vegetarian': 1500.0,
    'vegan': 1000.0,
  };

  /// Annual household electricity usage (kWh/year)
  static const double householdElectricityUse = 4000.0;

  /// Electricity emission factor (kgCO2e/kWh)
  static const double electricityFactor = 0.70;

  // ---------------------------
  // Data Models
  // ---------------------------

  /// Input data structure for carbon calculations
  static Map<String, dynamic> createInputData({
    required String postcode,
    required int adults,
    required int cars,
    required List<String> fuelType,
    required int tripsPerWeek,
    required String diet,
    required String solar,
  }) {
    return {
      'postcode': postcode,
      'adults': adults,
      'cars': cars,
      'fuel_type': fuelType,
      'trips_per_week': tripsPerWeek,
      'diet': diet,
      'solar': solar,
    };
  }

  /// Output data structure for carbon calculations
  static Map<String, dynamic> createOutputData(double annualTotalKgco2e) {
    return {
      'annual_total_kgco2e': annualTotalKgco2e,
    };
  }

  // ---------------------------
  // Calculation Methods
  // ---------------------------

  /// Calculate annual CO2 equivalent emissions for a household
  ///
  /// [payload] should contain:
  /// - adults: number of adults in household
  /// - cars: number of cars
  /// - fuel_type: list of fuel types (petrol, diesel, ev)
  /// - trips_per_week: weekly trips per car
  /// - diet: dietary preference
  /// - solar: whether solar panels are installed
  ///
  /// Returns annual CO2e emissions in kg
  static double calculateAnnualCo2e(Map<String, dynamic> payload) {
    final int adults = payload['adults'] ?? 0;
    final int cars = payload['cars'] ?? 0;
    final List<String> fuelTypes =
        List<String>.from(payload['fuel_type'] ?? []);
    final int tripsPerWeek = payload['trips_per_week'] ?? 0;
    final String diet = payload['diet'] ?? 'normal';
    final String solar = payload['solar'] ?? 'no';

    // 1) Transport per week (per car)
    double transportPerWeek = 0.0;
    if (fuelTypes.isNotEmpty) {
      // Calculate average transport emissions across all cars
      double totalWeeklyEmissions = 0.0;
      for (String fuelType in fuelTypes) {
        final double efficiency = carEfficiency[fuelType] ?? 0.0;
        final double emission = emissionFactor[fuelType] ?? 0.0;
        totalWeeklyEmissions +=
            tripsPerWeek * avgTripDistanceKm * efficiency * emission;
      }
      transportPerWeek = totalWeeklyEmissions / fuelTypes.length;
    }

    // 2) Transport annual (total for all cars)
    final double transportAnnual = cars * transportPerWeek * 52;

    // 3) Diet annual
    final double dietAnnual =
        adults * (dietEmissionsAnnualPerPerson[diet] ?? 2500.0);

    // 4) Electricity annual
    double electricityAnnual = 0.0;
    if (solar.toLowerCase() != 'yes') {
      electricityAnnual = householdElectricityUse * electricityFactor;
    }

    // 5) Total annual
    final double totalAnnual = transportAnnual + dietAnnual + electricityAnnual;
    return double.parse(totalAnnual.toStringAsFixed(2));
  }

  /// Calculate and return formatted output data
  static Map<String, dynamic> calculateCarbonFootprint(
      Map<String, dynamic> inputData) {
    final double annualTotal = calculateAnnualCo2e(inputData);
    return createOutputData(annualTotal);
  }

  /// Convert input data to JSON string
  static String inputDataToJson(Map<String, dynamic> inputData) {
    return JsonEncoder.withIndent('  ').convert(inputData);
  }

  /// Convert output data to JSON string
  static String outputDataToJson(Map<String, dynamic> outputData) {
    return JsonEncoder.withIndent('  ').convert(outputData);
  }

  /// Parse JSON string to input data
  static Map<String, dynamic> jsonToInputData(String jsonString) {
    return jsonDecode(jsonString);
  }

  /// Parse JSON string to output data
  static Map<String, dynamic> jsonToOutputData(String jsonString) {
    return jsonDecode(jsonString);
  }

  // ---------------------------
  // Utility Methods
  // ---------------------------

  /// Get available fuel types
  static List<String> getAvailableFuelTypes() {
    return carEfficiency.keys.toList();
  }

  /// Get available diet types
  static List<String> getAvailableDietTypes() {
    return dietEmissionsAnnualPerPerson.keys.toList();
  }

  /// Validate input data
  static List<String> validateInputData(Map<String, dynamic> inputData) {
    final List<String> errors = [];

    if (inputData['adults'] == null || inputData['adults'] <= 0) {
      errors.add('Adults must be a positive number');
    }

    if (inputData['cars'] == null || inputData['cars'] < 0) {
      errors.add('Cars must be a non-negative number');
    }

    if (inputData['fuel_type'] == null || !(inputData['fuel_type'] is List)) {
      errors.add('Fuel type must be a list');
    } else {
      final List<String> fuelTypes = List<String>.from(inputData['fuel_type']);
      if (fuelTypes.isEmpty && inputData['cars'] > 0) {
        errors.add('Fuel types must be specified for each car');
      }
      for (String fuelType in fuelTypes) {
        if (!carEfficiency.containsKey(fuelType)) {
          errors.add('Invalid fuel type: $fuelType');
        }
      }
    }

    if (inputData['trips_per_week'] == null ||
        inputData['trips_per_week'] < 0) {
      errors.add('Trips per week must be a non-negative number');
    }

    if (inputData['diet'] == null ||
        !dietEmissionsAnnualPerPerson.containsKey(inputData['diet'])) {
      errors.add('Invalid diet type: ${inputData['diet']}');
    }

    if (inputData['solar'] == null ||
        !['yes', 'no'].contains(inputData['solar'].toString().toLowerCase())) {
      errors.add('Solar must be either "yes" or "no"');
    }

    return errors;
  }

  /// Get calculation breakdown for detailed analysis
  static Map<String, dynamic> getCalculationBreakdown(
      Map<String, dynamic> inputData) {
    final int adults = inputData['adults'] ?? 0;
    final int cars = inputData['cars'] ?? 0;
    final List<String> fuelTypes =
        List<String>.from(inputData['fuel_type'] ?? []);
    final int tripsPerWeek = inputData['trips_per_week'] ?? 0;
    final String diet = inputData['diet'] ?? 'normal';
    final String solar = inputData['solar'] ?? 'no';

    // Calculate individual components
    double transportPerWeek = 0.0;
    if (fuelTypes.isNotEmpty) {
      double totalWeeklyEmissions = 0.0;
      for (String fuelType in fuelTypes) {
        final double efficiency = carEfficiency[fuelType] ?? 0.0;
        final double emission = emissionFactor[fuelType] ?? 0.0;
        totalWeeklyEmissions +=
            tripsPerWeek * avgTripDistanceKm * efficiency * emission;
      }
      transportPerWeek = totalWeeklyEmissions / fuelTypes.length;
    }

    final double transportAnnual = cars * transportPerWeek * 52;
    final double dietAnnual =
        adults * (dietEmissionsAnnualPerPerson[diet] ?? 2500.0);
    final double electricityAnnual = solar.toLowerCase() == 'yes'
        ? 0.0
        : householdElectricityUse * electricityFactor;
    final double totalAnnual = transportAnnual + dietAnnual + electricityAnnual;

    return {
      'breakdown': {
        'transport': {
          'weekly_per_car_kgco2e':
              double.parse(transportPerWeek.toStringAsFixed(2)),
          'annual_total_kgco2e':
              double.parse(transportAnnual.toStringAsFixed(2)),
          'percentage': double.parse(
              ((transportAnnual / totalAnnual) * 100).toStringAsFixed(1)),
        },
        'diet': {
          'annual_total_kgco2e': double.parse(dietAnnual.toStringAsFixed(2)),
          'percentage': double.parse(
              ((dietAnnual / totalAnnual) * 100).toStringAsFixed(1)),
        },
        'electricity': {
          'annual_total_kgco2e':
              double.parse(electricityAnnual.toStringAsFixed(2)),
          'percentage': double.parse(
              ((electricityAnnual / totalAnnual) * 100).toStringAsFixed(1)),
        },
      },
      'total_annual_kgco2e': double.parse(totalAnnual.toStringAsFixed(2)),
    };
  }
}
