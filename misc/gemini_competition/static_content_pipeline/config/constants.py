# config/constants.py

import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

# ANSI escape codes for colors
LIGHT_BLUE = '\033[94m'
MATTE_GREEN = '\033[92m'
COOL_PINK = '\033[95m'
RESET = '\033[0m'

# Google API Key
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
genai.configure(api_key=GOOGLE_API_KEY)

if not GOOGLE_API_KEY:
    raise ValueError("Please set the GOOGLE_API_KEY environment variable.")
