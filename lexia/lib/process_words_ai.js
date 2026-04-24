require("dotenv").config();
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// 🔑 Firebase
const serviceAccount = require("./lexia-5a462-firebase-adminsdk-fbsvc-240ef9b957.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// 🔑 Gemini
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

// 🧠 البرومبت
function buildPrompt(word) {
  return `
Analyze the word "${word}" for children aged 5–12.

Return ONLY valid JSON with this exact structure:

{
  "is_safe": true/false,
  "is_educational": true/false,
  "is_representable": true/false,
  "category": "animal | food | object | nature | action | place | unknown"
}

Strict Rules:
- is_safe = false if the word includes or strongly relates to:
  - violence
  - harm
  - weapons
  - fear or scary meanings
  - inappropriate or adult meanings
  - insults or offensive language
  - person names
  - religion or religious terms

- VERY IMPORTANT: If the word is religious or related to religion, set:
  - is_safe = false
  - is_educational = false
  - is_representable = false
  - category = "unknown"

- is_educational = true ONLY if:
  - the word is a real English word
  - the word is common and useful for children learning English
  - the word is suitable for children aged 5–12
  - the word is not slang, not a shortcut, not a name, and not too advanced

- is_representable = true ONLY if:
  - the word is concrete and easy to draw or visualize, like apple, dog, chair, run
  - the word is NOT abstract, like freedom, justice, belief, poverty, meaning

Extra rules:
- If the word is not suitable for children, set all boolean fields to false.
- If the word is not a valid/common English word, set all boolean fields to false.
- Do not delete or remove the word. Only return false values when it is not suitable.
- Be strict because this is for a children's learning app.
`;
}

// 🔁 معالجة الكلمات
async function processWords() {
  const snapshot = await db
    .collection("vocabulary_test")
    .where("status", "==", "pending")
    .limit(5) // 🔥 تجربة أول 5 كلمات فقط
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

      if (isTemporaryError(e)) {
        await doc.ref.update({
          status: "pending",
        });
        console.log(`⏳ ${word} will retry later`);
      } else {
        await doc.ref.update({
          status: "error",
        });
      }
    }
    await sleep(15000);
  }

  console.log("🎉 Done batch!");
}

processWords();
