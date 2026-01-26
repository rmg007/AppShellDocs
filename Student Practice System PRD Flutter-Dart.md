# Student Practice System PRD (Flutter/Dart)

### TL;DR

We are building a dynamic student practice system supporting any academic curriculum (math, science, English, etc.) and year (e.g., 7th grade). Two core products: a no-typing Student App (Flutter, mobile-first: Android/iOS/tablet/phone), and a web-first Admin Panel for authoring and publishing curriculum. Content and progress are fully offline-cached with seamless sync to Supabase. Students sign in with Gmail and can switch devices at any time. Curriculum is text-only and English-only for launch. Admins can update curriculum daily (initially), with instant in-app updates—no redeployment required.

---

## Goals

### Business Goals

* Launch a highly adaptable practice solution for K-12 curricula by Q2.

* Achieve daily curriculum update velocity by enabling one-click dynamic publishes.

* Ensure operational costs remain below $0.30 per monthly active user.

* Attain ≥98% content sync success rate between devices within a session.

* Achieve app store rating of 4.5+ within the first three months.

### User Goals

* Allow students to practice curriculum-relevant questions offline, anywhere.

* Provide frictionless, one-tap Gmail sign-in with seamless device switching.

* Enable students to track progress across domains, grades, and sessions.

* Give admins instant feedback via analytics and allow rapid curriculum adjustments.

* Reflect published curriculum updates in student apps immediately.

### Non-Goals

* No support for multimedia content (images, audio, video) at launch.

* No student-typed input: interactions are strictly multiple choice or similar.

* No multilingual support (English only for launch phase).

---

## User Stories

**Persona: Student**

* As a Student, I want to sign in with Gmail, so that I can access my progress from any device.

* As a Student, I want to select my subject and year, so that I can see questions relevant to my curriculum.

* As a Student, I want to practice questions without typing, so that I can use the app easily on any device.

* As a Student, I want to work offline, so that I can practice even without an internet connection.

* As a Student, I want to see explanations for correct/incorrect answers, so that I can learn from my mistakes.

**Persona: Admin**

* As an Admin, I want to log into a web dashboard, so that I can manage curriculum content.

* As an Admin, I want to enter, edit, and preview text-based question sets, so that students get the most up-to-date materials.

* As an Admin, I want to publish changes instantly with one click, so that updates propagate to students without delay.

* As an Admin, I want to view analytics of student progress, so that I can identify trends and areas for improvement.

---

## Functional Requirements

* **Curriculum Management (Priority: High)**

  * Curriculum Authoring: Admins can create, edit, and organize curriculum as text-based question sets by subject/year.

  * Dynamic Publishing: One-click publishing propagates updates instantly to all student devices.

  * Curriculum Versioning: Each update is versioned for smooth offline/online sync.

* **Question Player (Priority: High)**

  * No-Typing Question Display: All questions use multiple choice, true/false, or similar input.

  * Immediate Feedback: Show correct/incorrect with explanations immediately upon answering.

  * Progress Tracking: Mark and summarize completed questions for students.

* **Offline Caching & Sync (Priority: High)**

  * Device Caching: All curriculum and progress data are available offline.

  * Robust Background Sync: Data syncs via Supabase when the internet is available, handling conflicts and batching.

* **User Authentication (Priority: Medium)**

  * Gmail Sign-In: Single-tap sign-in.

  * Seamless Device Switching: Student progress and curriculum follow the user across devices.

* **Progress Tracking & Analytics (Priority: Medium)**

  * Student Progress Reports: Visual indicators for completion, accuracy, and improvement.

  * Admin Analytics Dashboard: Aggregated, anonymized performance and usage stats.

* **Admin Panel Web Flows (Priority: Medium)**

  * Curriculum Manager: List, filter, and organize question sets.

  * Batch Import/Export: Ability to import/export bulk questions.

  * Immediate Preview: Validate curriculum before publishing.

---

## User Experience

**Entry Point & First-Time User Experience**

* Student App opens with a welcoming splash, directly presenting "Sign in with Gmail."

* Upon sign-in, users choose their grade and subject before accessing content.

* Onboarding tooltip highlights offline functionality and how to switch devices if needed.

* Admin Panel accessed via web login; first-time admins shown quickstart tips for curriculum entry and publish workflow.

**Core Experience**

*Student Flow*

* **Step 1:** Open the app and sign in with Gmail.

  * One-tap with Google SSO; minimal friction.

  * If offline, login cache allows access to previously-used accounts/devices.

  * Error handling for failed logins with clear, actionable messages.

  * On success, proceed to domain/grade selection.

* **Step 2:** Select domain (Math, English, Science, etc.) and grade/year.

  * Simple, visual menus; accessible for mobile/tablet.

  * Progress for each domain/year shown as visual bar or chart.

* **Step 3:** Launch practice session—questions are loaded and cached textually.

  * Answer with tap/click—no typing at all.

  * Immediate feedback: Correct/incorrect + brief explanation.

  * Next button advances to the following question.

  * Ability to pause/exit and resume later.

* **Step 4:** See progress summary at session or topic completion.

  * Large, clear indicators of performance (e.g., % correct, streaks, areas for improvement).

* **Step 5:** App continues working offline; on network reconnect, syncs progress to Supabase, resolving conflicts as needed.

  * Users can switch to any other device and sign in—cached/unsynced progress merges automatically.

*Admin Flow*

* **Step 1:** Admin signs in to the web dashboard.

  * Simple login, password or SSO.

* **Step 2:** Access Curriculum Manager.

  * Browse/edit curriculum by subject/year; preview questions as students see them.

* **Step 3:** Enter and edit questions in plain English, using simple forms (question, answer choices, feedback).

* **Step 4:** Preview new/changed question sets in-situ.

* **Step 5:** Publish instantly—changes go live to all student apps with no user action required.

  * Old versions remain in cache for offline users until next sync.

**Advanced Features & Edge Cases**

* Admin batch upload for rapid curriculum iteration.

* Handling of curriculum updates during mid-session (students alerted to reload if questions have changed).

* Device conflict resolution for progress (last write wins, or merge by question).

* Graceful fallback when offline: queuing submissions, local error logs for failed sync.

* Duplicate submission guardrails for multi-device sync.

**UI/UX Highlights**

* Tap-target sizes conform to accessibility guidelines across mobile/tablet.

* High color contrast, simple sans-serif fonts, and large type for readability.

* Responsive layouts; fully usable on all screen sizes (phones, iPads, Chromebooks).

* All flows optimized for one-handed, thumb-driven mobile navigation.

* Animated feedback/rewards for correct answers and milestones—text-based only.

---

## Narrative

Fatima, a 7th-grade student, often struggles to find reliable practice materials when traveling between home and her grandmother’s house, where internet connectivity is spotty. She downloads the Student Practice App on her phone and signs in with her school Gmail. Instantly, she selects Math for 7th grade, and the app presents bite-sized questions, which she answers easily through taps. Even when the internet drops, Fatima’s practice continues uninterrupted, and when she visits her cousin later and borrows a tablet, her progress appears there too.

Meanwhile, Mr. Evans, a curriculum admin, receives district feedback that the science curriculum needs update to the latest standards. He logs into the Admin Panel from his browser, edits the question sets, and hits "Publish." The new materials reflect instantly in all connected students’ apps—even those mid-session get a courteous nudge about the update.

Fatima’s experience is seamless; she makes real progress and gets instant feedback, wherever she goes. For Mr. Evans, publishing improvements is real-time and requires no technical overhead. Ultimately, students learn effectively anywhere, admins operate with speed, and the education system adapts as quickly as the world demands.

---

## Success Metrics

* **User-Centric Metrics**

  * Daily/weekly active users (DAU/WAU) as % of total sign-ups.

  * Session completion rates per user (e.g., ≥80% sessions completed).

  * App store ratings (goal: 4.5+ average).

  * User-reported sync errors/incidents (goal: <1% of sessions).

* **Business Metrics**

  * Cost per MAU (goal: <$0.30).

  * Curriculum updates published per week/month.

  * Growth in active students per curriculum/subject.

* **Technical Metrics**

  * Sync success/failure rate (target: ≥98%).

  * Data loss or duplication incidents (target: zero).

  * Mean time to propagate published update (target: <5 seconds for online users).

  * Uptime and reliability of Supabase backend (>99.5%).

* **Tracking Plan**

  * User sign-in attempts/success.

  * Curriculum version loads on device.

  * Question answered/submitted.

  * Progress sync attempts/results.

  * Device switching events.

  * Curriculum publish events (admin).

---

## Technical Considerations

### Technical Needs

* **APIs & Data Model**: Curriculum and progress data structured as normalized JSON; RESTful endpoints for sync; web sockets for push updates (if feasible).

* **Front-End**: Flutter mobile app (Android/iOS/tablet) for students; React or similar for the web admin panel.

* **Back-End**: Supabase for user accounts, progress, content sync; separate content storage/“CDN” table for curriculum text.

### Integration Points

* Gmail (Google OAuth) for primary authentication.

* Supabase as the real-time and long-term storage and sync backend.

* Device local storage (e.g., SQLite or Flutter’s local DB) for full offline caching.

### Data Storage & Privacy

* All user progress stored locally first, then synced to Supabase via background batch writes.

* Row-level security: Students can only access their own progress; admins can only update curriculum, not individual student data.

* No personally identifying data outside email address (for sign-in).

* All data encrypted at rest and in transit per educational data compliance.

### Scalability & Performance

* Designed for hundreds of simultaneous students per subject.

* Curriculum fetches and syncs batched to minimize API load.

* Handles mid-session curriculum version changes gracefully (alerts or merges).

* Queue/batch unsynced writes for poor/inconsistent connections.

### Potential Challenges

* Handling curriculum changes during active student sessions (prompt or auto-reload).

* Duplicate progress submissions during device switching (resolved via idempotent writes or “last write wins”).

* Offline/online sync reliability and transactionality.

* Maintaining low operational cost with potentially volatile sync schedules.

---

## Milestones & Sequencing

### Project Estimate

* Large: 8 weeks for MVP launch with both student app and admin panel.

### Team Size & Composition

* Small Team: 1–2 people (engineer/product owner + (part-time) QA/UX tester).

### Suggested Phases

**1. Prototype & Architecture (2 weeks)**

* Key Deliverables: Single engineer–define data schema, set up Supabase; build minimal question-playing prototype; Gmail sign-in stub; initial admin web entry point.

* Dependencies: Gmail OAuth config, Supabase setup.

**2. Core App Development (4 weeks)**

* Key Deliverables: Student App: offline-first practice and sync, question player, feedback, device switching. Admin Panel: basic curriculum entry, edit, preview, publish.

* Dependencies: Offline DB workflow, finalized content JSON, sync logic.

**3. Sync/Polish & Launch (2 weeks)**

* Key Deliverables: Robust offline batching, dynamic curriculum update workflow, full QA, edge-case user flows (mid-session updates, merge conflicts, etc.). Store submission; production GoLive.

* Dependencies: App Store/Play Store developer accounts, final content.

**Definition of Done**:

* All flows function fully offline (practice, sync on reconnect).

* Admin dynamic curriculum updates are visible in student apps within 5 seconds if online, instantly after reconnect if offline.

* No student-typed input, text-only questions/explanations, English only for all user-facing content.

* All personal data secure, privacy compliant.

* <1% sync failure rate in simulated poor network conditions.