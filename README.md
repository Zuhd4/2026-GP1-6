# Lexia – Dyslexia Support Learning Application

# Introduction

Lexia is an Android mobile learning application designed to support children with dyslexia in improving their reading and spelling skills through interactive and child-friendly learning activities.

The application includes two main interfaces: a child interface and a parent interface. The child interface allows children to practice through educational games, reading activities, text-to-speech support, speech recognition, and level-based progression. The parent interface allows parents to create and manage child profiles, monitor the child’s progress, scan learning materials using OCR, and analyze word difficulty.

Lexia assists children by:

* Providing educational games such as Letter Scramble, Word Matching, and Listen & Spell.

* Supporting reading activities with speech recognition and feedback.

* Using a word difficulty scoring system to classify words based on linguistic rules.

* Highlighting difficult words to support children while reading.

* Allowing parents to track learning progress through a dedicated parent dashboard.

Unlike traditional learning applications, Lexia combines dyslexia-friendly design, interactive learning activities, OCR text capture, and a custom word difficulty scoring system to create a supportive reading and spelling environment.

# Technologies Used

Lexia uses a combination of mobile, cloud, backend, and data processing tools:

**Mobile Application**

* Flutter — Used to develop the Android mobile application.

* Dart — Used as the main programming language for the Flutter application.

* Android Emulator — Used to run and test the application on a virtual Android device.

**Firebase Services**

* Firebase Authentication — Used for parent account registration and login.

* Cloud Firestore — Used to store parent accounts, child profiles, vocabulary data, and learning progress.

**Backend and Data Processing**

* Python — Used to process the vocabulary corpus and apply the word difficulty scoring rules.

* Flask — Used to build the word analyzer backend.

* Node.js — Used for Firebase Admin SDK scripts and generative AI processing workflows.

* Google Colab — Used during dataset preparation and corpus processing.

**Generative AI**

* Google Generative AI / Gemini API — Used for text validation and image validation during the educational content preparation process.

**Development and Version Control Tools**

* Visual Studio Code — Used as the main development environment.

* GitHub — Used for version control, collaboration, and storing the project repository.

# Launching Instructions

## 1. Clone the Repository

```bash
git clone <repository-url>
cd lexia
```

## 2. Mobile Application Setup
Install the Flutter dependencies:

```bash
flutter pub get
```
Run the application on an Android emulator or connected Android device:
```bash
flutter run
```
Make sure Flutter SDK, Android Studio, and Android Emulator are installed and configured before running the application.

## 3. Flask Backend Setup

The project includes a Flask backend used for the word difficulty analyzer.

Install the required Python packages:
```bash
pip install -r requirements.txt
```

Run the Flask backend:
```bash
python app.py
```
## 4. Node.js Scripts Setup

Some data processing and generative AI workflows are handled using Node.js scripts, such as Firebase upload scripts, text validation, image generation, and image validation.

Navigate to the folder that contains the required script:
```bash
cd <script-folder-name>
```
Install dependencies:
```bash
npm install
```
Run the selected script:
```bash
node <script-name>.js
```

## 5. Required Local Files

The following files may be required locally but should not be uploaded to GitHub for security reasons:
```bash
.env
serviceAccountKey.json
Firebase API keys
Gemini API key
Firebase configuration files
```

--- 

# Student Names: 

* Norah Alshamsan, 444200817
* Dana Alsalami, 443200945
* Zuhd Ibrahim, 444201206
* Layan Alhowaimel, 444200969
