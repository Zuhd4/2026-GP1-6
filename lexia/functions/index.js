
"use strict";

const crypto = require("node:crypto");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");

initializeApp();

const db = getFirestore();
const pinPepper = defineSecret("LEXIA_PIN_PEPPER");
const pinRecoveryKey = defineSecret("LEXIA_PIN_RECOVERY_KEY");

const REGION = "me-central1";
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 16;

// Family Code reset: 5 minutes.
const RESET_MS = 5 * 60 * 1000;

// Child picture PIN: 5 attempts, then 5 minutes.
const PIN_LOCK_MS = 5 * 60 * 1000;
const PIN_MAX_FAILURES = 5;

// Separate Family Code lookup abuse protection.
const PROFILE_LOOKUP_LOCK_MS = 15 * 60 * 1000;
const PROFILE_LOOKUP_MAX = 10;

const codeRegistry = db.collection("users")
    .doc("_familyCodeRegistry").collection("codes");

const attemptRegistry = db.collection("users")
    .doc("_familyCodeRegistry").collection("lookupAttempts");

/**
 * Generate a cryptographically random Family Code.
 * @return {string} New code.
 */
function newCode() {
  let result = "";

  for (let i = 0; i < CODE_LENGTH; i++) {
    result += CODE_ALPHABET[
        crypto.randomInt(CODE_ALPHABET.length)];
  }

  return result;
}

/**
 * Normalize a Family Code.
 * @param {unknown} value Input.
 * @return {string} Normalized code.
 */
function normalizeCode(value) {
  return typeof value === "string" ?
    value.toUpperCase().replace(/[\s-]/g, "") : "";
}

/**
 * Require a parent authenticated by email/password.
 * @param {Object} request Callable request.
 * @return {string} Parent UID.
 */
function requireParent(request) {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Parent sign-in required.",
    );
  }

  const claims = request.auth.token;

  if (
    claims.role === "child" ||
    !claims.firebase ||
    claims.firebase.sign_in_provider !== "password"
  ) {
    throw new HttpsError(
        "permission-denied",
        "Parent account required.",
    );
  }

  return request.auth.uid;
}

/**
 * Validate a three-picture PIN.
 * @param {unknown} value PIN sequence.
 * @return {string} Normalized PIN.
 */
function validatePin(value) {
  if (
    !Array.isArray(value) ||
    value.length !== 3 ||
    !value.every(
        (v) => Number.isInteger(v) && v >= 1 && v <= 9,
    )
  ) {
    throw new HttpsError(
        "invalid-argument",
        "Select exactly three images (1-9).",
    );
  }

  return value.join("-");
}

/**
 * Generate a unique Firebase identity for a child.
 * @param {string} uid Parent UID.
 * @param {string} id Child document ID.
 * @return {string} Child Firebase UID.
 */
function childAuthUid(uid, id) {
  return "lexia_child_" + crypto
      .createHash("sha256")
      .update(JSON.stringify([uid, id]))
      .digest("hex");
}

/**
 * Validate a child document ID.
 * @param {unknown} id Child ID.
 * @return {boolean} Whether the ID is valid.
 */
function validChildId(id) {
  return typeof id === "string" &&
      id.length > 0 &&
      id.length <= 128 &&
      !id.includes("/");
}

/**
 * Generate a keyed digest of a picture PIN.
 * @param {string} pin Picture PIN.
 * @param {string} salt Random salt.
 * @return {string} PIN digest.
 */
function pinDigest(pin, salt) {
  const secret = pinPepper.value();

  if (!secret || secret.length < 32) {
    throw new HttpsError(
        "failed-precondition",
        "PIN secret is not configured.",
    );
  }

  return crypto
      .createHmac("sha256", secret)
      .update(salt + ":" + pin)
      .digest("hex");
}

/**
 * Compare PIN digests securely.
 * @param {string} actual Actual digest.
 * @param {string} expected Expected digest.
 * @return {boolean} Whether they match.
 */
function safeMatch(actual, expected) {
  if (
    !/^[0-9a-f]{64}$/.test(actual || "") ||
    !/^[0-9a-f]{64}$/.test(expected || "")
  ) {
    return false;
  }

  return crypto.timingSafeEqual(
      Buffer.from(actual, "hex"),
      Buffer.from(expected, "hex"),
  );
}

/**
 * Calculate the remaining lockout period.
 * @param {Object} entry Attempt-tracking data.
 * @param {number} now Current time in milliseconds.
 * @return {number} Remaining milliseconds.
 */
function lockRemaining(entry, now) {
  const until = entry &&
      entry.lockedUntil &&
      typeof entry.lockedUntil.toMillis === "function" ?
    entry.lockedUntil.toMillis() : 0;

  return Math.max(0, until - now);
}

/**
 * Encrypt a recoverable copy of the picture sequence for the parent.
 * This is separate from the one-way login verifier.
 * @param {string} pin Normalized picture sequence.
 * @param {string} parentUid Parent UID.
 * @param {string} childId Child ID.
 * @return {Object} Encrypted sequence.
 */
function encryptPinRecovery(pin, parentUid, childId) {
  const raw = pinRecoveryKey.value();
  if (!/^[0-9a-fA-F]{64}$/.test(raw || "")) {
    throw new HttpsError("failed-precondition", "Recovery key invalid.");
  }
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(
      "aes-256-gcm", Buffer.from(raw, "hex"), iv);
  cipher.setAAD(Buffer.from(JSON.stringify([parentUid, childId])));
  const ciphertext = Buffer.concat([
    cipher.update(pin, "utf8"), cipher.final(),
  ]);
  return {
    version: 1,
    iv: iv.toString("base64"),
    ciphertext: ciphertext.toString("base64"),
    tag: cipher.getAuthTag().toString("base64"),
  };
}

/**
 * Decrypt parent recovery copy.
 * @param {Object} data Encrypted sequence.
 * @param {string} parentUid Parent UID.
 * @param {string} childId Child ID.
 * @return {Array<number>} Picture identifiers.
 */
function decryptPinRecovery(data, parentUid, childId) {
  const raw = pinRecoveryKey.value();
  if (!/^[0-9a-fA-F]{64}$/.test(raw || "") ||
      !data || data.version !== 1) {
    throw new HttpsError("failed-precondition", "Recovery unavailable.");
  }
  try {
    const decipher = crypto.createDecipheriv(
        "aes-256-gcm", Buffer.from(raw, "hex"),
        Buffer.from(data.iv, "base64"));
    decipher.setAAD(Buffer.from(JSON.stringify([parentUid, childId])));
    decipher.setAuthTag(Buffer.from(data.tag, "base64"));
    const pin = Buffer.concat([
      decipher.update(Buffer.from(data.ciphertext, "base64")),
      decipher.final(),
    ]).toString("utf8");
    const sequence = pin.split("-").map(Number);
    validatePin(sequence);
    return sequence;
  } catch (e) {
    throw new HttpsError("failed-precondition", "Recovery unavailable.");
  }
}

// ====================================================
// FUNCTION 1: MANAGE FAMILY CODE
// ====================================================

exports.manageFamilyCode = onCall({
  region: REGION,
  maxInstances: 10,
}, async (request) => {
  const uid = requireParent(request);
  const action = (request.data || {}).action || "get";

  if (action !== "get" && action !== "reset") {
    throw new HttpsError(
        "invalid-argument",
        "Invalid action.",
    );
  }

  const parentRef = db.collection("users").doc(uid);

  for (let i = 0; i < 10; i++) {
    const candidate = newCode();
    const candidateRef = codeRegistry.doc(candidate);

    const result = await db.runTransaction(async (tx) => {
      const parentSnap = await tx.get(parentRef);

      if (!parentSnap.exists) {
        throw new HttpsError(
            "failed-precondition",
            "Parent document missing.",
        );
      }

      const parent = parentSnap.data();
      const now = Date.now();

      const oldCode =
          typeof parent.familyCode === "string" ?
            parent.familyCode : "";

      const lastReset = parent.familyCodeLastResetAt;

      const last = lastReset &&
          typeof lastReset.toMillis === "function" ?
        lastReset.toMillis() : 0;

      const remaining = last ?
        Math.max(0, last + RESET_MS - now) : 0;

      // Return the existing Family Code.
      if (action === "get" && oldCode) {
        return {
          familyCode: oldCode,
          canReset: remaining === 0,
          retryAfterSeconds: Math.ceil(
              remaining / 1000,
          ),
        };
      }

      // A Family Code must exist before reset.
      if (action === "reset" && !oldCode) {
        throw new HttpsError(
            "failed-precondition",
            "Generate a code first.",
        );
      }

      // Prevent another reset within 5 minutes.
      if (action === "reset" && remaining > 0) {
        throw new HttpsError(
            "resource-exhausted",
            "Wait before resetting.",
            {
              retryAfterSeconds: Math.ceil(
                  remaining / 1000,
              ),
            },
        );
      }

      if (candidate === oldCode) {
        return {collision: true};
      }

      // Reserve code atomically.
      const candidateSnap =
          await tx.get(candidateRef);

      if (candidateSnap.exists) {
        return {collision: true};
      }

      const oldRef = action === "reset" ?
        codeRegistry.doc(oldCode) : null;

      const oldSnap = oldRef ?
        await tx.get(oldRef) : null;

      if (
        oldSnap &&
        oldSnap.exists &&
        oldSnap.data().parentUid !== uid
      ) {
        throw new HttpsError(
            "failed-precondition",
            "Code ownership mismatch.",
        );
      }

      tx.create(candidateRef, {
        parentUid: uid,
        createdAt: Timestamp.fromMillis(now),
      });

      if (oldRef && oldSnap.exists) {
        tx.delete(oldRef);
      }

      const update = {
        familyCode: candidate,
        familyCodeCreatedAt: Timestamp.fromMillis(now),
      };

      if (action === "reset") {
        update.familyCodeLastResetAt =
            Timestamp.fromMillis(now);
      }

      tx.update(parentRef, update);

      return {
        familyCode: candidate,
        canReset: action !== "reset",
        retryAfterSeconds:
            action === "reset" ? 300 : 0,
      };
    });

    if (!result.collision) {
      return result;
    }
  }

  throw new HttpsError(
      "unavailable",
      "Could not reserve a Family Code.",
  );
});

// ====================================================
// FUNCTION 2: VERIFY FAMILY CODE
// ====================================================

exports.verifyFamilyCode = onCall({
  region: REGION,
  maxInstances: 10,
}, async (request) => {
  const code = normalizeCode(
      (request.data || {}).familyCode,
  );

  if (
    code.length !== CODE_LENGTH ||
    [...code].some(
        (c) => !CODE_ALPHABET.includes(c),
    )
  ) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid Family Code format.",
    );
  }

  // Rate-limit Family Code lookup requests.
  const ip = (
    request.rawRequest &&
    request.rawRequest.ip
  ) || "unknown";

  const bucket = crypto
      .createHash("sha256")
      .update(ip)
      .digest("hex");

  const attemptsRef = attemptRegistry.doc(bucket);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(attemptsRef);
    const now = Date.now();

    const record = snap.exists ?
      snap.data() : {};

    if (lockRemaining(record, now) > 0) {
      throw new HttpsError(
          "resource-exhausted",
          "Try again later.",
      );
    }

    const start = record.windowStart &&
        typeof record.windowStart.toMillis ===
          "function" ?
      record.windowStart.toMillis() : 0;

    const active =
        now - start < PROFILE_LOOKUP_LOCK_MS;

    const count = active ?
      (record.count || 0) + 1 : 1;

    tx.set(attemptsRef, {
      count: count,
      windowStart: Timestamp.fromMillis(
          active ? start : now,
      ),
      lockedUntil: count >= PROFILE_LOOKUP_MAX ?
        Timestamp.fromMillis(
            now + PROFILE_LOOKUP_LOCK_MS,
        ) : null,
    });
  });

  const indexSnap = await codeRegistry.doc(code).get();

  if (!indexSnap.exists) {
    throw new HttpsError(
        "not-found",
        "Family Code not found.",
    );
  }

  const parentUid = indexSnap.data().parentUid;

  const parent = await db
      .collection("users")
      .doc(parentUid)
      .get();

  if (
    !parent.exists ||
    parent.data().familyCode !== code
  ) {
    throw new HttpsError(
        "not-found",
        "Family Code not found.",
    );
  }

  const children = await parent.ref
      .collection("children")
      .get();

  return {
    profiles: children.docs.map((doc) => ({
      childId: doc.id,
      name: String(doc.data().name || ""),
      avatarUrl: String(
          doc.data().avatarUrl || "",
      ),
    })),
  };
});

// ====================================================
// FUNCTION 3: MANAGE CHILD PICTURE PIN
// ====================================================


exports.manageChildPin = onCall({
  region: REGION,
  maxInstances: 10,
  secrets: [pinPepper, pinRecoveryKey],
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "Sign-in required.",
    );
  }

  const data = request.data || {};
  const action = data.action;

  if (
    !validChildId(data.childId) ||
    !["set", "reset", "change", "verify", "getRecovery"].includes(action)
  ) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid child or action.",
    );
  }

  const childSession =
      request.auth.token.role === "child";

  let parentUid;

  if (childSession) {
    if (
      !(["change", "verify"].includes(action)) ||
      request.auth.token.childId !== data.childId
    ) {
      throw new HttpsError(
          "permission-denied",
          "Cannot change this PIN.",
      );
    }

    parentUid = request.auth.token.parentUid;
  } else {
    parentUid = requireParent(request);

    if (action === "change" || action === "verify") {
      throw new HttpsError(
          "invalid-argument",
          "Parents must use set or reset.",
      );
    }
  }

  if (
    typeof parentUid !== "string" ||
    !parentUid
  ) {
    throw new HttpsError(
        "permission-denied",
        "Invalid family identity.",
    );
  }

  // Only a signed-in parent can reach this branch. Child sessions
  // are restricted to changing their own PIN above.
  if (action === "getRecovery") {
    const pinRef = db.collection("users").doc(parentUid)
        .collection("children").doc(data.childId)
        .collection("privateAuth").doc("picturePin");
    const snap = await pinRef.get();
    if (!snap.exists || !snap.data().recovery) {
      return {available: false, requiresReset: true};
    }
    return {
      available: true,
      sequence: decryptPinRecovery(
          snap.data().recovery, parentUid, data.childId),
    };
  }

  const nextPin = action === "verify" ? null :
    validatePin(data.newPin);

  const oldPin = ["change", "verify"].includes(action) ?
    validatePin(data.oldPin) : null;

  const childRef = db
      .collection("users")
      .doc(parentUid)
      .collection("children")
      .doc(data.childId);

  // Private PIN document, inaccessible to Flutter.
  const pinRef = childRef
      .collection("privateAuth")
      .doc("picturePin");

  const salt = crypto.randomBytes(16)
      .toString("hex");

  const digest = nextPin === null ? null : pinDigest(nextPin, salt);
  const recovery = nextPin === null ? null :
    encryptPinRecovery(nextPin, parentUid, data.childId);

  const result = await db.runTransaction(async (tx) => {
    // Read all documents before performing writes.
    const childSnap = await tx.get(childRef);
    const pinSnap = await tx.get(pinRef);

    if (!childSnap.exists) {
      throw new HttpsError(
          "not-found",
          "Child profile not found.",
      );
    }

    const currentPin = pinSnap.exists ?
      pinSnap.data() : null;

    const now = Date.now();

    if (action === "change" || action === "verify") {
      if (
        !currentPin ||
        !currentPin.salt ||
        !currentPin.digest
      ) {
        throw new HttpsError(
            "failed-precondition",
            "Picture PIN is not configured.",
        );
      }

      const remaining = lockRemaining(
          currentPin,
          now,
      );

      if (remaining > 0) {
        throw new HttpsError(
            "resource-exhausted",
            "PIN temporarily locked.",
            {
              retryAfterSeconds: Math.ceil(
                  remaining / 1000,
              ),
            },
        );
      }

      const matches = safeMatch(
          pinDigest(oldPin, currentPin.salt),
          currentPin.digest,
      );

      if (!matches) {
        const expired = currentPin.lockedUntil &&
            remaining === 0;

        const previousFailures = expired ?
          0 : (currentPin.failures || 0);

        const failures = previousFailures + 1;

        const locked = failures >= PIN_MAX_FAILURES;

        tx.update(pinRef, {
          failures: failures,
          lockedUntil: locked ?
            Timestamp.fromMillis(now + PIN_LOCK_MS) :
            null,
        });

        return {
          incorrect: true,
          retryAfterSeconds: locked ?
            PIN_LOCK_MS / 1000 : 0,
        };
      }
    }

    // Verification only: do not update the PIN or its metadata.
    if (action === "verify") {
      return {success: true};
    }

    // Store PIN verifier privately.
    tx.set(pinRef, {
      salt: salt,
      digest: digest,
      recovery: recovery,
      failures: 0,
      lockedUntil: null,
      updatedAt: Timestamp.fromMillis(now),
    });

    // Store only non-sensitive PIN status
    // in the regular child profile.
    tx.update(childRef, {
      picturePinEnabled: true,
      picturePinUpdatedAt:
          Timestamp.fromMillis(now),
    });

    return {success: true};
  });

  // Throw after transaction commits the failed attempt.
  if (result.incorrect) {
    throw new HttpsError(
        "permission-denied",
        "Incorrect picture PIN.",
        {
          retryAfterSeconds:
              result.retryAfterSeconds,
        },
    );
  }

  return {success: true};
});


// ====================================================
// FUNCTION 4: LOGIN CHILD
// ====================================================


exports.loginChild = onCall({
  region: REGION,
  maxInstances: 10,
  secrets: [pinPepper],
}, async (request) => {
  const data = request.data || {};

  const code = normalizeCode(data.familyCode);

  if (
    code.length !== CODE_LENGTH ||
    [...code].some(
        (c) => !CODE_ALPHABET.includes(c),
    ) ||
    !validChildId(data.childId)
  ) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid login details.",
    );
  }

  const pin = validatePin(data.pin);

  // Resolve Family Code to parent.
  const codeSnap = await codeRegistry
      .doc(code)
      .get();

  if (!codeSnap.exists) {
    throw new HttpsError(
        "permission-denied",
        "Invalid login details.",
    );
  }

  const parentUid = codeSnap.data().parentUid;

  const parentRef = db
      .collection("users")
      .doc(parentUid);

  const childRef = parentRef
      .collection("children")
      .doc(data.childId);

  const pinRef = childRef
      .collection("privateAuth")
      .doc("picturePin");

  const result = await db.runTransaction(async (tx) => {
    // Read everything before writing.
    const parentSnap = await tx.get(parentRef);
    const childSnap = await tx.get(childRef);
    const pinSnap = await tx.get(pinRef);

    if (
      !parentSnap.exists ||
      parentSnap.data().familyCode !== code ||
      !childSnap.exists
    ) {
      throw new HttpsError(
          "permission-denied",
          "Invalid login details.",
      );
    }

    if (!pinSnap.exists) {
      throw new HttpsError(
          "failed-precondition",
          "Child PIN is not configured.",
      );
    }

    const storedPin = pinSnap.data();
    const now = Date.now();

    if (!storedPin.salt || !storedPin.digest) {
      throw new HttpsError(
          "failed-precondition",
          "Child PIN is not configured.",
      );
    }

    // Check temporary lockout.
    const remaining = lockRemaining(
        storedPin,
        now,
    );

    if (remaining > 0) {
      throw new HttpsError(
          "resource-exhausted",
          "PIN temporarily locked.",
          {
            retryAfterSeconds: Math.ceil(
                remaining / 1000,
            ),
          },
      );
    }

    const matches = safeMatch(
        pinDigest(pin, storedPin.salt),
        storedPin.digest,
    );

    if (!matches) {
      const expired = storedPin.lockedUntil &&
          remaining === 0;

      const previousFailures = expired ?
        0 : (storedPin.failures || 0);

      const failures = previousFailures + 1;

      const locked = failures >= PIN_MAX_FAILURES;

      tx.update(pinRef, {
        failures: failures,
        lockedUntil: locked ?
          Timestamp.fromMillis(now + PIN_LOCK_MS) :
          null,
      });

      return {
        incorrect: true,
        retryAfterSeconds: locked ?
          PIN_LOCK_MS / 1000 : 0,
      };
    }

    // Correct PIN: reset failed attempts.
    tx.update(pinRef, {
      failures: 0,
      lockedUntil: null,
    });

    return {success: true};
  });

  // Return the error only after the
  // failed-attempt transaction has committed.
  if (result.incorrect) {
    throw new HttpsError(
        "permission-denied",
        "Incorrect picture PIN.",
        {
          retryAfterSeconds:
              result.retryAfterSeconds,
        },
    );
  }

  // Create the child's Firebase identity.
  const uid = childAuthUid(
      parentUid,
      data.childId,
  );

  const claims = {
    role: "child",
    parentUid: parentUid,
    childId: data.childId,
  };

  const customToken = await getAuth()
      .createCustomToken(uid, claims);

  return {
    customToken: customToken,
    parentUid: parentUid,
    childId: data.childId,
  };
});


//
// FUNCTION 5: DELETE FAMILY ACCOUNT
//

exports.deleteFamilyAccount = onCall({
  region: REGION,
  maxInstances: 3,
  timeoutSeconds: 540,
  memory: "512MiB",
}, async (request) => {
  const uid = requireParent(request);

  // Require a recent parent authentication.
  const authTime = Number(request.auth.token.auth_time || 0);

  if (!authTime || Date.now() / 1000 - authTime > 5 * 60) {
    throw new HttpsError(
        "failed-precondition",
        "Please confirm your password again.",
    );
  }

  const parentRef = db.collection("users").doc(uid);
  const parentSnap = await parentRef.get();

  if (!parentSnap.exists) {
    throw new HttpsError(
        "not-found",
        "Parent profile not found.",
    );
  }

  const parent = parentSnap.data();

  const childrenSnap = await parentRef.collection("children").get();
  const childIds = childrenSnap.docs.map((doc) => doc.id);

  // Remove user-owned files from known Firebase Storage folders.
  const bucket = getStorage().bucket();

  for (const prefix of [
    "users/" + uid + "/",
    "parents/" + uid + "/",
  ]) {
    await bucket.deleteFiles({
      prefix,
      force: true,
    });
  }

  // Delete each child's Firebase Authentication account.
  for (const childId of childIds) {
    try {
      await getAuth().deleteUser(childAuthUid(uid, childId));
    } catch (e) {
      if (e.code !== "auth/user-not-found") {
        throw e;
      }
    }
  }

  // Remove the family's Family Code registry entry.
  const code = typeof parent.familyCode === "string" ?
    parent.familyCode : "";

  if (code) {
    const codeRef = codeRegistry.doc(code);
    const codeSnap = await codeRef.get();

    if (
      codeSnap.exists &&
      codeSnap.data().parentUid === uid
    ) {
      await codeRef.delete();
    }
  }

  // Recursively delete the parent's Firestore data,
  // including children, progress and private PIN records.
  await db.recursiveDelete(parentRef);

  // Delete the parent's Authentication account last.
  await getAuth().deleteUser(uid);

  return {success: true};
});

// ====================================================
// FUNCTION 6: DELETE ONE CHILD PROFILE
// ====================================================

exports.deleteChildProfile = onCall({
  region: REGION,
  maxInstances: 3,
  timeoutSeconds: 540,
  memory: "512MiB",
}, async (request) => {
  const parentUid = requireParent(request);
  const childId = (request.data || {}).childId;

  if (!validChildId(childId)) {
    throw new HttpsError(
        "invalid-argument",
        "Invalid child ID.",
    );
  }

  const childRef = db.collection("users")
      .doc(parentUid)
      .collection("children")
      .doc(childId);

  // Remove only this child's Storage files.
  await getStorage().bucket().deleteFiles({
    prefix: `users/${parentUid}/children/${childId}/`,
    force: true,
  });

  // Remove the child's Firebase Authentication identity.
  try {
    await getAuth().deleteUser(childAuthUid(parentUid, childId));
  } catch (error) {
    if (error.code !== "auth/user-not-found") {
      throw error;
    }
  }

  // Delete the child document and ALL subcollections.
  await db.recursiveDelete(childRef);

  return {success: true};
});
