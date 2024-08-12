cd ../misc/gemini_competition

REQUIREMENTS="requirements.txt"
if [ -f "$REQUIREMENTS" ]; then
    pip install -r requirements.txt
else
    echo "$REQUIREMENTS not found. Please make sure it is in the ../misc/gemini_competition directory."
fi

cd ../../cloud_functions_node/functions
npm install

echo "Environment setup completed successfully."