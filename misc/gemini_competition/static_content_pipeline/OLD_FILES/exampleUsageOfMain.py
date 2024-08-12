import os
import json

import google.generativeai as genai
import sys
from dotenv import load_dotenv

load_dotenv()


# ANSI escape codes for colors
LIGHT_BLUE = '\033[94m'
MATTE_GREEN = '\033[92m'
COOL_PINK = '\033[95m'
RESET = '\033[0m'

# Constants for the current COURSE, LEVEL, MODULE, and SECTION
COURSE = "eng_de"
ORIGIN = "english"
LANGUAGE = "german"
LEVEL = "A1"
MODULE = int(sys.argv[1])
MODULE_NAME = "Greetings & Introductions"
SECTION = int(sys.argv[2])

# Example JSON and avoid JSON data
EXAMPLE_JSON = """
[
    {
        "section": "section1",
        "title": "Module 1: Greetings & Introductions",
        "chapters": [
            {
                "chapter": 0,
                "type": 7,
                "title": "1: Basic Greetings",
                "vocabulary": [
                  {
                    "word": "Hallo",
                    "meaning": "Hello"
                  },
                  {
                    "word": "Guten Morgen",
                    "meaning": "Good morning"
                  },
                  {
                    "word": "Guten Tag",
                    "meaning": "Good afternoon"
                  },
                  {
                    "word": "Guten Abend",
                    "meaning": "Good evening"
                  },
                  {
                    "word": "Auf Wiedersehen",
                    "meaning": "Goodbye (formal)"
                  },
                  {
                    "word": "Tschüss",
                    "meaning": "Bye (informal)"
                  },
                  {
                    "word": "Grüß Gott",
                    "meaning": "Hello (used in Southern Germany and Austria)"
                  },
                  {
                    "word": "Servus",
                    "meaning": "Hello/Goodbye (informal, used in Southern Germany and Austria)"
                  },
                  {
                    "word": "Moin",
                    "meaning": "Hello (used in Northern Germany)"
                  },
                  {
                    "word": "Gute Nacht",
                    "meaning": "Good night"
                  },
                  {
                    "word": "Bis später",
                    "meaning": "See you later"
                  },
                  {
                    "word": "Wie geht's?",
                    "meaning": "How are you?"
                  },
                  {
                    "word": "Willkommen",
                    "meaning": "Welcome"
                  }
                ]
               },
               {
                "chapter": 1,
                "type": 3,
                "title": "2: Fill-in-the-Blank: Greetings",
                "content": [
                  {
                    "sentence": "___ (Hello), mein ___ (name) ist Maria.",
                    "options": [
                      {"choices": ["Hallo", "Guten Morgen", "Guten Tag", "Tschüss"]},
                      {"choices": ["Vorname", "Nachname", "Name", "Familienname"]}
                    ],
                    "answers": ["Hallo", "Name"]
                  },
                  {
                    "sentence": "___ (Good morning), wer ___ (are) Sie?",
                    "options": [
                      {"choices": ["Hallo", "Guten Morgen", "Guten Tag", "Tschüss"]},
                      {"choices": ["sind", "bin", "ist", "seid"]}
                    ],
                    "answers": ["Guten Morgen", "sind"]
                  },
                  {
                    "sentence": "___ (Good evening), wer ___ (to be) du?",
                    "options": [
                      {"choices": ["Guten Abend", "Gute Nacht", "Auf Wiedersehen", "Servus"]},
                      {"choices": ["geht", "links", "bist", "geht's"]}
                    ],
                    "answers": ["Guten Abend", "bist"]
                  },
                  {
                    "sentence": "___ (Goodbye), bis ___ (tomorrow)!",
                    "options": [
                      {"choices": ["Auf Wiedersehen", "Hallo", "Willkommen", "Moin"]},
                      {"choices": ["morgen", "gestern", "heute", "später"]}
                    ],
                    "answers": ["Auf Wiedersehen", "morgen"]
                  },
                  {
                    "sentence": "___ (Welcome) in Deutschland! Wie ist Ihr ___ (last name)?",
                    "options": [
                      {"choices": ["Willkommen", "Servus", "Grüß Gott", "Bis später"]},
                      {"choices": ["Nachname", "Vorname", "Name", "Spitzname"]}
                    ],
                    "answers": ["Willkommen", "Nachname"]
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
                "content": "Ich ___ (to be called) Maria.\n\nDu ___ (to be) ein Student.\n\n___ (Good evening), ___ (How are you?)\n\n___ (Goodbye), bis ___ (tomorrow)!\n\nWir ___ (come) aus Deutschland.\n\nSie ___ (live) in Berlin.\n\nEr ___ (to be) 25 Jahre alt.\n\nIch ___ (to speak) ein bisschen Deutsch.",
                "answers": ["heiße", "bist", "Guten Abend", "wie geht's?", "Auf Wiedersehen", "morgen", "kommen", "wohnen", "ist", "spreche"]
            },
            {
                "chapter": 7,
                "type": 0,
                "title": "8: Basic Sentence Structure - Subject-Verb-Object",
                "content": "German main clauses typically follow a Subject-Verb-Object (SVO) structure, similar to English. The subject performs the action, the verb describes the action, and the object receives the action.\n\nExamples:\n1. Ich [Subject] esse [Verb] einen Apfel [Object].\n   (I eat an apple.)\n\n2. Der Hund [Subject] jagt [Verb] die Katze [Object].\n   (The dog chases the cat.)\n\n3. Maria [Subject] liest [Verb] ein Buch [Object].\n   (Maria reads a book.)\n\n4. Wir [Subject] trinken [Verb] Kaffee [Object].\n   (We drink coffee.)\n\n5. Die Kinder [Subject] spielen [Verb] Fußball [Object].\n   (The children play soccer.)\n\nNote: While this SVO structure is common, German word order can be more flexible than English, especially when emphasizing different parts of the sentence or in subordinate clauses. However, in simple statements, SVO is the standard order."
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

AVOID_JSON = f"""
    einen rot Apfel : it should be einen roten Apfel
    Eins Apfel : It is ein Apfel
    Adding '-e' to nouns to form the plural. Example: Ein Apfel (One apple), Zwei \u00c4pfel (Two apples) : This doesn't make sense.
    Ich habe ___ (One) Apfel. Du hast ___ (Two) Bücher. : Result should be Ich habe einen Apfel. Du hast zwei Bücher.
    Der Himmel ist ___ (blue).  Die Sonne ist ___ (yellow).  Die Banane ist ___ (yellow).  Der Stuhl ist ___ (black). : Avoid repetitions
    Subject-Verb-Object structure. Example: Der Apfel ist [Subject] rot [Object] : Hardly understandable.
    Ein (a, an - masculine), Eine (a, an - feminine).  Example: Ein Apfel (a/an apple), Eine Banane (a/an banana). : An explanation would be better.
    A1 students hardly understand German. Try to give the English version of the phrases at the end so that they understand the meaning.
    Type 6 exercises : Reference should be in {LANGUAGE} and the questions/answers have to be more accurate.
    Wo wohnt Anna? Ich komme aus Berlin : That's not an accurate answer for type 6 exercise.
    Type 0 and 7 : They are not the same. Don't use type 0 and 7 one after the other. Type 0 should introduce new context for example structure of German phrases and type 7 is used for vocabulary.
"""

# Preconstructed modules as individual variables
MODULE_1 = """
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
"""

MODULE_2 = """
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
"""

MODULE_3 = """
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
"""

MODULE_4 = """
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
"""

MODULE_5= """
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
"""

MODULE_6 = """
**Module 6: Travel and Transportation**
- **Section 1:**
  - Vocabulary: Auto, Bus, Zug, Flugzeug, Fahrrad, Taxi, Zu Fuß gehen, Fahren, Fliegen, Ticket.
  - Exercises: Type 0 (more frequent), Type 1-5, Type 6, Type 7 (more frequent).
- **Section 2:**
  - Vocabulary: Bahnhof, Flughafen, Bushaltestelle, Sitzplatz, Karte, Reise, Ziel, Reisen, Route, Gepäck.
  - Exercises: Type 0 (less frequent), Type 1-5, Type 6, Type 7 (less frequent).
- **Section 3:**
  - Vocabulary: Ankunft, Abfahrt, Fahrplan, Zeitplan, Buchung, Reservierung, Pass, Bordkarte, Check-in, Gate.
  - Exercises: Type 0 (even less frequent), Type 1-5, Type 6, Type 7 (even less frequent).
- **Section 4:**
  - Vocabulary: Tourist, Reiseführer, Besuch, Ausflug, Besichtigung, Museum, Hotel, Unterkunft, Aufenthalt, Zimmer.
  - Exercises: Type 0 (rare), Type 1-5, Type 6, Type 7 (rare).
- **Section 5:**
  - Vocabulary: Abenteuer, Entdecken, Reisebüro, Pauschalreise, Reiseplan, Sehenswürdigkeit, Denkmal, Kultur, Erlebnis.
  - Exercises: Type 0 (very rare), Type 1-5, Type 6, Type 7 (very rare).
"""

MODULE_7 = """
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
"""

MODULE_8 = """
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


PRECONSTRUCT_MODULES = [MODULE_1, MODULE_2, MODULE_3, MODULE_4, MODULE_5, MODULE_6, MODULE_7, MODULE_8]

GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

if not GOOGLE_API_KEY:
    raise ValueError("Please set the GOOGLE_API_KEY environment variable.")

genai.configure(api_key=GOOGLE_API_KEY)

def list_models():
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(m.name)

def create_system_instruction(module, section):
    return f"""
      **Your Role:**

      - You are a virtual language teacher for students of {ORIGIN} learning {LANGUAGE} at level {LEVEL}.
      - Your goal is to create JSON files with exercises that progressively introduce new vocabulary and challenge students to use it effectively.

      **JSON File Structure:**

      - The JSON file represents a module with a specific topic.
      - Each module is divided into sections with increasing difficulty, appropriate for level {LEVEL}.
        - **Each section will contain an important amount of unique exercises**, structured as follows:
          1. **Type 0 Exercise:** These exercises introduce grammar rules, conjugation rules, and phrase structures. They should be more frequent in Section 1 and gradually decrease in frequency by the last section.
          2. **Type 7 Exercise (Vocabulary listing):** These exercises provide a list of new vocabulary words with their meanings. They should be more frequent in Section 1 and gradually decrease in frequency by the last section.
          3. **Type 1-6 Exercises (Practice & Reinforcement):** These exercises should utilize the vocabulary introduced in the Type 0 and Type 7 exercises. These can be a mix of exercise types:
              - **Type 1:** Fill-in-the-blank exercises with a single answer. (Answers should use the introduced vocabulary)
              - **Type 2:** Conjugation exercises, here always ask the 6 pronouns (if applicable to the vocabulary introduced in Type 0 and Type 7).
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
          - 3: Fill-in-the-blank exercises with multiple possible answers. // This has a more complex json structure - check the example json
          - 4: Vocabulary matching exercises.
          - 5: Reading comprehension exercises.
          - 6: Question-answering exercises based on a provided dialogue or passage.
          - 7: Vocabulary listing with meanings (introducing new vocabulary).
      - **title:** Descriptive title for the chapter (e.g., "Basic Greetings").
      - **content:** In {LANGUAGE}, varies based on the exercise type:
          - Type 0: String with explanations, definitions, example sentences, and context.
          - Type 1: String with fill-in-the-blank sentences and an array of answers. (Answers should use previously introduced vocabulary)
          - Type 2: Array containing parts to conjugate and an answer array.
          - Type 3: Object with a sentence and a map of possible answers (indicating correctness).
          - Type 4: Arrays for answers and words to be matched.
          - Type 5: String with reading content using previously introduced vocabulary.
          - Type 6: String with a passage and an array of questions, each question paired with a reference to the answer in the passage.
          - Type 7: Array of objects, each with `word` and `meaning` properties for vocabulary listing.

      **Generating a New Module:**

      - Create the demanded module and section.
      - Ensure every section begins with Type 7 exercises to introduce new vocabulary in context and is followed by Type 1-6 exercises that use this vocabulary.
      - Create enough exercises to practice newly introduced vocabulary.
      - Gradually increase the difficulty while ensuring the previously learned vocabulary is reused and reinforced.

      **Avoiding Mistakes:**

      - Ensure exercises are relevant to the module's topic.
      - Type 7 exercises **must** introduce new vocabulary. If type 0 is used, it shouldn't introduce vocabulary. Instead it should be about grammar rules, conjugation rules and phrase structures.
      - Only use previously introduced vocabulary in exercises of Type 1-6 (practice and reinforcement exercises).
      - Type 6 exercises should have answers in third person and not dialogues said in 'content'.
      - Pay attention to low and high caps for words.

      **Additional Information:**

      - Example JSON structure is provided ({EXAMPLE_JSON}).
      - Review those chapters to avoid mistakes. ':' separates mistake with explaination ({AVOID_JSON}).

      """

def generate_content(module, section):
    instruction = create_system_instruction(module, section)
    model = genai.GenerativeModel(
        model_name="gemini-1.5-pro",
        system_instruction=instruction,
        generation_config={"response_mime_type": "application/json"}
    )
    response = model.generate_content(
        f"Generate module {module} section {section} with exercises for students of {ORIGIN} learning {LANGUAGE} at level {LEVEL}. The module should progressively introduce new vocabulary and challenge students to use it, following the specified JSON structure and exercise types. Remember to only introduce what is mentioned in preconstructed modules and avoid duplicates as well as exercises without introducing the vocabulary. The module is {PRECONSTRUCT_MODULES[module-1]}"
    )

    try:
        response_json = json.loads(response.text)
    except json.JSONDecodeError as e:
        print(f"{COOL_PINK}Failed to parse JSON: {e}{RESET}")
        print("Response text was:", response.text)
        print(f"{LIGHT_BLUE}Reasking for the correct JSON format...{RESET}")
        second_response = model.generate_content(
            f"I now need you to generate content for the Second section of module {module}. Generate me chapters of type 0, 1, 2, 3 and 4. The chapters should be {section-1}1, {section-1}2, {section-1}3, {section-1}4, {section-1}5, {section-1}6, {section-1}7, {section-1}8, {section-1}9, {section}0 respectively. The last one was not in the correct format. We got this error: {e}"
        )
        try:
            response_json = json.loads(second_response.text)
            print(response_json)
        except json.JSONDecodeError as e:
            print(f"{COOL_PINK}Failed to parse JSON a SECOND TIME: {e}{RESET}")
            print("Second response text was:", second_response.text)
            return None
    return response_json

def save_json_to_file(response_json, module, section):
    if response_json is None:
        print("No valid JSON to save. Exiting.")
        return

    directory_path = f"../../modules/{COURSE}_{LEVEL}/module{module}"
    os.makedirs(directory_path, exist_ok=True)
    file_name = f"section_{section}.json"
    file_path = os.path.join(directory_path, file_name)
    
    try:
        with open(file_path, 'w') as json_file:
            json.dump(response_json, json_file, indent=4)
        print(f"{MATTE_GREEN}Response saved to {file_path}{RESET}")
    except Exception as e:
        print(f"{COOL_PINK}Failed to save the response to the file: {e}{RESET}")

def main():
    list_models()
    print(f"Generating content for Module {MODULE}, Section {SECTION}...")
    response_json = generate_content(MODULE, SECTION)
    save_json_to_file(response_json, MODULE, SECTION)

if __name__ == "__main__":
    main()