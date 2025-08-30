import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terrago/screens/chooseAvatar_screen.dart';
import 'package:terrago/screens/game_screen.dart';

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      print('Post Code: ${_postCodeController.text}');
      print('Number of People: ${_peopleController.text}');
      print('Number of Vehicles: $_numberOfVehicles');
      print('Vehicle Types: $_vehicleTypes');
      print('Trips per Week: ${_tripsController.text}');
      print('Dietary Type: $_dietaryType');
      print('Has Solar Panels: $_hasSolarPanels');

      // Navigate to next screen or show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ChooseAvatarScreen()),
      );
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
                      'Let\'s assess your environmental impact',
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
