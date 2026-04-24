const admin = require("firebase-admin");
const fs = require("fs");
const csv = require("csv-parser");

const serviceAccount = require("./lexia-5a462-firebase-adminsdk-fbsvc-240ef9b957.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const INPUT_CSV = "./sampled_words_400_each.csv";
const COLLECTION_NAME = "vocabulary_test";
const BATCH_SIZE = 400;
const PAUSE_MS = 1500;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function cleanKey(key) {
  return key.replace(/^\uFEFF/, "").trim();
}

async function readCsv() {
  return new Promise((resolve, reject) => {
    const rows = [];

    fs.createReadStream(INPUT_CSV)
      .pipe(csv())
      .on("data", (row) => {
        const cleaned = {};
        for (const key of Object.keys(row)) {
          cleaned[cleanKey(key)] = row[key];
        }
        rows.push(cleaned);
      })
      .on("end", () => resolve(rows))
      .on("error", reject);
  });
}

function chunkArray(array, size) {
  const result = [];
  for (let i = 0; i < array.length; i += size) {
    result.push(array.slice(i, i + size));
  }
  return result;
}

function makeDocId(word) {
  return word
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

async function uploadWords() {
  try {
    const rows = await readCsv();

    console.log(`Read ${rows.length} rows from CSV.`);

    const chunks = chunkArray(rows, BATCH_SIZE);
    console.log(`Uploading in ${chunks.length} batches...`);

    for (let i = 0; i < chunks.length; i++) {
      const batch = db.batch();

      for (const row of chunks[i]) {
        const word = String(row.word || "").trim().toLowerCase();
        const totalScore = Number(row.total_score);
        const difficulty = String(row.difficulty || "").trim();
        const level = Number(row.level);

        if (!word || !level || !totalScore) {
          console.log("Skipped row:", row);
          continue;
        }

        const docId = makeDocId(word);
        const docRef = db.collection(COLLECTION_NAME).doc(docId);

        batch.set(docRef, {
          word,
          total_score: totalScore,
          difficulty,
          level,
          shuffle_key: Math.random(),
          status: "pending",
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      console.log(`Batch ${i + 1}/${chunks.length} uploaded.`);

      if (i < chunks.length - 1) {
        await sleep(PAUSE_MS);
      }
    }

    console.log("Upload completed successfully.");
  } catch (error) {
    console.error("Upload failed:", error);
  }
}

uploadWords();