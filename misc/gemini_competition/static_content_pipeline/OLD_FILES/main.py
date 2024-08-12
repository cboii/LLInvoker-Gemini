# main.py

import sys
from misc.gemini_competition.static_content_pipeline.src.utils.utils import load_environment
from src.generators import InstructionGenerator

def main():
    load_environment()

    # Constants for the current MODULE and SECTION from command-line arguments
    MODULE = int(sys.argv[1])
    SECTION = int(sys.argv[2])
    LEVEL = int(sys.argv[3]) # LEVELS = ["A1", "A2"] for example

    generator = InstructionGenerator(LEVEL)
    print(f"Generating content for Module {MODULE}, Section {SECTION}...")
    response_json = generator.generate_content(MODULE, SECTION)
    generator.save_json_to_file(response_json, MODULE, SECTION)

if __name__ == "__main__":
    main()