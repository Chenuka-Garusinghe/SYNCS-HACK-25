import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Represents a household's carbon footprint data
class HouseholdData {
  final String postcode;
  final int adults;
  final int cars;
  final String fuelType;
  final int tripsPerWeek;
  final String diet;
  final String solar;

  HouseholdData({
    required this.postcode,
    required this.adults,
    required this.cars,
    required this.fuelType,
    required this.tripsPerWeek,
    required this.diet,
    required this.solar,
  });

  Map<String, dynamic> toJson() {
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

  factory HouseholdData.fromJson(Map<String, dynamic> json) {
    return HouseholdData(
      postcode: json['postcode'] as String,
      adults: json['adults'] as int,
      cars: json['cars'] as int,
      fuelType: json['fuel_type'] as String,
      tripsPerWeek: json['trips_per_week'] as int,
      diet: json['diet'] as String,
      solar: json['solar'] as String,
    );
  }

  void validate() {
    final required = [
      'postcode',
      'adults',
      'cars',
      'fuel_type',
      'trips_per_week',
      'diet',
      'solar'
    ];
    final missing =
        required.where((field) => !toJson().containsKey(field)).toList();
    if (missing.isNotEmpty) {
      throw ArgumentError('Missing required fields: ${missing.join(', ')}');
    }
  }
}

class CarbonActionsResponse {
  final List<String> actions;

  CarbonActionsResponse({required this.actions});

  Map<String, dynamic> toJson() {
    return {
      'actions': actions,
    };
  }

  factory CarbonActionsResponse.fromJson(Map<String, dynamic> json) {
    return CarbonActionsResponse(
      actions: List<String>.from(json['actions'] as List),
    );
  }
}

class CarbonActionsGenerator {
  static const String _promptTemplate = '''You are a household carbon advisor. 
Your job is to take household details (from a JSON input) and output exactly 8 small, realistic lifestyle changes 
that the family could adopt to slightly reduce their annual carbon footprint. 

## CONTRACT
- Always return valid JSON with this structure:

{
  "actions": [
    "Action 1",
    "Action 2",
    "Action 3",
    "Action 4",
    "Action 5",
    "Action 6",
    "Action 7",
    "Action 8"
  ]
}

- Each "Action" must be one short, simple sentence.
- Actions must be personalised to the household's JSON inputs.
- Actions must always be easy, low-cost, and immediately achievable.
- No major investments or disruptive changes (❌ no "buy an EV", ❌ no "install solar panels", ❌ no "move house").
- There must be exactly 8 actions in every output.
- Use temperature=0 for deterministic results.

## INPUT FORMAT (from the user/file)
{
  "postcode": string,
  "adults": number,
  "cars": number,
  "fuel_type": "petrol" | "diesel" | "ev",
  "trips_per_week": number,
  "diet": "meat_heavy" | "normal" | "flexitarian" | "vegetarian" | "vegan",
  "solar": "yes" | "no"
}

## PSEUDOCODE FOR ACTION SELECTION
1. Initialise empty list `actions = []`.

2. Transport-related actions:
   - If cars > 0 and trips_per_week > 0:
       - Suggest replacing 1 short car trip/week with walking or cycling.
       - Suggest combining errands to cut down car trips.
       - If fuel_type != "ev": suggest fuel-saving habits (gentle acceleration, tyre pressure).
   - If trips_per_week is high (>5): suggest public transport once a week.
   - If cars == 0: suggest keeping up with walking/public transport.

3. Diet-related actions:
   - If diet == "meat_heavy" or "normal": suggest one meat-free meal per week.
   - If diet == "flexitarian": suggest adding one more vegetarian meal per week.
   - If diet == "vegetarian" or "vegan": suggest seasonal/local produce to reduce transport footprint.

4. Electricity-related actions:
   - If solar == "no": suggest switching off unused appliances.
   - Always: suggest washing clothes in cold water.
   - Always: suggest air drying laundry once per week instead of dryer.
   - Always: suggest turning off lights when leaving rooms.

5. Household general:
   - Suggest using reusable bags and bottles.
   - Suggest shorter showers (cut 1 minute).
   - Suggest filling kettle only as needed.

6. Select the 8 most relevant, easy actions based on the above rules.
7. Return them as the JSON contract.

Input:
''';

  static CarbonActionsResponse generateActions(HouseholdData household) {
    final List<String> actions = <String>[];

    if (household.cars > 0 && household.tripsPerWeek > 0) {
      actions
          .add('Replace one short car trip per week with walking or cycling');
      actions.add('Combine errands to reduce the number of car trips');
      if (household.fuelType != 'ev') {
        actions.add(
            'Practice fuel-efficient driving habits like gentle acceleration');
        actions.add(
            'Check and maintain proper tyre pressure for better fuel efficiency');
      }
    }
    if (household.tripsPerWeek > 5) {
      actions.add('Use public transport once a week instead of driving');
    }
    if (household.cars == 0) {
      actions
          .add('Continue using walking and public transport for daily needs');
    }

    if (household.diet == 'meat_heavy' || household.diet == 'normal') {
      actions.add('Have one meat-free meal per week');
    }
    if (household.diet == 'flexitarian') {
      actions.add('Add one more vegetarian meal to your weekly routine');
    }
    if (household.diet == 'vegetarian' || household.diet == 'vegan') {
      actions.add(
          'Choose seasonal and locally produced food to reduce transport footprint');
    }

    if (household.solar == 'no') {
      actions.add('Switch off unused appliances and electronics');
    }
    actions.add('Wash clothes in cold water to save energy');
    actions.add('Air dry laundry once per week instead of using the dryer');
    actions.add('Turn off lights when leaving rooms');

    actions.add('Use reusable shopping bags and water bottles');
    actions.add('Reduce shower time by one minute to save water and energy');
    actions.add('Only fill the kettle with the amount of water you need');

    while (actions.length < 8) {
      actions.add('Turn off standby mode on electronics when not in use');
    }
    if (actions.length > 8) {
      actions.removeRange(8, actions.length);
    }

    return CarbonActionsResponse(actions: actions);
  }

  static String buildPrompt(HouseholdData household) {
    return _promptTemplate + jsonEncode(household.toJson());
  }

  static Future<HouseholdData> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      final household = HouseholdData.fromJson(json);
      household.validate();
      return household;
    } catch (e) {
      throw Exception('Failed to load household data: $e');
    }
  }

  static Future<void> saveToFile(
      CarbonActionsResponse response, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(jsonEncode(response.toJson()));
    } catch (e) {
      throw Exception('Failed to save carbon actions: $e');
    }
  }

  static CarbonActionsResponse fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CarbonActionsResponse.fromJson(json);
    } catch (e) {
      throw Exception('Failed to parse JSON: $e');
    }
  }

  static String toJsonString(CarbonActionsResponse response) {
    return jsonEncode(response.toJson());
  }

  static Future<CarbonActionsResponse> callOpenAI(
      HouseholdData household) async {
    try {
      await dotenv.load();

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      final model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY not found in environment variables');
      }

      final prompt = buildPrompt(household);

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'temperature': 0,
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content': 'You are a household carbon advisor.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return fromJsonString(content);
      } else {
        throw Exception(
            'OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to call OpenAI API: $e');
    }
  }

  static Future<void> processOutputAndGenerateActions({
    required String outputJsonPath,
    required String actionsJsonPath,
    bool useOpenAI = true,
  }) async {
    try {
      final household = await loadFromFile(outputJsonPath);

      CarbonActionsResponse actions;

      if (useOpenAI) {
        actions = await callOpenAI(household);
      } else {
        actions = generateActions(household);
      }
      await saveToFile(actions, actionsJsonPath);

    } catch (e) {
      throw Exception('Failed to process output and generate actions: $e');
    }
  }
}
