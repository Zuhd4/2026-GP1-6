require("dotenv").config();
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");

// 🔑 Firebase
const serviceAccount = require("./lexia-5a462-firebase-adminsdk-fbsvc-240ef9b957.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "lexia-5a462.appspot.com",
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// 🔑 Gemini Image / Nano Banana
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({
  model: "gemini-2.5-flash-image",
});

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
    msg.includes("high demand") ||
    msg.includes("service unavailable")
  );
}

function cleanFileName(word) {
  return word
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9_-]/g, "_");
}

function buildImagePrompt(word, category) {
  return `
Generate a simple, clean, child-friendly illustration of the word "${word}".

Category: ${category}

GENERAL STYLE (VERY IMPORTANT):
- Style: cartoon, flat illustration (2D)
- The image must be in a square format (1:1 aspect ratio)
- The background must be a full square
- No circular backgrounds, no glow, no vignette
- Do NOT place the subject inside a circle
- The subject must be centered inside a square canvas
- Leave balanced padding around the object
- No realistic or 3D rendering
- No text, letters, numbers, or words in the image
- White or soft solid background (no gradients)
- Bright, friendly colors
- One clear subject only
- Clean shapes and simple design
- Suitable for children aged 5–12

Category-specific rules (ONLY apply if the word clearly belongs to the category):

Animals:
- Show one animal clearly
- No humans
- No background clutter

People / Jobs:
- Show a person doing the job
- Use simple visual hints such as uniform or tools
- No text labels

Plants:
- Show the plant clearly
- Keep it simple

Objects:
- Show one object centered
- No multiple items

Food:
- Show one food item only
- Clean and clear

Toys:
- Show one toy clearly

Clothes:
- Show clothing item alone OR worn by a simple figure

Places:
- Show a simple place or building
- Avoid too many objects

Actions:
- Show a person performing the action
- Minimal background

Nature:
- Show natural element clearly

IF THE WORD DOES NOT CLEARLY BELONG TO ANY CATEGORY:
- Follow ONLY the general style rules
- Create the simplest and most direct visual representation
- Do not add extra elements or complexity

Restrictions:
- No multiple unrelated objects
- No clutter
- No text, letters, numbers, logos, or watermarks
- No realistic style
- No complex scenes

Return image only.
`;
}

async function generateImageWithRetry(word, category, maxRetries = 3) {
  const prompt = buildImagePrompt(word, category);

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await model.generateContent(prompt);
    } catch (error) {
      if (!isTemporaryError(error) || attempt === maxRetries) {
        throw error;
      }

      const waitTime = attempt * 10000;
      console.log(
        `⏳ Temporary error with ${word}. Retry ${attempt}/${maxRetries - 1} in ${
          waitTime / 1000
        }s...`,
      );
      await sleep(waitTime);
    }
  }
}

async function processImages() {
  const snapshot = await db
    .collection("vocabulary_test")
    .where("status", "==", "done")
    .where("validation_status", "==", "done")
    .where("is_safe", "==", true)
    .where("is_educational", "==", true)
    .where("is_representable", "==", true)
    .get();

  if (snapshot.empty) {
    console.log("No valid words found for image generation.");
    return;
  }

  const docsToGenerate = snapshot.docs
    .filter((doc) => doc.data().image_status !== "done")
    .slice(0, 5);

  if (docsToGenerate.length === 0) {
    console.log("No images to generate.");
    return;
  }

  console.log(`Generating ${docsToGenerate.length} images...`);

  for (const doc of docsToGenerate) {
    const data = doc.data();
    const word = data.word;
    const category = data.category || "unknown";

    try {
      const result = await generateImageWithRetry(word, category);

      const parts = result.response.candidates?.[0]?.content?.parts || [];
      const imagePart = parts.find((part) => part.inlineData?.data);

      if (!imagePart) {
        throw new Error("No image returned from Gemini.");
      }

      const imageBase64 = imagePart.inlineData.data;
      const buffer = Buffer.from(imageBase64, "base64");

      const fileName = cleanFileName(word);
      const filePath = `word_images/${fileName}.png`;
      const file = bucket.file(filePath);

      await file.save(buffer, {
        metadata: {
          contentType: "image/png",
        },
      });

      const [url] = await file.getSignedUrl({
        action: "read",
        expires: "03-01-2030",
      });

      await doc.ref.update({
        image_url: url,
        image_status: "done",
        image_storage_path: filePath,
        image_error: admin.firestore.FieldValue.delete(),
      });

      console.log(`✅ ${word} image generated`);
    } catch (e) {
      console.log(`❌ Error with ${word}:`, e.message);

      await doc.ref.update({
        image_status: "error",
        image_error: e.message,
      });
    }

    await sleep(8000);
  }

  console.log("🎉 Image generation batch done!");
}

processImages();
