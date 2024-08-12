import os
import json
import config.courses.eng_de.constants as constants

current_dir = os.path.dirname(os.path.abspath(__file__))
# TODO ADD MORE HERE IF NEW LEVELS ARE ADDED
# TODO has to be changed if we go from a1 to a2 etc...
dirs = [os.path.join(current_dir, 'levels', 'a1')] #["a1", "a2"]

# Iterate over each directory
for dir in dirs:
    # Iterate over each JSON file in the directory
    for filename in sorted(os.listdir(dir)):
        if filename.endswith(".json"):
            # Construct the full file path
            filepath = os.path.join(dir, filename)
            
            # Read the content of the JSON file
            try:
                with open(filepath, "r") as file:
                    content = json.load(file)  # Load the JSON content
                    
                    # Append the content to the list
                    constants.PRECONSTRUCT_MODULES.append(content)
            except json.JSONDecodeError:
                print(f"Error decoding JSON from file: {filepath}")
            except Exception as e:
                print(f"An unexpected error occurred while reading {filepath}: {e}")