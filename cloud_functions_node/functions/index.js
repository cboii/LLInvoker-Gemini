// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
const {logger, https, auth} = require("firebase-functions");
const {VertexAI} = require("@google-cloud/vertexai");
const {ChapterGenerator} = require("./chapterGenerator");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {setLanguage} = require("./utils");

// The Firebase Admin SDK to access Firestore.
const {initializeApp} = require("firebase-admin/app");
const {Firestore} = require("firebase-admin/firestore");
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const {getAuth} = require("firebase-admin/auth");

initializeApp({
  storageBucket: "gs://llinvoker.appspot.com",
});

const vertexAI = new VertexAI({
  project: process.env.GCLOUD_PROJECT,
  location: "us-central1",
});
// logger.log("Request body: ", request.body.messages);
// Available models: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models
const model = "gemini-1.5-pro";


exports.chat = https.onCall(async (req, context) => {
  // Get the ID token from the Authorization header
  const idToken = context.auth.token;
  if (!idToken) {
    return {error: "Unauthorized: No token provided"};
  }
  const ratesDoc = getFirestore().collection("rateLimits").doc(idToken.uid);
  const rates = (await ratesDoc.get()).get("chat");
  const user = await getAuth().getUser(idToken.uid);
  let claims;

  if (!user.customClaims) {
    claims = null;
  } else {
    claims = user.customClaims.stripeRole;
  }

  if (rates <= 0 && !claims) {
    return {error: "You have reached the limit of chat requests for today."};
  } else {
    await ratesDoc.update({chat: rates - 1});
  }


  const generativeModel = vertexAI.preview.getGenerativeModel({
    systemInstructions: `You are a virtual assistant for learning languages.
You can help users with their questions related to language learning.
You can also help users with their exercises
and provide feedback on their answers.
Do not provide any personal information or any information
that is not related to language learning.
Be polite and helpful.`,
    model: model,
    generation_config: { // Test impact of parameters: https://makersuite.google.com
      "max_output_tokens": 2048,
      "temperature": 0.9,
      "top_p": 1,
    },
  });

  // const req = {
  //   contents: [{role: 'user', parts: [{text: request.body.text}]}],
  // };
  const messages = req.messages.map((message) => {
    logger.log("Message: ", message);
    return {role: message.role, parts: [{text: message.text}]};
  });

  const request = {
    contents: messages.reverse(),
  };

  try {
    const content = await generativeModel.generateContent(request);
    const result = content.response.candidates.at(0).content.parts.at(0).text;
    return {text: result};
  } catch (error) {
    logger.error(error);
    return {error: "Intenal server error"};
  }
},
);


exports.transform = https.onCall(async (req, context) => {
  const db = getFirestore();

  // Get the ID token from the Authorization header
  const idToken = context.auth.token;
  if (!idToken) {
    return {error: "Unauthorized: No token provided"};
  }

  const {type, level, language, gcsFileName} = req;

  const ratesDoc = getFirestore().collection("rateLimits").doc(idToken.uid);
  const rates = (await ratesDoc.get()).get("transform");
  const user = await getAuth().getUser(idToken.uid);
  let claims;

  if (!user.customClaims) {
    claims = null;
  } else {
    claims = user.customClaims.stripeRole;
  }

  if (rates <= 0 && !claims) {
    return {
      error: "You have reached the limit of image upload requests for today.",
    };
  } else {
    await ratesDoc.update({transform: rates - 1});
  }

  try {
    logger.log("Request body: ", req);
    // Check if image, type, and level are provided
    if (!gcsFileName || type == null || !level) {
      return {error: "Missing image, type, or level parameter"};
    }

    // Upload image to Cloud Storage
    const bucket = getStorage().bucket();
    const file = bucket.file(gcsFileName);
    // Download the file contents
    const [fileContents] = await file.download();

    // Convert the file contents to a base64 encoded string
    const base64String = fileContents.toString("base64");

    const {origin, target} = setLanguage(language);


    // Available models: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models
    const generativeModel = vertexAI.preview.getGenerativeModel({
      model: model,
      systemInstruction: `
You are a virtual language teacher for students speaking ${origin},
learning ${target} at level ${level}.
You get an image as an input and your goal is to generate 
a new chapter in ${target} based on the given information.
Therefore, we need a description which precisley captures 
the content of the exercise,
using the information from the image.
  Here is a short description of the exercise types:
  - **type:** Defines the exercise type (integer):
    - 0: Informational content, which is a String with explanations,
      definitions, example sentences, and context.
      Do not introduce new vocabulary in this type!
    - 1: Fill-in-the-blank exercises with a single answer.
    - 2: Conjugation exercises of a specific verb for each personal pronoun
      (must always contain 6 entries).
    - 3: Fill-in-the-blank exercises with multiple possible answers.
    - 4: Vocabulary matching exercises.
    - 5: Reading comprehension exercises.
    - 6: Question-answering exercises based on a 
      provided dialogue or passage.
    - 7: Vocabulary listing with meanings
      (introducing new vocabulary and verbs).
      Always include the articles.
    - 8: Verb conjugation in specifc tenses. 
      Always include all the personal pronouns.
    - 9: Writing exercises where the user has to write a text
      based on a given topic.
      The text must be proofread and evaluated.
        
  Adapt your response to the given type and image content.`,

      generation_config: {
        "max_output_tokens": 2048,
        "temperature": 0.9,
        "top_p": 1,
      },
    });

    const generativeReq = {
      contents: [
        {
          role: "user",
          parts: [
            {text: `Process this image.
  The type of this exercise must be: ${type} (mentioned earlier),
  Level: ${level}.
  Return a description of the exercise as a string and be precise.
  Do not return a description of the image,
  but a description for the exercise according to the right type.`},
            {inline_data: {mime_type: "image/png", data: base64String}},
          ],
        },
      ],
    };

    const content = await generativeModel.generateContent(generativeReq);
    const result = content.response.candidates.at(0).content.parts.at(0).text;
    logger.log(result);

    const chapterGenerator = new ChapterGenerator(origin, target);
    const chapterResponse = await chapterGenerator
        .generateChapter(type, level, result);

    if (!chapterResponse) {
      return {error: "Failed to generate chapter"};
    }

    const ref = await db.collection(`users/${idToken.uid}/generatedChapters`)
        .add(chapterResponse);

    return {
      path: ref.path,
      data: chapterResponse,
      result: result,
    };
  } catch (error) {
    logger.error("Error in transform function:", error);
    return {error: "Internal server error"};
  }
});


exports.generateChapter = https.onCall(async (req, context) => {
  const db = getFirestore();
  const {type, level, description, language} = req;
  logger.log(type, level, description);

  // Get the ID token from the Authorization header
  const idToken = context.auth.token;
  if (!idToken) {
    return {text: "Unauthorized: No token provided"};
  }

  const ratesDoc = getFirestore().collection("rateLimits").doc(idToken.uid);
  const rates = (await ratesDoc.get()).get("generateChapter");
  const user = await getAuth().getUser(idToken.uid);
  let claims;

  if (!user.customClaims) {
    claims = null;
  } else {
    claims = user.customClaims.stripeRole;
  }

  if (rates <= 0 && !claims) {
    return {error: "You have reached the limit of chat requests for today."};
  } else {
    await ratesDoc.update({generateChapter: rates - 1});
  }


  if ( !level || !description) {
    return {
      error: "Missing required fields: type, level, or description",
    };
  }

  const {origin, target} = setLanguage(language);
  logger.info(origin, target);

  if (!origin || !target) {
    return {error: "Invalid language"};
  }

  const chapterGenerator = new ChapterGenerator(origin, target);
  try {
    const response = await chapterGenerator
        .generateChapter(type, level, `${description}
          The chapter content must be in ${target},
          with explanations in ${origin}.`);

    if (!response) {
      return {error: "Failed to generate chapter"};
    }
    const ref = await db.collection(`users/${idToken.uid}/generatedChapters`)
        .add(response);
    return {path: ref.path, data: response};
  } catch (error) {
    logger.error("Error:", error);
    return {error: "Internal server error"};
  }
});


exports.questionAnswerExercise = https.onCall(async (req, context) => {
  const idToken = context.auth.token;
  if (!idToken) {
    return {error: "Unauthorized: No token provided"};
  }

  const ratesDoc = getFirestore().collection("rateLimits").doc(idToken.uid);
  const rates = (await ratesDoc.get()).get("questionAnswerExercise");
  const user = await getAuth().getUser(idToken.uid);
  let claims;

  if (!user.customClaims) {
    claims = null;
  } else {
    claims = user.customClaims.stripeRole;
  }

  if (rates <= 0 && !claims) {
    return {error: "You have reached the limit of requests for today."};
  } else {
    await ratesDoc.update({questionAnswerExercise: rates - 1});
  }

  logger.log("Request body: ", req);
  // Available models: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models


  const generativeModel = vertexAI.preview.getGenerativeModel({
    model: model,
    generationConfig: { // Test impact of parameters: https://makersuite.google.com
      maxOutputTokens: 2048,
      temperature: 0.9,
      topP: 1,
      responseMimeType: "application/json",
    },
  });

  const reqString = `
  Here is a text where the user has to answer some questions:
  ${req.text}
  Here are the questions, reference answers,and the answers from the user:
  Question 1: ${req.question1}
  Reference Answer 1: ${req.reference1}
  Answer 1: ${req.answer1}
  
  Question 2: ${req.question2}
  Reference Answer 2: ${req.reference2}
  Answer 2: ${req.answer2}
  
  Question 3: ${req.question3}
  Reference Answer 3: ${req.reference3}
  Answer 3: ${req.answer3}
  
  Based on the given text and reference answers, evaluate the answers.
  Return a JSON object with the following structure:

  {
    "result": true/false
    "feedback": "Your feedback here"
  }

  Return true if the answers are correct and precise.
  Be extremely careful with the evaluation
  and use the references as an anker point for comparison.
  Make sure the sentences are complete and grammatically correct!
  The answers must be correct and precise.`;

  const request = {
    contents: [{role: "user", parts: [{text: reqString}]}],
  };

  try {
    const content = await generativeModel.generateContent(request);
    const result = content.response.candidates
        .at(0).content.parts.at(0).text;
    logger.log(result);
    const res = JSON.parse(result);
    return res;
  } catch (error) {
    logger.error(error);
    return {error: "Internal server error"};
  }
});


exports.writingExercise = https.onCall(
    async (req, context) => {
      const idToken = context.auth.token;
      if (!idToken) {
        return {text: "Unauthorized: No token provided"};
      }

      const ratesDoc = getFirestore().collection("rateLimits").doc(idToken.uid);
      const rates = (await ratesDoc.get()).get("questionAnswerExercise");
      const user = await getAuth().getUser(idToken.uid);
      let claims;

      if (!user.customClaims) {
        claims = null;
      } else {
        claims = user.customClaims.stripeRole;
      }

      if (rates <= 0 && !claims) {
        return {text: "You have reached the limit of chat requests for today."};
      } else {
        await ratesDoc.update({writingExercise: rates - 1});
      }

      logger.log("Request body: ", req);
      const language = req.language;
      // Available models: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models

      const generativeModel = vertexAI.preview.getGenerativeModel({
        model: model,
        generationConfig: {
          temperature: 1,
          topP: 1,
          maxOutputTokens: 2048,
          responseMimeType: "application/json",
        },
      });

      const {origin, target} = setLanguage(language);

      const example = {
        result: true,
        feedback: `The text is well written and the errors are minimal.
        The vocabulary is appropriate and the style is clear and engaging. 
        Good job!`,
      };

      const reqString = `
  Here is a topic about which the user has to write a short text in ${target}:
  ${req.topic}
  Proofread the text and spot the errors.
  Also, give a short feedback of around 50 words,
  focusing on grammar, style and vocabulary.
  Make sure the sentences are complete and grammatically correct!

  Here is the written text:
  ${req.text}
  Return true when the text is well written and the errors are minimal.
  Otherwise, return false.

  The text must be written in ${target}. If not, return false.
  The feedback must be in ${origin}.

  Return a JSON object with the following structure:
  ${JSON.stringify(example)}`;

      const request = {
        contents: [{role: "user", parts: [{text: reqString}]}],
      };
      try {
        const content = await generativeModel.generateContent(request);
        const result = content.response.candidates
            .at(0).content.parts.at(0).text;
        logger.log(result);
        return JSON.parse(result);
      } catch (error) {
        logger.error(error);
        return {error: "Internal server error"};
      }
    },
);


// exports.dailyLeaderboardUpdate = functions.pubsub
//     .schedule("0 0 * * *")
//     .timeZone("UTC")
//     .onRun(async (context) => {
//       const db = admin.firestore();
//       try {
//         // Get all users ordered by score in descending order
//         const usersSnapshot = await db.collection("users")
//             .orderBy("score", "desc")
//             .get();

//         const leaderboard = [];
//         let position = 1;

//         for (const doc of usersSnapshot.docs) {
//           const userData = doc.data();
//           const newScore = userData.score;
//           leaderboard.push({
//             path: doc.ref.path,
//             position: position,
//             score: newScore,
//           });

//           position++;
//         }

//         // Save the leaderboard to the leaderboard collection
//         await db.collection("leaderboard")
//             .doc("current")
//             .set({users: leaderboard});

//         console.log("Daily leaderboard update completed successfully");
//         return null;
//       } catch (error) {
//         console.error("Error updating leaderboard:", error);
//         return null;
//       }
//     });

// Keep the onUpdate function for immediate level updates
exports.updateLevelOnScoreChange = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      // Check if the score has changed
      if (before.score !== after.score) {
        const newScore = after.score;
        const newLevel = Math.floor(newScore / 100);
        const oldLevel = Math.floor(before.score / 100);
        // Only update if the level has changed
        if (newLevel !== oldLevel) {
          await change.after.ref.update({level: newLevel});
          logger.log(`User ${context.params.userId} new level: ${newLevel}`);
        }
      }
      return null;
    });

// exports.updateUserLevelOnScoreChange = firestore
//     .document("users/{userId}")
//     .onWrite(async (change, context) => {
//       const userId = context.params.userId;
//       const beforeData = change.before.exists ? change.before.data() : null;
//       const afterData = change.after.exists ? change.after.data() : null;

//       // Check if the document was deleted
//       if (!afterData) {
//         return null;
//       }

//       // Get the previous and new score
//       const previousScore = beforeData ? beforeData.score : null;
//       const newScore = afterData.score;

//       logger.log(`User ${userId} new score:`, newScore);
//       logger.log(`User ${userId} previous score:`, previousScore);

//       // If score hasn't changed, do nothing
//       if (previousScore === newScore) {
//         return null;
//       }
//       const newLevel = Math.floor(newScore / 100);
//       logger.log(`User ${userId} new level:`, newLevel);

//       const doc = await admin.firestore()
//           .collection("users").doc(userId).update({level: newLevel});
//       // Update the level in Firestore
//       return doc;
//     });


exports.createUserDocument = auth.user().onCreate(async (user) => {
  const englishCourseRef = await admin.firestore().collection("courses")
      .doc("eng_de");
  const frenchCourseRef = await admin.firestore().collection("courses")
      .doc("eng_fr");
  const englishA1Ref = await englishCourseRef.collection("levels")
      .doc("A1");
  const frenchA1Ref = await frenchCourseRef.collection("levels")
      .doc("A1");
  const englishA1Chapter0 = await englishA1Ref.collection("modules")
      .doc("module1").collection("sections")
      .doc("section1").collection("chapters").doc("0");
  const frenchA1Chapter0 = await frenchA1Ref.collection("modules")
      .doc("module1").collection("sections")
      .doc("section1").collection("chapters").doc("0");
  const userId = user.uid;
  const userEmail = user.email;
  const achievements = [];
  const score = 0;
  const premiumMembership = false;
  const league = {};
  const level = 1;
  const hearts = 5;
  const starsMap = {};
  const activeLanguage = "eng_de";
  const activeLevel = "A1";
  const myCourses = {
    "eng_de": {
      "A1": {
        "currentChapter": englishA1Chapter0,
        "progress": [],
      },
    },
    "eng_fr": {
      "A1": {
        "currentChapter": frenchA1Chapter0,
        "progress": [],
      },
    },
  };
  const activeCourse = englishA1Ref;
  const courses = [englishA1Ref, frenchA1Ref];
  const currentChapter = englishA1Chapter0;
  const stars = 0;
  const position = 0;

  try {
    await admin.firestore().collection("users").doc(userId).set({
      email: userEmail,
      achievements: achievements,
      score: score,
      premiumMembership: premiumMembership,
      league: league,
      level: level,
      activeCourse: activeCourse,
      activeLanguage: activeLanguage,
      activeLevel: activeLevel,
      myCourses: myCourses,
      hearts: hearts,
      currentChapter: currentChapter,
      courses: courses,
      stars: stars,
      starsMap: starsMap,
      position: position,
      createdAt: Firestore.FieldValue.serverTimestamp(),
    });
    logger.log(`Successfully created user document for UID: ${userId}`);
    await admin.firestore().collection("users")
        .doc(userId).collection("vocabulary").doc("eng_de").set({
          "language": "German",
        });
    await admin.firestore().collection("users")
        .doc(userId).collection("vocabulary").doc("eng_fr").set({
          "language": "French",
        });
    await admin.firestore().collection("rateLimits").doc(userId).set({
      chat: 10,
      transform: 1,
      generateChapter: 1,
      questionAnswerExercise: 2,
      writingExercise: 2,
    });
  } catch (error) {
    logger.error(`Error creating user document for UID: ${userId}`, error);
  }
});


exports.resetRates = functions.pubsub
    .schedule("0 0 * * *")
    .timeZone("UTC")
    .onRun(async (context) => {
      const db = admin.firestore();
      try {
        const usersSnapshot = await db.collection("rateLimits").get();
        for (const doc of usersSnapshot.docs) {
          await doc.ref.update({
            chat: 10,
            transform: 1,
            generateChapter: 1,
            questionAnswerExercise: 2,
            writingExercise: 2,

          });
        }
        logger.log("Reset rates completed successfully");
        return null;
      } catch (error) {
        logger.error("Error resetting rates:", error);
        return null;
      }
    });

exports.resetHearts = functions.pubsub
    .schedule("0 0 * * *")
    .timeZone("UTC")
    .onRun(async (context) => {
      const db = admin.firestore();
      const auth = admin.auth();
      try {
        const usersSnapshot = await db.collection("users").get();
        for (const doc of usersSnapshot.docs) {
          if ((await auth.getUser(doc.id)).customClaims.stripeRole) {
            // Add 5 hearts to premium usersa
            await doc.ref.update({
              hearts: Firestore.FieldValue.increment(5),
            });
          } else {
            // Reset hearts to 5 for non-premium users
            await doc.ref.update({
              hearts: 5,
            });
          }
        }
        logger.log("Reset hearts completed successfully");
        return null;
      } catch (error) {
        logger.error("Error resetting hearts:", error);
        return null;
      }
    });
