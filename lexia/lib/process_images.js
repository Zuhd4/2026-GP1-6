require("dotenv").config();
const admin = require("firebase-admin");
const { GoogleGenerativeAI } = require("@google/generative-ai");


const serviceAccount = require("./lexia-5a462-firebase-adminsdk-fbsvc-240ef9b957.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "lexia-5a462.firebasestorage.app",
});

const db = admin.firestore();
const bucket = admin.storage().bucket();


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
Create a simple child-friendly educational illustration for the word "${word}".

Category hint: ${category}

IMPORTANT:
The category is only a hint. If the category does not fit the word clearly, ignore it and create the most direct simple visual meaning of the word.

IMAGE STYLE:
- Cute cartoon style
- Flat illustration, 2D
- Clean app-style educational icon
- Square image, 1:1 ratio
- Full image canvas must have one single solid soft pastel background color
- No rounded corners inside the generated image
- No transparent corners
- No black corners
- No borders, frames, shadows, glow, vignette, or extra background layers
- The app will apply rounded corners later, so generate a normal full square image

SUBJECT:
- One main subject only
- Subject centered
- Subject should fill about 60–75% of the image
- Leave balanced padding around the subject
- Clear, simple, easy for a child to recognize
- Bright friendly colors
- Suitable for children aged 5–12

DO NOT INCLUDE:
- No text
- No letters
- No numbers
- No logos
- No watermarks
- No realistic style
- No 3D style
- No complex scenes
- No multiple unrelated objects

CATEGORY GUIDANCE:

If category is "animal":
- Show one clear animal only

If category is "food":
- Show one clear food item only

If category is "object":
- Show one clear object only

If category is "nature":
- Show one clear natural element, such as sun, rain, tree, flower, mountain, or river

If category is "action":
- Show one child-friendly character clearly performing the action
- Keep the background simple

If category is "place":
- Show a very simple scene or building representing the place
- Avoid too many details

If category is "unknown":
- Create the simplest direct visual representation of the word
- If the word is too abstract, use the most concrete child-friendly symbol possible

FINAL CHECK:
The final image must look like one clean square educational icon with a pastel background and one centered cartoon subject.

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
    .slice(0, 20);

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
