import os
import json
from dotenv import load_dotenv

import google.generativeai as genai


load_dotenv()
# Define the constants for the current COURSE, LEVEL, MODULE, and SECTION
# BEFORE RUNNING THE SCRIPT!
course = "eng_de"
origin = "english"
language = "german"
level = "A1"
module = 1
module_name = "Greetings & Introductions"
section = 2
example_json = """[
    {
        "section": "section1",
        "title": "Module 1: Greetings & Introductions",
        "chapters": [
            {
                "chapter": 0,
                "type": 7,
                "title": "1: Basic Greetings",
                "vocabulary": [{
                    "word": "Hallo",
                    "meaning": "Hello"
                }, {
                    "word": "Guten Morgen",
                    "meaning": "Good morning"
                }, {
                    "word": "Guten Tag",
                    "meaning": "Good afternoon"
                }, {
                    "word": "Guten Abend",
                    "meaning": "Good evening"
                }, {
                    "word": "Auf Wiedersehen",
                    "meaning": "Goodbye"
                }, {
                    "word": "Tschüss",
                    "meaning": "Bye"
                }]
                },
            {
                "chapter": 1,
                "type": 3,
                "title": "2: Fill-in-the-Blank: Greetings",
                "content": {
                    "sentence": "___ (Hello), ___ (Good morning)",
                    "answers": {
                        "Hallo": "correct",
                        "Guten Morgen": "correct",
                        "Guten Tag": "incorrect",
                        "Tschüss": "incorrect"
                    }
                },
                "answers": ["Hallo", "Guten Morgen"]
            },
            {
                "chapter": 2,
                "type": 7,
                "title": "3: Introducing Yourself",
                "vocabulary": [
                    {
                        "word": "Ich heiße",
                        "meaning": "My name is"
                    },
                    {
                        "word": "Wie geht es Ihnen/dir?",
                        "meaning": "How are you?"
                    },
                    {
                        "word": "Gut, danke!",
                        "meaning": "Good, thank you!"
                    },
                    {
                        "word": "und Ihnen/dir?",
                        "meaning": "and you?"
                    },
                    {
                        "word": "Was machen Sie/du?",
                        "meaning": "What are you doing?"
                    }
                ]
            },
            {
                "chapter": 3,
                "type": 2,
                "title": "4: Conjugation: Verb 'sein'",
                "content": [
                    "ich",
                    "du",
                    "er/sie/es",
                    "wir",
                    "ihr",
                    "sie/Sie"
                ],
                "answers": [
                    "bin",
                    "bist",
                    "ist",
                    "sind",
                    "seid",
                    "sind"
                ]
            },
            {
                "chapter": 4,
                "type": 1,
                "title": "5: Fill-in-the-Blank: Introductions",
                "content": "Ich ___ (heißen) Maria. Du ___ (sein) ein Student.",
                "answers": ["heiße", "bist"]
            },
            {
                "chapter": 5,
                "type": 7,
                "title": "6: Personal Pronouns",
                "vocabulary": [{
                    "word": "ich",
                    "meaning": "I"
                }, {
                    "word": "du",
                    "meaning": "you"
                }, {
                    "word": "er",
                    "meaning": "he"
                }, {
                    "word": "sie",
                    "meaning": "she"
                }, {
                    "word": "es",
                    "meaning": "it"
                }, {
                    "word": "wir",
                    "meaning": "we"
                }, {
                    "word": "ihr",
                    "meaning": "you"
                }, {
                    "word": "sie",
                    "meaning": "they"
                }, {
                    "word": "Sie",
                    "meaning": "you"
                }]
            },
            {
                "chapter": 6,
                "type": 1,
                "title": "7: Fill-in-the-Blank: Pronouns and Verbs",
                "content": "___ (I) bin glücklich. ___ (You) bist mein Freund.",
                "answers": ["Ich", "Du"]
            },
            {
                "chapter": 7,
                "type": 0,
                "title": "8: Basic Sentence Structure",
                "content": "Subject-Verb-Object structure. Example: Ich heiße [Subject] Max [Object]."
            },
            {
                "chapter": 8,
                "type": 1,
                "title": "9: Fill-in-the-Blank: Basic Sentences",
                "content": "___ (I) ___ (to be called) Anna.",
                "answers": ["Ich", "heiße"]
            },
            {
                "chapter": 9,
                "type": 4,
                "title": "10: Vocabulary Exercise: Greetings and Introductions",
                "answers": ["Hello", "Good morning", "My name is", "How are you?", "Good, thank you!", "Goodbye"],
                "words": ["Hallo", "Guten Morgen", "Ich heiße", "Wie geht es Ihnen?", "Gut, danke!", "Auf Wiedersehen"]
            },
            {
                "chapter": 10,
                "type": 5,
                "title": "11: Reading Exercise: Greetings and Introductions",
                "content": "Ich heiße Maria. Wie geht es Ihnen? Gut, danke! Ich bin ein Student. Auf Wiedersehen!"
            },
            {
                "chapter": 11,
                "type": 6,
                "title": "12: Question Answering: Dialogue",
                "content": "Hallo, ich heiße Anna. Ich bin zwanzig Jahre alt und komme aus Deutschland. Ich wohne in Berlin. Ich habe einen Hund und eine Katze. Mein Hund heißt Bruno und meine Katze heißt Luna. Ich studiere an der Universität und lerne Deutsch. In meiner Freizeit lese ich gern Bücher und spiele Gitarre. Am Wochenende treffe ich oft meine Freunde im Park. Wir spielen Fußball und haben viel Spaß.",
                "questions": ["Wie heißt der Hund?","Wo wohnt Anna?","Was macht Anna in ihrer Freizeit?"],
                "references": ["Der Hund heißt Bruno.", "Ana wohnt in Berlin.", "Ana liest Bücher und spielt Gitarre in ihrer Freizeit."]
            }
        ]
    }
]

"""
avoid_json = f"""
    einen rot Apfel : it should be einen roten Apfel
    Eins Apfel : It is ein Apfel
    Adding '-e' to nouns to form the plural. Example: Ein Apfel (One apple), Zwei \u00c4pfel (Two apples) : This doesn't make sense.
    Ich habe ___ (One) Apfel. Du hast ___ (Two) B\u00fccher. : Result should be Ich habe einen Apfel. Du hast zwei Bücher.
    Der Himmel ist ___ (blue).  Die Sonne ist ___ (yellow).  Die Banane ist ___ (yellow).  Der Stuhl ist ___ (black). : Avoid repetitions
    Subject-Verb-Object structure. Example: Der Apfel ist [Subject] rot [Object] : Hardly understandable.
    Ein (a, an - masculine), Eine (a, an - feminine).  Example: Ein Apfel (a/an apple), Eine Banane (a/an banana). : An explanation would be better.
    A1 students hardly understand german. Try to give the english version of the phrases at the end so that they understand the meaning.
    Type 6 exercises : Reference should be in {language} and the questions/answers have to be more accurate.
    Wo wohnt Anna? Ich komme aus Berlin : That's not an accurate answer for type 6 exercise.
    Type 0 and 7 : They are not the same. Don't use type 0 and 7 one after the other. Type 0 should introduce new context for example structure of german phrases and type 7 is used for vocabulary.
"""

preconstruct_modules = [
    """Understood! Type 7 exercises will vary in frequency across the sections, similar to Type 0 exercises but focusing solely on vocabulary lists without additional context or explanations. Here’s how the updated modules will be structured to include Type 7 exercises varying from more frequent to very rare:

**Module 1: Basic Greetings and Introductions**
- **Section 1:**
  - Vocabulary: Hallo, Auf Wiedersehen, Bitte, Danke, Ja, Nein, Ich heiße, Wie geht es dir?, Schön dich zu treffen, Bis später.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Wie ist dein Name?, Woher kommst du?, Ich komme aus, Wie alt bist du?, Ich bin [Alter] Jahre alt.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Guten Morgen, Guten Tag, Guten Abend, Gute Nacht, Hab einen schönen Tag.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Lange nicht gesehen, Wie geht's?, Was gibt's Neues?, Mach's gut, Gute Reise.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Ich vermisse dich, Bis bald, Später nachholen, In Kontakt bleiben, Alles Gute.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).

**Module 2: Numbers and Colors**
- **Section 1:**
  - Vocabulary: Eins, Zwei, Drei, Vier, Fünf, Rot, Blau, Grün, Gelb, Schwarz, Weiß.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Sechs, Sieben, Acht, Neun, Zehn, Lila, Braun, Orange, Pink, Grau.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Elf, Zwölf, Dreizehn, Vierzehn, Fünfzehn, Hell [Farbe], Dunkel [Farbe].
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Sechzehn, Siebzehn, Achtzehn, Neunzehn, Zwanzig, Leuchtend [Farbe], Pastell [Farbe].
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Einundzwanzig, Zweiundzwanzig, Dreiundzwanzig, Vierundzwanzig, Fünfundzwanzig, Primärfarben, Sekundärfarben.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).

**Module 3: Family and Friends**
- **Section 1:**
  - Vocabulary: Vater, Mutter, Bruder, Schwester, Freund, Familie, Großvater, Großmutter, Onkel, Tante.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Cousin, Neffe, Nichte, Bester Freund, Nachbar, Elternteil, Geschwister.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Stiefvater, Stiefmutter, Stiefgeschwister, Schwiegereltern, Verwandter.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Patenonkel, Patentante, Patenkind, Pflegeeltern, Vormund.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Adoptiert, Vorfahr, Nachkomme, Blutsverwandter, Großfamilie.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).

**Module 4: Daily Activities**
- **Section 1:**
  - Vocabulary: Aufwachen, Frühstücken, Zur Schule gehen, Lernen, Spielen, Schlafen, Zähne putzen, Lesen, Schreiben, Spazieren gehen.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Duschen, Sich anziehen, Mittagessen, Hausaufgaben machen, Fernsehen, Sport machen, Ins Bett gehen.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Abendessen kochen, Das Haus putzen, Einkaufen gehen, Freunde treffen, Musik hören.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Das Bett machen, Ein Nickerchen machen, Im Internet surfen, Wäsche waschen, Mit dem Hund spazieren gehen.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Die Katze füttern, Die Pflanzen gießen, Den Müll rausbringen, Entspannen, Den Tag planen.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).

**Module 5: Food and Drink**
- **Section 1:**
  - Vocabulary: Apfel, Banane, Brot, Wasser, Milch, Kaffee, Tee, Käse, Huhn, Reis.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Orange, Trauben, Kartoffel, Saft, Limonade, Salat, Rindfleisch, Fisch, Pasta, Suppe.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Erdbeere, Zitrone, Karotte, Joghurt, Eiscreme, Pizza, Burger, Wurst, Sandwich, Ei.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Heidelbeere, Wassermelone, Spinat, Pudding, Pfannkuchen, Waffel, Speck, Muffin, Müsli, Butter.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Avocado, Himbeere, Brokkoli, Smoothie, Schokolade, Sushi, Nudeln, Hummer, Krabbe, Steak.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).

**Module 6: Travel and Transportation**
- **Section 1:**
  - Vocabulary: Auto, Bus, Zug, Flugzeug, Fahrrad, Taxi, Zu Fuß gehen, Fahren, Fliegen, Ticket.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Bahnhof, Flughafen, Bushaltestelle, Sitzplatz, Karte, Reise, Ziel, Reisen, Route, Gepäck.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Ankunft, Abfahrt, Fahrplan, Zeitplan, Buchung, Reservierung, Pass, Bordkarte, Check-in, Gate

.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Tourist, Reiseführer, Besuch, Ausflug, Besichtigung, Museum, Hotel, Unterkunft, Aufenthalt, Zimmer.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Abenteuer, Entdecken, Reisebüro, Pauschalreise, Reiseplan, Sehenswürdigkeit, Denkmal, Kultur, Erlebnis.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).

**Module 7: Shopping and Money**
- **Section 1:**
  - Vocabulary: Geschäft, Laden, Markt, Einkaufszentrum, Bargeld, Karte, Zahlung, Preis, Einkaufswagen, Rabatt.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Verkäufer, Kunde, Produkte, Regal, Schaufenster, Kleidung, Schuhe, Accessoires, Elektronik, Haushaltswaren.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Größe, Farbe, Marke, Qualität, Einkaufsliste, Artikel, Bezahlen, Rückgabe, Umtausch, Garantie.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Sonderangebot, Werbung, Gutschein, Schaufensterbummel, Online-Shopping, Lieferung, Versand, Zollgebühren, Steuern, Beleg.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Währung, Wechselkurs, Sparschwein, Kreditkarte, Bankkonto, Geldautomat, Ausgaben, Budget, Finanzen, Kontoauszug.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).

**Module 8: Weather and Seasons**
- **Section 1:**
  - Vocabulary: Sonnig, Regnerisch, Bewölkt, Windig, Schneeig, Heiß, Kalt, Warm, Kühl, Temperatur.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Frühling, Sommer, Herbst, Winter, Wettervorhersage, Sturm, Donner, Blitz, Hagel, Frost.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Feucht, Trocken, Nass, Brise, Sturm, Nebel, Dunst, Nieselregen, Platzregen, Hitzewelle.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Schneesturm, Hurrikan, Tornado, Zyklon, Dürre, Überschwemmung, Erosion, Klima, Atmosphäre, Wetterbericht.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Meteorologie, Prognose, Barometer, Thermometer, Hygrometer, Anemometer, Wetterphänomene, Saisonale Veränderungen, Globale Erwärmung, Klimawandel.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).
"""
]
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

if not GOOGLE_API_KEY:
    raise ValueError("Please set the GOOGLE_API_KEY environment variable.")

genai.configure(api_key=GOOGLE_API_KEY)

for m in genai.list_models():
    if 'generateContent' in m.supported_generation_methods:
        print(m.name)


model = genai.GenerativeModel(
    model_name="gemini-1.5-pro",
    system_instruction={
        f"""
**Your Role:**

- You are a virtual language teacher for students of {origin} learning {language} at level {level}.
- Your goal is to create JSON files with exercises that progressively introduce new vocabulary and challenge students to use it effectively.

**JSON File Structure:**

- The JSON file represents a module with a specific topic.
- Each module is divided into sections with increasing difficulty, appropriate for level {level}.
  - **Each section will contain an important amount of unique exercises**, structured as follows:
    1. **Type 0 Exercise:** These exercises introduce grammar rules, conjugation rules and phrases structures. They should be more frequent in Section 1 and gradually decrease in frequency by last section. The `content` section can include:
    2. **Type 7 Exercise (Vocabulary listing):** These exercises provide a list of new vocabulary words with their meanings.They should be more frequent in Section 1 and gradually decrease in frequency by last section.
    3. **Type 1-6 Exercises (Practice & Reinforcement):** These exercises should utilize the vocabulary introduced in the Type 0 and Type 7 exercises. These can be a mix of exercise types:
        - **Type 1:** Fill-in-the-blank exercises with a single answer. (Answers should use the introduced vocabulary)
        - **Type 2:** Conjugation exercises (if applicable to the vocabulary introduced in Type 0 and Type 7).
        - **Type 3:** Fill-in-the-blank exercises with multiple possible answers (using the introduced vocabulary).
        - **Type 4:** Vocabulary matching exercises (matching words with definitions/meanings from the introduced vocabulary).
        - **Type 5:** Reading comprehension exercises using a short passage that incorporates the introduced vocabulary.
        - **Type 6:** Question-answering exercises in which content is introduced, questions are asked and answers are demanded.
    4. **Uniqueness:** All exercises within each section should be unique, except when different exercise types are used but the vocabulary remains the same.

- Each section should ensure that previously learned vocabulary is reused in the new exercises while introducing new vocabulary for the next section.

**Chapter Properties:**

- **chapter:** Unique identifier for the exercise (e.g., 0, 1, 2).
- **type:** Defines the exercise type (integer):
    - 0: Informational content.
    - 1: Fill-in-the-blank exercises with a single answer.
    - 2: Conjugation exercises (if applicable to the vocabulary).
    - 3: Fill-in-the-blank exercises with multiple possible answers.
    - 4: Vocabulary matching exercises.
    - 5: Reading comprehension exercises.
    - 6: Question-answering exercises based on a provided dialogue or passage.
    - 7: Vocabulary listing with meanings (introducing new vocabulary).
- **title:** Descriptive title for the chapter (e.g., "Basic Greetings").
- **content:** In {language}, varies based on the exercise type:
    - Type 0: String with explanations, definitions, example sentences, and context.
    - Type 1: String with fill-in-the-blank sentences and an array of answers. (Answers should use previously introduced vocabulary)
    - Type 2: Array containing parts to conjugate and an answer array.
    - Type 3: Object with a sentence and a map of possible answers (indicating correctness).
    - Type 4: Arrays for answers and words to be matched.
    - Type 5: String with reading content using previously introduced vocabulary.
    - Type 6: String with a passage and an array of questions, each question paired with a reference to the answer in the passage.
    - Type 7: Array of objects, each with `word` and `meaning` properties for vocabulary listing.

**Pre-constructed Modules:**
{preconstruct_modules[0]}

**Generating a New Module:**

- Create the demanded module and section.
- Ensure every section begins with Type 7 exercises to introduce new vocabulary in context and is followed by Type 1-6 exercises that use this vocabulary.
- Gradually increase the difficulty while ensuring the previously learned vocabulary is reused and reinforced.

**Avoiding Mistakes:**

- Ensure exercises are relevant to the module's topic.
- Type 7 exercises **must** introduce new vocabulary.
- Only use previously introduced vocabulary in exercises of Type 1-6 (practice and reinforcement exercises).
- Type 6 exercises should be more than just repeating what is written in the content and a lot of mistakes are done.
- Pay attention to low and high caps for words.

**Additional Information:**

- Example JSON structure is provided ({example_json}).
- Review those chapters to avoid mistakes ({avoid_json}).

"""
    },
    generation_config={"response_mime_type": "application/json"}
)

response = model.generate_content(
    f"Generate module {module} section {section} with exercises for students of {origin} learning {language} at level {level}. The module should progressively introduce new vocabulary and challenge students to use it, following the specified JSON structure and exercise types. Remember to only introduce what is mention in preconstructed modules and you should avoid duplicates as well as exercices without introduction to the vocabulary."
)

print(response.text)

# Parse the response text as JSON
response_json = json.loads(response.text)

# Define the directory path using the course, level, and module
directory_path = f"../../modules/{course}_{level}/module{module}"

# Create the directory if it doesn't exist
os.makedirs(directory_path, exist_ok=True)

# Define the file name using the section number
file_name = f"section_{section}.json"

# Full file path
file_path = os.path.join(directory_path, file_name)

# Save the JSON to a file
with open(file_path, 'w') as json_file:
    json.dump(response_json, json_file, indent=4)

print(f"Response saved to {file_path}")
