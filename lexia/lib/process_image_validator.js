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

const validatorModel = genAI.getGenerativeModel({
  model: "gemini-2.5-flash",
});

const imageModel = genAI.getGenerativeModel({
  model: "gemini-2.5-flash-image",
});

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function cleanFileName(word) {
  return word
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9_-]/g, "_");
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

function buildImageValidationPrompt(word) {
  return `
You are validating an image for Lexia, a children's English learning app.

Word:
"${word}"

Check whether the image clearly represents the word.

Return ONLY valid JSON:

{
  "image_matches_word": true/false,
  "reason": "short reason"
}

Rules:
- Return true if the image reasonably represents the word.
- Return false ONLY if the image is clearly unrelated, confusing, or represents a different word.
- Return false if the image contains text, letters, logos, or watermarks.
- Return false if the image is inappropriate for children aged 5–12.
- Do NOT reject for small style differences.
- Do NOT reject only because the image is not perfect.
- Be practical and strict only when the image is clearly wrong.

Return JSON only.
`;
}

async function validateImageWithRetry(word, imageBase64, maxRetries = 3) {
  const prompt = buildImageValidationPrompt(word);

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await validatorModel.generateContent([
        prompt,
        {
          inlineData: {
            data: imageBase64,
            mimeType: "image/png",
          },
        },
      ]);
    } catch (error) {
      if (!isTemporaryError(error) || attempt === maxRetries) throw error;

      const waitTime = attempt * 10000;
      console.log(
        `⏳ Validation retry ${attempt} for ${word} in ${waitTime / 1000}s`,
      );
      await sleep(waitTime);
    }
  }
}

async function generateImageWithRetry(word, category, maxRetries = 3) {
  const prompt = buildImagePrompt(word, category);

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await imageModel.generateContent(prompt);
    } catch (error) {
      if (!isTemporaryError(error) || attempt === maxRetries) throw error;

      const waitTime = attempt * 10000;
      console.log(
        `⏳ Image retry ${attempt} for ${word} in ${waitTime / 1000}s`,
      );
      await sleep(waitTime);
    }
  }
}

async function replaceImage(doc, data) {
  const word = data.word;
  const category = data.category || "unknown";

  const result = await generateImageWithRetry(word, category);

  const parts = result.response.candidates?.[0]?.content?.parts || [];
  const imagePart = parts.find((part) => part.inlineData?.data);

  if (!imagePart) {
    throw new Error("No replacement image returned from Gemini.");
  }

  const imageBase64 = imagePart.inlineData.data;
  const buffer = Buffer.from(imageBase64, "base64");

  const fileName = cleanFileName(word);
  const filePath = data.image_storage_path || `word_images/${fileName}.png`;
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
    image_storage_path: filePath,
    image_status: "done",
    image_changed: true,
    image_validation_status: "done",
    image_validation_error: admin.firestore.FieldValue.delete(),
  });

  console.log(`🔁 ${word} image replaced`);
}

async function processImageValidation() {
  const snapshot = await db
    .collection("vocabulary_test")
    .where("image_status", "==", "done")
    .get();

  if (snapshot.empty) {
    console.log("No generated images found.");
    return;
  }

  const docsToValidate = snapshot.docs
    .filter((doc) => doc.data().image_validation_status !== "done")
    .slice(0, 30);

  if (docsToValidate.length === 0) {
    console.log("No images to validate.");
    return;
  }

  console.log(`Validating ${docsToValidate.length} images...`);

  for (const doc of docsToValidate) {
    const data = doc.data();
    const word = data.word;
    const imagePath = data.image_storage_path;

    try {
      if (!imagePath) {
        throw new Error("Missing image_storage_path.");
      }

      const file = bucket.file(imagePath);
      const [buffer] = await file.download();
      const imageBase64 = buffer.toString("base64");

      const result = await validateImageWithRetry(word, imageBase64);
      const text = result.response.text();

      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error("Invalid JSON from image validator.");

      const validationData = JSON.parse(jsonMatch[0]);
      const matches = validationData.image_matches_word === true;

      if (matches) {
        await doc.ref.update({
          image_changed: false,
          image_validation_status: "done",
          image_validation_reason: validationData.reason || "",
          image_validation_error: admin.firestore.FieldValue.delete(),
        });

        console.log(` ${word} image valid`);
      } else {
        console.log(` ${word} image mismatch. Replacing image...`);
        await replaceImage(doc, data);

        await doc.ref.update({
          image_validation_reason:
            validationData.reason || "Image did not match word.",
        });
      }
    } catch (e) {
      console.log(`❌ Error validating ${word}:`, e.message);

      await doc.ref.update({
        image_validation_status: isTemporaryError(e) ? "pending" : "error",
        image_validation_error: e.message,
      });
    }

    await sleep(8000);
  }

  console.log("🎉 Image validation batch done!");
}

processImageValidation();
