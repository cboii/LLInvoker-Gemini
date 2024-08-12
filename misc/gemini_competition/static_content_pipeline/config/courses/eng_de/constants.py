# config/courses/eng_de/constants.py
import os


COURSE = "eng_de"
ORIGIN = "english"
LANGUAGE = "german"
PRECONSTRUCT_MODULES = [] # Is constructed in __init__.py

# TODO This should also become a json file, it should also be seperated by type so that we can give type specific examples in /src/generators/chapterGenerator.py
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
