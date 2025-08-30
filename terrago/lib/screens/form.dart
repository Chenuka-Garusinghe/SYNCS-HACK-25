import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../utils/carbon_calculator.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();
  final TextEditingController _tripsController = TextEditingController();

  // Form values
  int _numberOfVehicles = 0;
  List<String> _vehicleTypes = []; // 'Gas' or 'EV'
  String _dietaryType = 'Normal Omnivorous';
  bool _hasSolarPanels = false;

  // Dietary options
  final List<String> _dietaryOptions = [
    'Meat Heavy',
    'Normal Omnivorous',
    'Vegetarian',
    'Vegan',
  ];

  @override
  void initState() {
    super.initState();
    _vehicleTypes = List.filled(0, 'Gas');
  }

  @override
  void dispose() {
    _postCodeController.dispose();
    _peopleController.dispose();
    _tripsController.dispose();
    super.dispose();
  }

  void _updateVehicleTypes() {
    setState(() {
      _vehicleTypes = List.filled(_numberOfVehicles, 'Gas');
    });
  }

  Map<String, dynamic> _generateJsonData() {
    // Convert dietary type to the format specified in the JSON
    String dietType = 'normal';
    switch (_dietaryType) {
      case 'Meat Heavy':
        dietType = 'meat_heavy';
        break;
      case 'Normal Omnivorous':
        dietType = 'normal';
        break;
      case 'Vegetarian':
        dietType = 'vegetarian';
        break;
      case 'Vegan':
        dietType = 'vegan';
        break;
    }

    // Convert fuel types to a list based on each vehicle's type
    List<String> fuelTypes = [];
    for (String vehicleType in _vehicleTypes) {
      fuelTypes.add(vehicleType == 'Gas' ? 'petrol' : 'ev');
    }

    return {
      "postcode": _postCodeController.text,
      "adults": int.tryParse(_peopleController.text) ?? 0,
      "cars": _numberOfVehicles,
      "fuel_type": fuelTypes,
      "trips_per_week": int.tryParse(_tripsController.text) ?? 0,
      "diet": dietType,
      "solar": _hasSolarPanels ? "yes" : "no",
    };
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> jsonData = _generateJsonData();
      String jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Store the JSON data in variables for further use
      // You can access:
      // - jsonData: Map<String, dynamic> containing the structured data
      // - jsonString: String containing the formatted JSON

      print('Generated JSON ------>');
      print(jsonString);

      // Calculate carbon footprint using the carbon calculator
      try {
        final double carbonFootprint =
            CarbonCalculator.calculateAnnualCo2e(jsonData);
        final Map<String, dynamic> breakdown =
            CarbonCalculator.getCalculationBreakdown(jsonData);

        print('\n=== CARBON FOOTPRINT CALCULATION ===');
        print('Annual CO2e: ${carbonFootprint} kg');
        print(
            'Transport: ${breakdown['breakdown']['transport']['annual_total_kgco2e']} kg CO2e (${breakdown['breakdown']['transport']['percentage']}%)');
        print(
            'Diet: ${breakdown['breakdown']['diet']['annual_total_kgco2e']} kg CO2e (${breakdown['breakdown']['diet']['percentage']}%)');
        print(
            'Electricity: ${breakdown['breakdown']['electricity']['annual_total_kgco2e']} kg CO2e (${breakdown['breakdown']['electricity']['percentage']}%)');

        // Create output data for the JSON file
        final Map<String, dynamic> outputData = {
          'annual_total_kgco2e': carbonFootprint,
          'breakdown': breakdown['breakdown'],
          'input_data': jsonData,
          'calculation_timestamp': DateTime.now().toIso8601String(),
        };

        // Save to output.json file
        await _saveOutputToFile(outputData);

        // You can now use carbonFootprint and breakdown data as needed
        // For example, store them in variables, send to API, or display in UI
      } catch (e) {
        print('Error calculating carbon footprint: $e');
      }

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Form submitted successfully! JSON data generated.'),
      //     backgroundColor: Colors.green,
      //     duration: Duration(seconds: 2),
      //   ),
      // );
    }
  }

  Future<void> _saveOutputToFile(Map<String, dynamic> outputData) async {
    try {
      final Directory documentsDir = Directory.systemTemp;
      final String filePath = '${documentsDir.path}/output.json';

      final String jsonString =
          const JsonEncoder.withIndent('  ').convert(outputData);

      final File file = File(filePath);
      await file.writeAsString(jsonString);

      print('✅ Output saved to: $filePath');
      print('📄 File contents:');
      print(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Carbon footprint calculated and saved to output.json'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving output file to hidden temp foler$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving output file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Environmental Assessment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.eco,
                      size: 50,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Let\'s  now assess your environmental impact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Post Code Field
              _buildInputField(
                controller: _postCodeController,
                label: 'Post Code',
                hint: 'Enter your post code',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your post code';
                  }
                  if (value.length < 4) {
                    return 'Post code must be at least 4 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Number of People Field
              _buildInputField(
                controller: _peopleController,
                label: 'Number of People in the House',
                hint: 'Enter number of people',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of people';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Number of Motor Vehicles
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Number of Motor Vehicles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$_numberOfVehicles',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_numberOfVehicles > 0) {
                                _numberOfVehicles--;
                                _updateVehicleTypes();
                              }
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _numberOfVehicles++;
                              _updateVehicleTypes();
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    if (_numberOfVehicles > 0) ...[
                      const SizedBox(height: 15),
                      Text(
                        'Vehicle Types:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: List.generate(_numberOfVehicles, (index) {
                          final isGas = _vehicleTypes[index] == 'Gas';
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGas
                                      ? Icons.local_gas_station
                                      : Icons.electric_car,
                                  size: 16,
                                  color: isGas
                                      ? Colors.orange[700]
                                      : Colors.blue[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Vehicle ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isGas ? 'Gas' : 'EV',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isGas
                                        ? Colors.orange[700]
                                        : Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            selected: true,
                            onSelected: (selected) {
                              setState(() {
                                _vehicleTypes[index] = isGas ? 'EV' : 'Gas';
                              });
                            },
                            selectedColor:
                                isGas ? Colors.orange[100] : Colors.blue[100],
                            backgroundColor: Colors.grey[200],
                            side: BorderSide(
                              color: isGas
                                  ? Colors.orange[300]!
                                  : Colors.blue[300]!,
                              width: 2,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap each vehicle chip to toggle between Gas and EV',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Trips per Week Field
              _buildInputField(
                controller: _tripsController,
                label: 'Number of Trips per Week',
                hint: 'Enter number of trips',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of trips';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Dietary Type
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dietary Type on Average',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _dietaryOptions.map((option) {
                        return ChoiceChip(
                          label: Text(option),
                          selected: _dietaryType == option,
                          onSelected: (selected) {
                            setState(() {
                              _dietaryType = option;
                            });
                          },
                          selectedColor: Colors.green[200],
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Solar Panels Question
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Do you have solar panels at your house?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Yes'),
                            leading: Radio<bool>(
                              value: true,
                              groupValue: _hasSolarPanels,
                              onChanged: (value) {
                                setState(() {
                                  _hasSolarPanels = value!;
                                });
                              },
                              activeColor: Colors.green,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('No'),
                            leading: Radio<bool>(
                              value: false,
                              groupValue: _hasSolarPanels,
                              onChanged: (value) {
                                setState(() {
                                  _hasSolarPanels = value!;
                                });
                              },
                              activeColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Submit Assessment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: keyboardType == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.green[600]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.green[50],
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
