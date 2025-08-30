#!/usr/bin/env python3
import argparse, json, os, sys
from typing import Any, Dict
from openai import OpenAI

# -------- Prompt template (word-for-word from your spec) --------
PROMPT_TEMPLATE = """You are a household carbon advisor. 
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
- Actions must be personalised to the household’s JSON inputs.
- Actions must always be easy, low-cost, and immediately achievable.
- No major investments or disruptive changes (❌ no “buy an EV”, ❌ no “install solar panels”, ❌ no “move house”).
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
"""

# -------- Functions --------
def load_input(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    required = {"postcode","adults","cars","fuel_type","trips_per_week","diet","solar"}
    missing = required - set(data.keys())
    if missing:
        raise ValueError(f"Missing required fields: {sorted(missing)}")
    return data

def call_model(prompt: str, model: str) -> Dict[str, Any]:
    client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
    resp = client.chat.completions.create(
        model=model,
        temperature=0,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": "You are a household carbon advisor."},
            {"role": "user", "content": prompt},
        ],
    )
    content = resp.choices[0].message.content
    return json.loads(content)

def main():
    parser = argparse.ArgumentParser(description="Generate 8 easy carbon actions from a household JSON.")
    parser.add_argument("input_json", help="Path to input JSON file.")
    parser.add_argument("output_json", help="Path to write output JSON file.")
    parser.add_argument("--model", default=os.environ.get("OPENAI_MODEL", "gpt-4o-mini"),
                        help="OpenAI model name (default from OPENAI_MODEL or gpt-4o-mini).")
    args = parser.parse_args()

    if not os.environ.get("OPENAI_API_KEY"):
        print("ERROR: Please set OPENAI_API_KEY in your environment.", file=sys.stderr)
        sys.exit(1)

    # 1) Read input
    household = load_input(args.input_json)

    # 2) Build prompt + input JSON
    full_prompt = PROMPT_TEMPLATE + json.dumps(household, ensure_ascii=False, indent=2)

    # 3) Call model
    result = call_model(full_prompt, args.model)

    # 4) Write output
    with open(args.output_json, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"Wrote actions to {args.output_json}")

if __name__ == "__main__":
    main()
