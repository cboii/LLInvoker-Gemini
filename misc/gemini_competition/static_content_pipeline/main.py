from src.generators.sectionGenerator import SectionGenerator
import sys
from config.constants import LIGHT_BLUE, MATTE_GREEN, COOL_PINK, RESET

# Default values and valid options
default_module = 1
default_section = 1
default_level = "A1"
default_amount_of_chapters = 15

valid_modules = list(range(1, 11))  # Modules 1 to 10
valid_sections = list(range(1, 11))  # Sections 1 to 10
valid_levels = ["A1", "A2"]
valid_amount_of_chapters = list(range(1, 21))  # Chapters 1 to 20

def validate_or_default(value, valid_options, default):
    if value in valid_options:
        return value
    else:
        print(f"{COOL_PINK}Invalid value: {value}. Using default: {default}{RESET}")
        return default

# Check if arguments are provided and validate them, otherwise use default values
try:
    module = validate_or_default(int(sys.argv[1]), valid_modules, default_module) if len(sys.argv) > 1 else default_module
except ValueError:
    print(f"{COOL_PINK}Invalid value for module. Using default: {default_module}{RESET}")
    module = default_module

try:
    section = validate_or_default(int(sys.argv[2]), valid_sections, default_section) if len(sys.argv) > 2 else default_section
except ValueError:
    print(f"{COOL_PINK}Invalid value for section. Using default: {default_section}{RESET}")
    section = default_section

try:
    level = validate_or_default(sys.argv[3], valid_levels, default_level) if len(sys.argv) > 3 else default_level
except ValueError:
    print(f"{COOL_PINK}Invalid value for level. Using default: {default_level}{RESET}")
    level = default_level

try:
    amount_of_chapters = validate_or_default(int(sys.argv[4]), valid_amount_of_chapters, default_amount_of_chapters) if len(sys.argv) > 4 else default_amount_of_chapters
except ValueError:
    print(f"{COOL_PINK}Invalid value for amount of chapters. Using default: {default_amount_of_chapters}{RESET}")
    amount_of_chapters = default_amount_of_chapters

print(f"{LIGHT_BLUE}Module: {module}, Section: {section}, Level: {level}, Amount of Chapters: {amount_of_chapters}{RESET}")



# Create an instance of SectionGenerator
sectionGenerator = SectionGenerator(amount_of_chapters)

# Generate the section
sectionGenerator.generate_section(module, section, level)