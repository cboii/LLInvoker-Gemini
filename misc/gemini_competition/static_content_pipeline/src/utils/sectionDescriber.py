# TODO Basically find a way to describe each section for each module in the course
# This can be way smaller and more efficient, for example the model does not have to know 
class SectionDescriber:
    def __init__(self, amount_of_chapters):
        self.amount_of_chapters = amount_of_chapters

    def describe_section(self, module, section):
        # good for first sections of a module
        # TODO adapt for other sections -> for example the first 2-3 sections of a module could follow this pattern, the 4-6 sections should have more complex exercises
        chapters_of_type_7 = round(self.amount_of_chapters / 4) 
        chapters_of_type_0 = round(self.amount_of_chapters / 4)
        
        # TODO adapt the description to the specific module and section
        # TODO ADD EXAMPLE HERE FOR EACH TYPE -> JSON FILE
        description = f"""
        The section should contain {self.amount_of_chapters} chapters.
        Each section should contain at least {chapters_of_type_7} chapters of type 7 and {chapters_of_type_0} of type 0.
        The rest of the chapters can be of any type.

        - **type:** Defines the exercise type (integer):
              - 0: Informational content, which is a String with explanations, definitions, example sentences, and context. Do not introduce new vocabulary in this type!
              - 1: Fill-in-the-blank exercises with a single answer.
              - 2: Conjugation exercises of a specific verb for each personal pronoun (if applicable to the vocabulary).
              - 3: Fill-in-the-blank exercises with multiple possible answers. // This has a more complex json structure - check the example json
              - 4: Vocabulary matching exercises.
              - 5: Reading comprehension exercises.
              - 6: Question-answering exercises based on a provided dialogue or passage.
              - 7: Vocabulary listing with meanings (introducing new vocabulary and verbs).
              - 8: Verb conjugation tables that include different tenses (present and imperfect) for a specific verb. 
              - 9: Writing exercises where learners must compose a short text or paragraph based on a given prompt. This type encourages creative language use and application of learned vocabulary and grammar.
        """
        
        return description