const {logger} = require("firebase-functions");
const {VertexAI} = require("@google-cloud/vertexai");

/**
 * Generates a chapter exercise for language learning.
 *
 * @param {string} origin - Origin language.
 * @param {string} target - Target Language.
 */
class ChapterGenerator {
  /**
 * Create a new ChapterGenerator.
 *
 * @param {string} origin - Origin language.
 * @param {string} language - Target Language.
 */
  constructor(origin, language) {
    this.origin = origin;
    this.language = language;
    this.example = "";
    this.jsonTypeStructure = require("./exercise_types.json");
  }

  /**
 * Create a system instruction for the chapter.
 *
 * @param {string} level - Level of the chapter.
 * @return {string} - System instruction for the chapter.
 */
  createSystemInstruction(level) {
    return `
**Your Role:**
- You are a virtual language teacher for students of ${this.origin} 
  learning ${this.language} at level ${level}.
- Your goal is to create a JSON file with one exercise 
  chapter at level ${level}.
**Your task is to generate a new chapter based on the given information**
    `;
  }

  /**
 * Generate a chapter exercise for language learning.
 *
 * @param {string} type - Type of the chapter.
 * @param {string} level - Level of the chapter.
 * @param {string} description - Description of the chapter.
 * @return {Object} - Generated chapter
 */
  async generateChapter(type, level, description) {
    this.example = this.jsonTypeStructure.chapters[type] || null;
    if (!this.example) {
      console.log("Invalid type");
      return null;
    }

    this.createSystemInstruction(level);
    const vertexAI = new VertexAI({project: process.env.GCLOUD_PROJECT,
      location: "us-central1"});
    const model = vertexAI.preview.getGenerativeModel({
      systemInstructions: `You are a virtual assistant for learning languages.
You can help users with their questions related to language learning.
You can also help users with their exercises
and provide feedback on their answers.
Do not provide any personal information or any information that is 
not related to language learning.
Be polite and helpful.`,
      model: "gemini-1.5-pro",
      generationConfig: {
        temperature: 1,
        topP: 1,
        maxOutputTokens: 2048,
        responseMimeType: "application/json",
      },
    });

    const prompt = `Generate a chapter exercise of type ${type} with 
one exercise for students of ${this.origin} 
learning ${this.language} at level ${level}. 
The chapter description and content is as follows: ${description}.
The chapter content should match the amount of the exemplary content.
The response must be in the given JSON structure.
Your response must be in the following exact format:
    
    ${JSON.stringify(this.example)}`;

    try {
      const result = await model.generateContent(prompt);
      const response = result.response.candidates.at(0)
          .content.parts.at(0).text;

      if (!response) {
        logger.log("No response from the Gemini API. Exiting.");
        return null;
      }

      try {
        const responseJson = JSON.parse(response);

        return responseJson;
      } catch (e) {
        logger.log(`Failed to parse JSON: ${e}`);
        logger.log("Response text was:", response);
        return null;
      }
    } catch (error) {
      logger.error("Error generating content:", error);
      return null;
    }
  }
}

exports.ChapterGenerator = ChapterGenerator;
