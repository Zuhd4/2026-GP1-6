# Firestore Upload and AI Processing Scripts

This folder contains the backend scripts used by the development team to upload vocabulary data to Firebase and process it using Generative AI. These scripts are not part of the mobile application runtime. They are used only during development and data preparation.

## Files Description

### `upload_words.js`
Uploads vocabulary words from a dataset into the Firestore `vocabulary_test` collection.

### `process_words_ai.js`
Processes pending words using Gemini AI. 

### `process_words_validator.js`
Validates the initial AI classification results. 

### `process_images.js`
Generates images for validated words using Gemini image generation. 

### `process_image_validator.js`
Validates generated images
### `fix_status.js`
Used to update or fix document status fields in Firestore when needed during testing or processing.

### `reset_validation.js`
Resets validation-related fields so that words can be reprocessed or revalidated when needed.

### `package.json`
Contains the Node.js dependencies and script configuration for this folder.

### `package-lock.json`
Stores the exact installed versions of the Node.js dependencies.

### `node_modules/`
Contains installed Node.js packages. This folder is generated automatically after running `npm install`.

### Firebase Admin SDK JSON file
The Firebase service account key used by the scripts to access Firestore and Firebase Storage.

## Notes

These scripts should be run manually from the terminal during data preparation. They require a valid Firebase Admin SDK key and a Gemini API key stored in the `.env` file.
