# Gemini Project

This project demonstrates how to set up and use the Gemini API with Python.

## Setup

0. Go to 
   ```bash
   cd misc/gemini_competition/static_content_pipeline
   ```

1. Create and activate a virtual environment:
   ```bash
   python -m venv gemini_env
   source gemini_env/bin/activate  # On Windows use `gemini_env\Scripts\activate`
   ```

2. Install dependencies:
    ```bash
    pip install -r requirements.txt
   ```


4. Set the environment variable for your API key (Unix/Linux/macOS):
    - [Get the API key here](https://console.cloud.google.com/apis/credentials?referrer=search&authuser=1&hl=en&project=gemini-competition-426114) (STATIC_CONTENT_PIPELINE)

   ```bash
    export GOOGLE_API_KEY=your_api_key_here
   ```


3. If you want to run the script without adaptation:
   ```bash
    python main.py

   ```