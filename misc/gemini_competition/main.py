import firebase_admin
from firebase_admin import credentials, firestore, auth
from dotenv import load_dotenv
import os
import json

# Load the environment variables
load_dotenv()


os.environ["FIRESTORE_EMULATOR_HOST"] = "localhost:8080"

class FirebaseInterface:

    def __init__(self, service_account_path='./serviceAccount.json'):
        # Initialize Firestore DB
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        self.db = firestore.client()


    def add_user(self, email, password, display_name, premium=False):
        # Create a new user
        user = auth.create_user(
            email=email,
            email_verified=False,
            password=password,
            display_name=display_name,
            disabled=False
        )
        if premium:
            auth.set_custom_user_claims(user.uid, {"stripeRole": "premium"})

            

    def update_module(self, language_pair, level, module, module_data_directory, titles: list = None):
        # Directory containing JSON files
        section_dirs = [f for f in os.listdir(module_data_directory)]
        for i, section_dir in enumerate(section_dirs):
            section_data_directory = os.path.join(module_data_directory, section_dir)
            section_id = section_dir
            title = titles[i] if titles else section_dir
            self.db.collection(f"courses/{language_pair}/levels/{level}/modules/{module}/sections").document(section_id).set({"title": title})
            # Directory containing JSON files
            json_files = [f for f in os.listdir(section_data_directory) if f.endswith('.json')]
            for json_file in json_files:
                file_path = os.path.join(section_data_directory, json_file)
                print(f"Processing file: {file_path}")
                try:
                    with open(file_path, 'r') as f:
                        data = json.load(f)
                        print(f"Successfully loaded JSON data from {file_path}")
                        self.db.collection(f"courses/{language_pair}/levels/{level}/modules/{module}/sections/{section_id}/chapters").document(str(data["chapter"])).set(data)
                except json.JSONDecodeError as e:
                    print(f"JSONDecodeError in file {file_path}: {e}")
                except Exception as e:
                    print(f"Error processing file {file_path}: {e}")


    def add_module(self, language_pair, language, level, module, module_title):
        self.db.collection("courses").document(language_pair).set({"language": language})
        self.db.collection(f"courses/{language_pair}/levels").document(f"{level}").set({"level": level, "language": language, "languagePair": language_pair})
        # Add the module to the Firestore database
        self.db.collection(f"courses/{language_pair}/levels/{level}/modules").document(module).set({"title": module_title})



    def get_collection(self, collection_name):
        # Fetch all the documents in the collection
        docs = self.db.collection(collection_name).stream()

        # Create a list to store the documents
        documents = []
        for doc in docs:
            temp = doc.to_dict()
            temp['id'] = doc.id
            temp['reference'] = doc.reference
            print(f"{temp['id']} => {temp}")
            documents.append(temp)

        return documents



if __name__ == '__main__':

    interface = FirebaseInterface()

    section_titles = [["Section 1: Basic Greetings", "Section 2: Polite Phrases", "Section 3: Introducing Yourself", "Section 4: Asking and Answering Questions about Yourself", "Section 5: Review and Reinforcement", "Section 6: Review and Reinforcement"],
                      ["Section 1: Numbers (0-20)", "Section 2: Numbers (21-100)","Section 3: Basic Colors","Section 4: Basic Shapes","Section 5: Ordinal Numbers (1st-10th)","Section 6: Review and Reinforcement 1","Section 7: Review and Reinforcement 2"],
                      ["Section 1: Family Members", "Section 2: Describing Relationships", "Section 3: Talking About Friends", "Section 4: Describing People (Basic Adjectives)", "Section 5: Review and Reinforcement 1"]]
    section_titles.reverse()


    language_pair = 'eng_de'
    language = 'English-German'
    level = 'A1'
    module_title = ['Getting Started with the basics', 'Colors, Shapes and Numbers', 'Family and Friends']
    module_title.reverse()
    module_folder = '../modules/eng_de_A1'

    for i, module in enumerate(os.listdir(module_folder)):
        print(module)
        interface.add_module(language_pair, language, level, module, module_title=module_title[i])
        interface.update_module(language_pair, level, module, os.path.join(module_folder, module), section_titles[i])

    language_pair = 'eng_fr'
    language = 'English-French'
    level = 'A1'
    module_folder = '../modules/eng_fr_A1'

    for i, module in enumerate(os.listdir(module_folder)):
        print(module)
        interface.add_module(language_pair, language, level, module, module_title=module_title[i])
        interface.update_module(language_pair, level, module, os.path.join(module_folder, module), section_titles[i])

    
    language_pair = 'fr_de'
    language = 'Français-Allemand'
    level = 'A1'
    module_title = ['Les bases', 'Les couleurs, les formes et les chiffres', 'La famille et les amis']
    module_title.reverse()
    module_folder = '../modules/fr_de_A1'

    for i, module in enumerate(os.listdir(module_folder)):
        print(module)
        interface.add_module(language_pair, language, level, module, module_title=module_title[i])
        interface.update_module(language_pair, level, module, os.path.join(module_folder, module))