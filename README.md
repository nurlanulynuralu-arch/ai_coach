# AI Study Coach

AI Study Coach is a Firebase-powered Flutter mobile MVP for exam preparation. Students can register, verify email, create an exam, generate a structured study plan, complete daily tasks, practice quizzes, review flashcards, track progress, and manage their profile in one connected flow.

## Project Overview

This project was built as a real startup-style academic MVP, not a UI-only demo.

Core problem solved:

- Poor planning -> exam setup generates a structured study plan.
- Lack of structure -> tasks are grouped by day and tracked in Firestore.
- Forgetting information -> flashcards and quizzes support active recall.
- Low motivation -> progress, streaks, and readiness metrics make momentum visible.

## Features

- Firebase Authentication with email/password sign up, sign in, sign out, and session persistence
- Firebase email verification flow on registration
- Firestore-backed user profiles in `users`
- Firestore CRUD for exams, study tasks, flashcards, and quiz attempts
- Dashboard with active exam summary, daily tasks, and quick actions
- Exam setup with date, difficulty, target score, notes, and topic management
- Study plan generation based on exam date and topics
- Task completion tracking with live progress updates
- Quiz attempts saved to Firestore
- Flashcard CRUD with mastery updates
- Progress dashboard with topic mastery, streak, quiz results, and weekly minutes
- Settings screen with verification refresh and app info
- Custom branded Android app icon

## Internet Knowledge Enrichment

Quizzes and flashcards are not limited to static local placeholders.

The app includes `TopicKnowledgeService`, which:

1. Searches Wikipedia for topic matches.
2. Fetches page summaries from the public Wikipedia REST endpoint.
3. Saves enriched topic summaries into the exam topic data.
4. Uses those summaries to generate richer flashcards and quiz questions.
5. Falls back to safe local content if network lookup fails.

This keeps the app stable offline while improving content quality when internet knowledge is available.

## Tech Stack

- Flutter
- Dart
- Provider
- GoRouter
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Material 3
- Google Fonts

## Folder Structure

```text
lib/
  core/
    constants/
  data/
    repositories/
  models/
  providers/
  routes/
  screens/
    auth/
    exam_setup/
    flashcards/
    home/
    onboarding/
    premium/
    profile/
    progress/
    quiz/
    settings/
    splash/
    study_plan/
  services/
  theme/
  widgets/
android/
assets/
firestore.rules
firestore.indexes.json
```

## Firestore Collections

- `users`
  - `uid`
  - `fullName`
  - `email`
  - `avatarUrl`
  - `avatarPlaceholder`
  - `createdAt`
  - `emailVerified`
  - `onboardingData`

- `exams`
  - `userId`
  - `title`
  - `subject`
  - `examDate`
  - `targetScore`
  - `difficulty`
  - `topics`
  - `notes`
  - `createdAt`
  - `updatedAt`

- `study_tasks`
  - `userId`
  - `examId`
  - `topicId`
  - `topicTitle`
  - `title`
  - `description`
  - `taskType`
  - `scheduledFor`
  - `estimatedMinutes`
  - `isCompleted`
  - `completedAt`

- `flashcards`
  - `userId`
  - `examId`
  - `topicId`
  - `topicTitle`
  - `front`
  - `back`
  - `masteryLevel`

- `quiz_attempts`
  - `userId`
  - `examId`
  - `scorePercent`
  - `correctAnswers`
  - `totalQuestions`
  - `weakTopics`
  - `attemptedAt`

## Firebase Setup

1. Create a Firebase project.
2. Enable Authentication -> Email/Password.
3. Create a Firestore database in production or test mode.
4. Run:

```bash
flutterfire configure
```

5. Replace the placeholder values in `lib/firebase_options.dart` if needed.
6. Deploy rules and indexes:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

7. Confirm the Android package is registered in Firebase before making a final release build.

## How to Run

```bash
flutter pub get
flutter run
```

## Build APK

Debug:

```bash
flutter build apk
```

Release:

```bash
flutter build apk --release
```

Latest verified local release output:

`build/app/outputs/flutter-apk/app-release.apk`

## Firebase Email Flow

On registration, the app triggers Firebase Auth email verification with:

- `sendEmailVerification()`

The UI also allows resending verification from Profile and Settings.

If you want a custom welcome email in addition to verification, add a Firebase Cloud Function or Firebase Extension later. The current MVP already satisfies the built-in Firebase email verification requirement.

## Quality Notes

- Real Firestore is the source of truth for the main study data
- Empty, loading, and error states are included
- Navigation is connected end-to-end with no dead buttons in the main flow
- Study tasks, flashcards, quizzes, progress, and profile actions are connected to live providers
- Release APK build was verified locally

## Screenshots

Add screenshots here before GitHub submission:

- `screenshots/onboarding.png`
- `screenshots/dashboard.png`
- `screenshots/exam-setup.png`
- `screenshots/study-plan.png`
- `screenshots/quiz.png`
- `screenshots/flashcards.png`
- `screenshots/progress.png`
- `screenshots/profile.png`

## Future Improvements

- Replace Wikipedia enrichment with a dedicated AI or education content pipeline
- Add avatar upload with Firebase Storage
- Add push notifications for daily reminders
- Add spaced repetition scheduling logic
- Add premium billing with RevenueCat or Play Billing
- Add teacher or tutor shared workspaces

## Useful Files

- `lib/main.dart`
- `lib/routes/app_router.dart`
- `lib/providers/auth_provider.dart`
- `lib/providers/study_plan_provider.dart`
- `lib/services/topic_knowledge_service.dart`
- `lib/services/study_plan_generator.dart`
- `firestore.rules`
- `firestore.indexes.json`
