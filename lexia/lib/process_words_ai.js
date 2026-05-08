require("dotenv").config();
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");


const serviceAccount = require("./lexia-5a462-firebase-adminsdk-fbsvc-240ef9b957.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();


const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash-lite" });

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isTemporaryError(error) {
  const msg = (error?.message || "").toLowerCase();
  return (
    msg.includes("429") ||
    msg.includes("503") ||
    msg.includes("quota") ||
    msg.includes("too many requests") ||
    msg.includes("high demand")
  );
}

function isDailyQuotaError(error) {
  const msg = (error?.message || "").toLowerCase();
  return (
    (msg.includes("generate_content_free_tier_requests") &&
      msg.includes("perday")) ||
    msg.includes("generaterequestsperdayperprojectpermodel-freetier")
  );
}

function buildPrompt(word) {
  return `
You are validating a single word for Lexia, a children's English literacy app for children aged 5–12.

Analyze ONLY this word:
"${word}"

Return ONLY valid JSON with this exact structure:

{
  "is_safe": true/false,
  "is_educational": true/false,
  "is_representable": true/false,
  "category": "animal | food | object | nature | action | place | body | emotion | unknown"
}

Important: Be strict. When unsure, choose false.

Step 1: Valid English word check
- If the input is not a real, standard English word, set all boolean fields to false and category to "unknown".
- Set all boolean fields to false if the word is:
  - an abbreviation, acronym, or initialism, such as "usb", "hr", "ceo"
  - an interjection or filler sound, such as "ah", "uh", "hmm", "oh"
  - slang, internet slang, or informal shorthand
  - a proper name, brand name, username, place name, or person name
  - misspelled, nonsense, random letters, or not commonly used in standard English
  - a function word that is not useful as a learning vocabulary item, such as "the", "and", "too", "across"

Step 2: Safety check
- is_safe = false if the word includes or strongly relates to:
  - violence, harm, weapons, injury, or death
  - fear, horror, scary meanings, or distressing topics
  - inappropriate, adult, sexual, or vulgar meanings
  - insults, swearing, curse words, or bad words
  - racist, discriminatory, hateful, or offensive language toward any group
  - bullying or humiliating language
  - religion or religious terms
  - politics or politically sensitive terms
  - If is_safe is false, set:
  is_educational = false
  is_representable = false
  category = "unknown"

Step 3: Educational usefulness check
- is_educational = true ONLY if the word is:
  - a real, standard English word
  - common and useful for children aged 5–12
  - suitable for basic vocabulary learning
  - likely to appear in children's books, classrooms, daily life, games, or simple stories
- is_educational = false if the word is:
  - too advanced, academic, abstract, rare, technical, legal, political, medical, or specialized
  - mostly useful for adults, not children
  - a grammar/function word with low vocabulary value
  - an abbreviation, acronym, filler sound, name, slang, or unclear word

Step 4: Visual representability check
- is_representable = true ONLY if a simple child-friendly picture can clearly show the word without text or explanation.
- Good representable examples:
  - concrete objects: apple, chair, ball, pencil
  - animals: dog, cat, bird
  - foods: banana, bread, milk
  - nature items: tree, flower, sun
  - simple actions: run, jump, eat, sleep
  - simple places: park, school, beach
- is_representable = false if the word is:
  - abstract: freedom, justice, meaning, poverty, absence
  - emotion or state that is hard to show clearly: honest, proud, lonely, actual
  - relationship/social role that needs context: interviewee, acquaintance
  - adjective/adverb that is not visually clear alone: absolute, additional, adaptable, acidic
  - verb that is too abstract or context-dependent: achieve, confirm, accuse, adhere
  - filler/interjection/acronym: ah, usb, hmm
- If is_representable is false, set category to "unknown".

Category rules:
- Choose the closest category only if it is clear.
- Use "unknown" if the word is abstract, invalid, unsafe, too advanced, or not clearly in a category.
- Do not invent categories outside the allowed list.

Decision rules:
- If the word fails the English word check, set:
  is_safe=false, is_educational=false, is_representable=false, category="unknown"
- If the word is unsafe, religious, racist, insulting, vulgar, or inappropriate, set:
  is_safe=false, is_educational=false, is_representable=false, category="unknown"
- If the word is valid but abstract or hard to draw, is_representable=false, category="unknown".
- Only set all three booleans to true when the word is safe, common for children, educational, and clearly drawable.

Return JSON only. No explanation. No markdown.
`;
}

async function processWords() {
  const snapshot = await db
    .collection("vocabulary_test")
    .where("status", "==", "pending")
    .limit(100)
    .get();

  if (snapshot.empty) {
    console.log("No pending words.");
    return;
  }

  console.log(`Processing ${snapshot.size} words...`);

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const word = data.word;

    try {
      const result = await model.generateContent(buildPrompt(word));
      const text = result.response.text();

      // تنظيف الرد
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error("Invalid JSON");

      const aiData = JSON.parse(jsonMatch[0]);

      await doc.ref.update({
        is_safe: aiData.is_safe ?? false,
        is_educational: aiData.is_educational ?? false,
        is_representable: aiData.is_representable ?? false,
        category: aiData.category ?? "unknown",
        status: "done",
      });

      console.log(`✅ ${word} processed`);
    } catch (e) {
      console.log(`❌ Error with ${word}:`, e.message);

      if (isDailyQuotaError(e)) {
        await doc.ref.update({
          status: "pending",
        });
        console.log(
          "Daily Gemini free-tier quota reached. Stop processing for now.",
        );
        console.log(
          "Run this script again after the quota resets, or enable paid quota for the Gemini API project.",
        );
        return;
      }

      if (isTemporaryError(e)) {
        await doc.ref.update({
          status: "pending",
        });
        console.log(` ${word} will retry later`);
      } else {
        await doc.ref.update({
          status: "error",
        });
      }
    }
    await sleep(2000);
  }

  console.log("🎉 Done batch!");
}

async function resetAllToPending() {
  const snapshot = await db.collection("vocabulary_test").get();

  if (snapshot.empty) {
    console.log("No documents found in vocabulary_test.");
    return;
  }

  console.log(`Found ${snapshot.size} documents. Resetting to pending...`);

  let batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    batch.update(doc.ref, {
      status: "pending",
      is_safe: admin.firestore.FieldValue.delete(),
      is_educational: admin.firestore.FieldValue.delete(),
      is_representable: admin.firestore.FieldValue.delete(),
      category: admin.firestore.FieldValue.delete(),
    });

    count++;

    if (count % 500 === 0) {
      await batch.commit();
      console.log(`Updated ${count} documents...`);
      batch = db.batch();
    }
  }

  await batch.commit();
  console.log(`✅ Done. Reset ${count} documents to pending.`);
}

processWords();
//resetAllToPending();
