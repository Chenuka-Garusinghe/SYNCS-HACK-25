import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../utils/carbon_calculator.dart';
import '../utils/carbon_actions.dart';
import 'chooseAvatar_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();
  final TextEditingController _tripsController = TextEditingController();

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
    String dietType = switch (_dietaryType) {
      'Meat Heavy' => 'meat_heavy',
      'Vegetarian' => 'vegetarian',
      'Vegan' => 'vegan',
      _ => 'normal',
    };

    final List<String> fuelTypes =
        _vehicleTypes.map((v) => v == 'Gas' ? 'petrol' : 'ev').toList();

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

  Map<String, dynamic> _generateCarbonActionsData() {
    String dietType = switch (_dietaryType) {
      'Meat Heavy' => 'meat_heavy',
      'Vegetarian' => 'vegetarian',
      'Vegan' => 'vegan',
      _ => 'normal',
    };

    String primaryFuelType = 'petrol';
    if (_numberOfVehicles > 0) {
      final petrolCount = _vehicleTypes.where((t) => t == 'Gas').length;
      final evCount = _vehicleTypes.where((t) => t == 'EV').length;
      primaryFuelType = petrolCount >= evCount ? 'petrol' : 'ev';
    }

    return {
      "postcode": _postCodeController.text,
      "adults": int.tryParse(_peopleController.text) ?? 0,
      "cars": _numberOfVehicles,
      "fuel_type": primaryFuelType,
      "trips_per_week": int.tryParse(_tripsController.text) ?? 0,
      "diet": dietType,
      "solar": _hasSolarPanels ? "yes" : "no",
    };
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final jsonData = _generateJsonData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      print('Generated JSON ------>\n$jsonString');

      try {
        final double carbonFootprint =
            CarbonCalculator.calculateAnnualCo2e(jsonData);
        final Map<String, dynamic> breakdown =
            CarbonCalculator.getCalculationBreakdown(jsonData);

        print('\n=== CARBON FOOTPRINT CALCULATION ===');
        print('Annual CO2e: $carbonFootprint kg');

        final outputData = {
          'annual_total_kgco2e': carbonFootprint,
          'breakdown': breakdown['breakdown'],
          'input_data': jsonData,
          'calculation_timestamp': DateTime.now().toIso8601String(),
        };

        await _saveOutputToFile(outputData);

        if (mounted) {
          _showSummaryPopup(jsonData, carbonFootprint, breakdown);
        }

        // Generate actions in the background while the dialog is visible
        // Don't auto-navigate - let user control when to proceed
        try {
          await _generateCarbonActions();
        } catch (e) {
          // ignore: avoid_print
          print('Error generating carbon actions: $e');
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error calculating carbon footprint: $e');
      }
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

      // ignore: avoid_print
      print('✅ Output saved to: $filePath');
      // ignore: avoid_print
      print('📄 File contents:\n$jsonString');

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
      // ignore: avoid_print
      print('❌ Error saving output file to hidden temp folder $e');
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

  Future<void> _generateCarbonActions() async {
    try {
      final Directory documentsDir = Directory.systemTemp;
      final String outputJsonPath = '${documentsDir.path}/output.json';
      final String actionsJsonPath = '${documentsDir.path}/actions.json';

      // ignore: avoid_print
      print('\n🔄 Generating carbon actions using OpenAI API...');

      final Map<String, dynamic> carbonActionsData =
          _generateCarbonActionsData();
      final String carbonActionsJsonString =
          const JsonEncoder.withIndent('  ').convert(carbonActionsData);

      final File outputFile = File(outputJsonPath);
      await outputFile.writeAsString(carbonActionsJsonString);

      // ignore: avoid_print
      print(
          '📄 Created output.json for carbon actions:\n$carbonActionsJsonString');

      await CarbonActionsGenerator.processOutputAndGenerateActions(
        outputJsonPath: outputJsonPath,
        actionsJsonPath: actionsJsonPath,
        useOpenAI: true,
      );

      final File actionsFile = File(actionsJsonPath);
      if (await actionsFile.exists()) {
        final String actionsContent = await actionsFile.readAsString();
        final Map<String, dynamic> actionsData = jsonDecode(actionsContent);

        // ignore: avoid_print
        print('\n🎯 GENERATED CARBON ACTIONS:\n${'=' * 50}');
        final List<dynamic> actions = actionsData['actions'];
        for (int i = 0; i < actions.length; i++) {
          // ignore: avoid_print
          print('${i + 1}. ${actions[i]}');
        }
        // ignore: avoid_print
        print('${'=' * 50}\n✅ Actions saved to: $actionsJsonPath');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Carbon actions generated successfully!'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // ignore: avoid_print
        print('❌ Actions file not found at: $actionsJsonPath');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error generating carbon actions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating carbon actions: $e'),
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
                    Icon(Icons.eco, size: 50, color: Colors.green[600]),
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

              // Vehicles
              _buildVehiclesCard(),

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
              _buildDietCard(),

              const SizedBox(height: 20),

              // Solar
              _buildSolarCard(),

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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _buildVehiclesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
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
          const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            Text(
              'Vehicle Types:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: List.generate(_numberOfVehicles, (index) {
                final isGas = _vehicleTypes[index] == 'Gas';
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGas ? Icons.local_gas_station : Icons.electric_car,
                        size: 16,
                        color: isGas ? Colors.orange[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Vehicle ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isGas ? 'Gas' : 'EV',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isGas ? Colors.orange[700] : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  selected: true,
                  onSelected: (_) {
                    setState(() {
                      _vehicleTypes[index] = isGas ? 'EV' : 'Gas';
                    });
                  },
                  selectedColor: isGas ? Colors.orange[100] : Colors.blue[100],
                  backgroundColor: Colors.grey[200],
                  side: BorderSide(
                    color: isGas ? Colors.orange[300]! : Colors.blue[300]!,
                    width: 2,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
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
    );
  }

  Widget _buildDietCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _dietaryOptions.map((option) {
              return ChoiceChip(
                label: Text(option),
                selected: _dietaryType == option,
                onSelected: (_) => setState(() => _dietaryType = option),
                selectedColor: Colors.green[200],
                backgroundColor: Colors.grey[200],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Yes'),
                  leading: Radio<bool>(
                    value: true,
                    groupValue: _hasSolarPanels,
                    onChanged: (value) => setState(() {
                      _hasSolarPanels = value!;
                    }),
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
                    onChanged: (value) => setState(() {
                      _hasSolarPanels = value!;
                    }),
                    activeColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      );

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
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

  // ---------- Summary Dialog (no scroll, no overflow) ----------

  void _showSummaryPopup(Map<String, dynamic> jsonData, double carbonFootprint,
      Map<String, dynamic> breakdown) {
    final size = MediaQuery.of(context).size;

    // Mild text scale down on short screens to guarantee fit without scrolling.
    final textScale = size.height < 720 ? 0.95 : 1.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: textScale),
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: FractionallySizedBox(
              widthFactor: 0.95,
              heightFactor: 0.78, // Take ~78% of height so we never overflow
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Header (compact)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.eco, color: Colors.green[700], size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your Environmental Assessment Summary',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Carbon Footprint (compact)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your Annual Carbon Footprint',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${carbonFootprint.toStringAsFixed(1)} kg CO₂e',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Breakdown (fixed height, compact rows)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breakdown by Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildBreakdownItem(
                            'Transport',
                            ((breakdown['breakdown']['transport']
                                            ['annual_total_kgco2e'] as num?)
                                        ?.toDouble() ??
                                    0.0)
                                .toStringAsFixed(1),
                            ((breakdown['breakdown']['transport']['percentage']
                                            as num?)
                                        ?.toDouble() ??
                                    0.0)
                                .toStringAsFixed(1),
                            Icons.directions_car,
                            Colors.blue,
                          ),
                          const SizedBox(height: 6),
                          _buildBreakdownItem(
                            'Diet',
                            ((breakdown['breakdown']['diet']
                                            ['annual_total_kgco2e'] as num?)
                                        ?.toDouble() ??
                                    0.0)
                                .toStringAsFixed(1),
                            ((breakdown['breakdown']['diet']['percentage']
                                            as num?)
                                        ?.toDouble() ??
                                    0.0)
                                .toStringAsFixed(1),
                            Icons.restaurant,
                            Colors.green,
                          ),
                          const SizedBox(height: 6),
                          _buildBreakdownItem(
                            'Electricity',
                            ((breakdown['breakdown']['electricity']
                                            ['annual_total_kgco2e'] as num?)
                                        ?.toDouble() ??
                                    0.0)
                                .toStringAsFixed(1),
                            ((breakdown['breakdown']['electricity']
                                            ['percentage'] as num?)
                                        ?.toDouble() ??
                                    0.0)
                                .toStringAsFixed(1),
                            Icons.electric_bolt,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Input summary as compact chips (takes minimal vertical space)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Based on your input:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoChip('${jsonData['adults'] ?? 0} adults'),
                              _infoChip(
                                  '${jsonData['cars'] ?? 0} car${(jsonData['cars'] ?? 0) == 1 ? '' : 's'} (${_formatFuelTypes(jsonData['fuel_type'])})'),
                              _infoChip(
                                  '${jsonData['trips_per_week'] ?? 0} trips/week'),
                              _infoChip('${jsonData['diet'] ?? 'normal'} diet'),
                              _infoChip('Solar: ${jsonData['solar'] ?? 'no'}'),
                              _infoChip(
                                  'Postcode: ${jsonData['postcode'] ?? 'N/A'}'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    _buildNextButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.green[800],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String value, String percentage,
      IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '$value kg CO₂e ($percentage%)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatFuelTypes(dynamic fuelTypes) {
    if (fuelTypes == null) return 'N/A';
    if (fuelTypes is List) {
      if (fuelTypes.isEmpty) return 'none';
      final Map<String, int> fuelCounts = {};
      for (final f in fuelTypes.cast<String>()) {
        fuelCounts[f] = (fuelCounts[f] ?? 0) + 1;
      }
      if (fuelCounts.length == 1) return fuelCounts.keys.first;
      return fuelCounts.entries.map((e) => '${e.value} ${e.key}').join(', ');
    }
    return fuelTypes.toString();
  }

  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Close the popup first
            Navigator.of(context).pop();
            // Then navigate to the next screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => const ChooseAvatarScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
