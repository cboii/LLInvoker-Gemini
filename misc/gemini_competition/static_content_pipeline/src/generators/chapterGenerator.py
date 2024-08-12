import json
import google.generativeai as genai
from config.constants import LIGHT_BLUE, MATTE_GREEN, COOL_PINK, RESET
from config.courses.eng_de.constants import AVOID_JSON
from config.courses.eng_de.constants import COURSE, ORIGIN, LANGUAGE
import os


COURSE = "eng_de"
ORIGIN = "english"
LANGUAGE = "german"

class ChapterGenerator():

    example = ""

    # Load the JSON file from the path
    def load_json(self, path):
        with open(path, 'r') as file:
            data = json.load(file)
        return data

    def __init__(self):
        current_dir = os.path.dirname(os.path.realpath(__file__))
        self.json_type_structure = self.load_json(os.path.join(current_dir, 'exercise_types.json'))

    def create_system_instruction(self, module, section, level):
        return f"""
          **Your Role:**

          - You are a virtual language teacher for students of {ORIGIN} learning {LANGUAGE} at level {level}.
          - Your goal is to create a JSON file with one exercise chapter for module {module} section {section} at level {level}.
              
          **Your task is to generate a New Chapter based on the given information**
          """

    def generate_chapter(self, module, section, type, chapter_number, level, chapter_description):
        match type:
            case 0:
                example = self.json_type_structure['chapters'][0]
                self.example = example
            case 1:
                example = self.json_type_structure['chapters'][1]
                self.example = example
            case 2:
                example = self.json_type_structure['chapters'][2]
                self.example = example
            case 3:
                example = self.json_type_structure['chapters'][3]
                self.example = example
            case 4:
                example = self.json_type_structure['chapters'][4]
                self.example = example
            case 5:
                example = self.json_type_structure['chapters'][5]
                self.example = example
            case 6:
                example = self.json_type_structure['chapters'][6]
                self.example = example
            case 7:
                example = self.json_type_structure['chapters'][7]
                self.example = example
            case _:
                print("Invalid type")

        
        instruction = self.create_system_instruction(module, section, level)
        model = genai.GenerativeModel(
            model_name="gemini-1.5-pro",
            system_instruction=instruction,
            generation_config={"response_mime_type": "application/json"}
        )
        response = model.generate_content(
            f"Generate a chapter of type {type} for module {module} section {section} with exercises for students of {ORIGIN} learning {LANGUAGE} at level {level}. The chapter number is {chapter_number}. The chapter description and content is as follows: {chapter_description}. Here is an exmaple for the JSON structure: {self.example}. The chapter content should match the amount of the examplary content. Please avoid the mistakes mentioned in the JSON structure: {AVOID_JSON}"
        )
        
        if response.text is None:
            # TODO if this ever happends need to implement retry logic
            print(f"{COOL_PINK}No response from the Gemini API. Exiting.{RESET}")
            return
    
        try:
            response_json = json.loads(response.text)
            print(response.text)
        except json.JSONDecodeError as e:
            print(f"{COOL_PINK}Failed to parse JSON: {e}{RESET}")
            print("Response text was:", response.text)
            print(f"{LIGHT_BLUE}Reasking for the correct JSON format...{RESET}")
        
        self.save_json_to_file(response_json, module=module, section=section, level=level, chapter=chapter_number)
        
        return response_json
    

    def save_json_to_file(self, response, module, section, level, chapter):
        if response is None:
            print("No valid JSON to save. Exiting.")
            return

        directory_path = f"../../modules/{COURSE}_{level}/module{module}/sections/section{section}"
        os.makedirs(directory_path, exist_ok=True)
        file_name = f"chapter_{chapter}.json"
        file_path = os.path.join(directory_path, file_name)
        
        try:
            with open(file_path, 'w') as json_file:
                json.dump(response, json_file, indent=4)
            print(f"{MATTE_GREEN}Response saved to {file_path}{RESET}")
        except Exception as e:
            print(f"{COOL_PINK}Failed to save the response to the file: {e}{RESET}")
        

# This is only used when the script is run directly
if __name__ == "__main__":
    module = 1
    section = 2
    type = 5
    chapter_number = 1
    level = "A1"

    chapter_generator = ChapterGenerator()
    response = chapter_generator.generate_chapter(module=module, section=section, type=type, chapter_number=chapter_number, level=level)