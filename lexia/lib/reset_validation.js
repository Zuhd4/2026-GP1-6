require("dotenv").config();
const admin = require("firebase-admin");

const serviceAccount = require("./lexia-5a462-firebase-adminsdk-fbsvc-240ef9b957.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function resetValidation() {
  const snapshot = await db.collection("vocabulary_test").get();

  if (snapshot.empty) {
    console.log("No documents found.");
    return;
  }

  console.log(`Resetting ${snapshot.size} documents...`);

  const batch = db.batch();

  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {
      is_valid: admin.firestore.FieldValue.delete(),
      validation_status: admin.firestore.FieldValue.delete(),
      validator_error: admin.firestore.FieldValue.delete(),
    });
  });

  await batch.commit();

  console.log("✅ Validation fields removed!");
}

resetValidation();