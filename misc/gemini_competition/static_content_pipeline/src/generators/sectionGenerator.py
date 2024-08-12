import src.generators.chapterGenerator as chapterGenerator
import json
import google.generativeai as genai
from config.constants import LIGHT_BLUE, MATTE_GREEN, COOL_PINK, RESET
from config.courses.eng_de.constants import AVOID_JSON
from config.courses.eng_de.constants import COURSE, ORIGIN, LANGUAGE, PRECONSTRUCT_MODULES
from src.utils import sectionDescriber
import os
import random
import time

SECTION_EXAMPLE = {
    "section": 1,
    "chapters": [
        {
            "title": "...",
            "type": "...",
            "description": "...",
            "vocabulary": ["...", "...", "..."]
        },
        {
            "title": "...",
            "type": "...",
            "description": "...",
            "vocabulary": ["...", "...", "..."]
        }
    ]
}

class SectionGenerator():
    def __init__(self, amount_of_chapters) -> None:
        self.amount_of_chapters = amount_of_chapters
        self.chapterGenerator = chapterGenerator.ChapterGenerator()
        self.sectionDescriber = sectionDescriber.SectionDescriber(amount_of_chapters)

    def create_system_instruction(self, module, section, level, error_message=None):
        sectionDescription = self.sectionDescriber.describe_section(module, section)
        
        instruction = f"""
        Generate a section for module {module} section {section} with exercises for students of {ORIGIN} learning {LANGUAGE} at level {level}. The module is about: {PRECONSTRUCT_MODULES[module-1]}.

        {sectionDescription}

        Return a JSON document with the generated section and the description of each chapter as a title and its content.
        Make sure the structure of the chapters makes sense and is coherent with the module's content. Therefore, you MUST always introduce new vocabulary and verbs (for example the verb 'to be') in type 7 exercises before using it in the rest of the exercises!
        When new words or concepts are introduced, make sure to adapt the rest of the exercises to include them. Every word must appear at least once in an exercise from the section.
        Every word that is used in an exercise needs to be explained in the type 7 exercises first. Do not use words that have not been introduced yet.
        Here is an example of the JSON structure: {SECTION_EXAMPLE}
        """
        if error_message:
            instruction += f"\n\nThe previous attempt resulted in an error: {error_message}. Please ensure the JSON format is correct."
        
        return instruction

    def generate_section(self, module, section, level, max_retries=3):
        retries = 0
        error_message = None
        
        while retries < max_retries:
            instruction = self.create_system_instruction(module, section, level, error_message)
            model = genai.GenerativeModel(
                model_name="gemini-1.5-pro",
                system_instruction=instruction,
                generation_config={"response_mime_type": "application/json"}
            )
            response = model.generate_content(
                f"Generate a section for module {module} with exercises for students of {ORIGIN} learning {LANGUAGE} at level {level}."
            )

            try:
                response_json = json.loads(response.text)
                print(f"{MATTE_GREEN} Successfully generated a whole section with one Gemini API call:{RESET}")
                break  # Exit the loop if successful
            except json.JSONDecodeError as e:
                error_message = str(e)
                print(f"{COOL_PINK}Failed to parse JSON: {e}{RESET}")
                print("Response text was:", response.text)
                print(f"{LIGHT_BLUE}Reasking for the correct JSON format...{RESET}")
                retries += 1
                time.sleep(2)  # Wait before retrying

        if retries == max_retries:
            print(f"{COOL_PINK}Failed to generate a correct JSON after {max_retries} attempts.{RESET}")
            return  # Exit the function if JSON parsing fails after retries

        print(f"{LIGHT_BLUE}Using the generated type and description to generate chapters...{RESET}")
        for i in range(len(response_json['chapters'])):
            type = response_json['chapters'][i]['type']
            # self.chapterGenerator.generate_chapter(module, section, type, i, level, response_json['chapters'][i]['description'])
            # FOR DEBUGGING PURPOSES
            print(f"Generated chapter {i} of type {type} for module {module} section {section} with description: {response_json['chapters'][i]['description']}")
            time.sleep(2)

# This is only used when the script is run directly
if __name__ == "__main__":
    sectionGenerator = SectionGenerator(15)
    sectionGenerator.generate_section(1, 1, "A1")
