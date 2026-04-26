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
You are a strict classification quality reviewer for Lexia, a children's English literacy app for children aged 5–12.

You are reviewing an EXISTING Firestore document.

The document already contains the classification fields:
is_safe, is_educational, is_representable, and category.

Your job is to review the previous AI classification and CORRECT it if needed.

IMPORTANT:
- You MUST update the SAME fields:
  is_safe, is_educational, is_representable, category
- Do NOT create new fields like:
  corrected_is_safe, fixed_category, or validator_is_safe
- You are modifying the existing document, NOT creating a new one

Word:
"${word}"

Previous AI classification:
${JSON.stringify(aiResult, null, 2)}

Return ONLY valid JSON with this exact structure:

{
  "is_safe": true/false,
  "is_educational": true/false,
  "is_representable": true/false,
  "category": "animal | food | object | nature | action | place | unknown",
  "changed_fields": ["is_safe", "is_educational", "is_representable", "category"]
}

Rules:
- Always return the FINAL corrected values for ALL fields
- If a field is correct, keep it as it is
- If a field is incorrect, FIX it and add its name to changed_fields
- If all fields are correct, return:
  changed_fields: []

- Do NOT include correct fields in changed_fields
- A false value can be correct
- A word can correctly have all fields false
- A correct rejection is still a correct classification

Field Rules:

1. is_safe
- true ONLY if safe for children aged 5–12
- false if related to:
  violence, harm, weapons, fear, inappropriate/adult content,
  insults, offensive language, racism, bullying,
  person names, religion, or politics

2. is_educational
- true ONLY if:
  real English word
  common and useful for children aged 5–12
  suitable for learning basic vocabulary

- false if:
  not a real word
  nonsense or random letters
  misspelled
  abbreviation (usb, ceo)
  filler sound (ah, hmm)
  slang or shortcut
  name or proper noun
  too advanced or rare
  low learning value (like "the", "and", "anything")

3. is_representable
- true ONLY if:
  can be clearly shown in a simple image
  without text or explanation

- false if:
  abstract (freedom, meaning)
  unclear or needs context
  adjective/adverb hard to visualize (actual, absolute)
  social role (interviewee)
  filler or acronym

4. category
Allowed:
animal, food, object, nature, action, place, unknown

- choose only if clearly correct
- otherwise use "unknown"

Special Rules:
- If the word is religious:
  → all false + category "unknown"

- If the word is not valid English:
  → all false + category "unknown"

Examples:

Word: "abiyuch"
Previous:
all false
→ correct → no changes

Output:
{
  "is_safe": false,
  "is_educational": false,
  "is_representable": false,
  "category": "unknown",
  "changed_fields": []
}

Word: "abroad"
Previous:
representable = true → incorrect → should be false because it's an abstract concept, not clearly representable in a simple image

Output:
{
  "is_safe": true,
  "is_educational": true,
  "is_representable": false,
  "category": "place",
  "changed_fields": ["is_representable"]
}

Return JSON only.
`;
}

async function validateWords() {
  const snapshot = await db
    .collection("vocabulary_test")
    .where("status", "==", "done")
    .where("validation_status", "!=", "done")
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

      const changedFields = Array.isArray(validatorData.changed_fields)
        ? validatorData.changed_fields
        : [];

      await doc.ref.update({
        is_safe: validatorData.is_safe ?? data.is_safe ?? false,
        is_educational:
          validatorData.is_educational ?? data.is_educational ?? false,
        is_representable:
          validatorData.is_representable ?? data.is_representable ?? false,
        category: validatorData.category ?? data.category ?? "unknown",
        changed_fields: changedFields,
        validation_status: "done",
      });

      console.log(
        `✅ ${word} validated. Changed fields: ${changedFields.length ? changedFields.join(", ") : "none"}`
      );
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