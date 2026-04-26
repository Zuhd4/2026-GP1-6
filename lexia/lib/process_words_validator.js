require("dotenv").config();
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const serviceAccount = require("./lexia-5a462-firebase-adminsdk-fbsvc-240ef9b957.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function buildValidationPrompt(word, aiResult) {
  return `
You are a strict validator for Lexia, a children's English literacy app for ages 5–12.

Your job is to check whether the PREVIOUS AI classification is accurate.

Word:
"${word}"

Previous AI classification:
${JSON.stringify(aiResult, null, 2)}

Return ONLY valid JSON:

{
  "is_valid": true/false
}

Important meaning:
- is_valid = true means the previous AI classification is correct.
- is_valid = false means one or more previous AI fields are incorrectly classified.
- Do NOT require all fields to be true.
- A word can be valid even if is_representable is false, as long as false is the correct classification.
- A word can be valid even if is_educational is false, as long as false is the correct classification.
- A word can be valid even if is_safe is false, as long as false is the correct classification.

Validate these fields:
1. is_safe
2. is_educational
3. is_representable
4. category

Validation rules:
- is_safe should be false for violence, harm, weapons, scary meanings, adult/inappropriate meanings, insults, swearing, racist/discriminatory language, bullying, religion, politics, or offensive words.
- is_safe should be true for harmless normal words.

- is_educational should be true if the word is a real standard English word that is useful/common enough for children aged 5–12 to learn.
- is_educational should be false for acronyms, filler sounds, slang, names, random letters, misspellings, very rare words, overly advanced adult/technical/legal/political/medical words, or words with low vocabulary-learning value.

- is_representable should be true only if the word can be clearly represented by a simple child-friendly image without needing text or explanation.
- is_representable should be false for abstract words, unclear adjectives/adverbs, context-dependent verbs, filler sounds, acronyms, social roles, or concepts that need explanation.

- category should be correct based on the word and allowed categories:
  animal, food, object, nature, action, place, body, emotion, unknown.
- category should be "unknown" if the word is invalid, unsafe, abstract, unclear, or does not fit any allowed category.

Examples:
- Word "address" with is_safe=true, is_educational=true, is_representable=false, category="place" can be valid if these classifications are accurate.
- Word "ah" with is_safe=false, is_educational=false, is_representable=false, category="unknown" is valid because "ah" is a filler sound.
- Word "apple" with is_safe=true, is_educational=true, is_representable=true, category="food" is valid.
- Word "actual" with is_safe=true, is_educational=false, is_representable=false, category="unknown" can be valid because it is not clearly image-representable and has low child vocabulary-game value.

Be strict, but judge classification correctness only.
Return JSON only. No markdown. No explanation.
`;
}

async function validateWords() {
  const snapshot = await db
    .collection("vocabulary_test")
    .where("status", "==", "done")
    .limit(50)
    .get();

  if (snapshot.empty) {
    console.log("No words to validate.");
    return;
  }

  console.log(`Validating ${snapshot.size} words...`);

  for (const doc of snapshot.docs) {
    const data = doc.data();

    if (data.validation_status === "done") {
      continue;
    }

    const word = data.word;

    const aiResult = {
      is_safe: data.is_safe ?? false,
      is_educational: data.is_educational ?? false,
      is_representable: data.is_representable ?? false,
      category: data.category ?? "unknown",
    };

    try {
      const result = await model.generateContent(
        buildValidationPrompt(word, aiResult)
      );

      const text = result.response.text();
      const jsonMatch = text.match(/\{[\s\S]*\}/);

      if (!jsonMatch) throw new Error("Invalid JSON");

      const validatorData = JSON.parse(jsonMatch[0]);

      await doc.ref.update({
        is_valid: validatorData.is_valid ?? false,
        validation_status: "done",
      });

      console.log(`✅ ${word} → ${validatorData.is_valid}`);
    } catch (e) {
      console.log(`❌ Error with ${word}:`, e.message);

      await doc.ref.update({
        validation_status: "pending",
        validator_error: e.message,
      });
    }

    await sleep(2000);
  }

  console.log("🎉 Validation batch done!");
}

validateWords();