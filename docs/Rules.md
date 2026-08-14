# MY Algeria BAC — Rules (Backbone)

> Source: product-owner backbone document (first prompt). This file is the
> canonical ruleset for the project. Rules here take priority over convenience.

## 1. ABSOLUTE ANTI-HALLUCINATION RULES

These rules have priority over convenience.

### Rule 1 — NEVER invent project requirements

If something is not explicitly specified in this document, existing project
files, uploaded educational sources, or an authoritative external source, DO
NOT silently invent a business rule. Use:

```
UNKNOWN — REQUIRES DECISION
```

instead. Do not convert assumptions into code.

### Rule 2 — NEVER invent educational facts

For educational content, never fabricate:

- BAC questions
- answers
- corrections
- coefficient values
- grading rules
- Algerian curriculum requirements
- official terminology
- exam dates
- subject programmes
- teacher claims
- ministry rules
- historical exam metadata
- solution explanations

Educational content must come from a trusted source. Every educational content
item must have provenance metadata.

Example:

```
sourceType = OFFICIAL_DOCUMENT
sourceName = ...
sourceYear = ...
sourceUrl = ...
sourcePage = ...
verified = true/false
```

If the source is unavailable:

```
CONTENT_REQUIRES_VERIFICATION
```

Do NOT guess.

### Rule 3 — NEVER invent APIs or libraries

Before using a library, API, SDK, Gradle plugin, Android API, Firebase API,
Google Play Billing API, AdMob API, YouTube API, or third-party service:

1. Check its current official documentation.
2. Verify the API actually exists.
3. Verify the version is compatible with the project.
4. Verify the package/import name.
5. Verify the method signature.
6. Only then write code.

If current documentation cannot be verified:

```
DEPENDENCY_REQUIRES_VERIFICATION
```

Do not fabricate an API.

### Rule 4 — NEVER use deprecated technology unless explicitly justified

Prefer current stable Android technologies. Primary stack should be:

- Kotlin
- Jetpack Compose
- Material 3
- AndroidX
- Navigation Compose
- ViewModel
- Kotlin Coroutines
- Flow
- Room for persistent local data
- DataStore for lightweight preferences
- Hilt or another officially supported dependency-injection solution
- WorkManager for appropriate background work

However: DO NOT blindly assume the latest version numbers. Version selection
must be verified against current official documentation at implementation time.

### Rule 5 — Do not over-engineer the first milestone

Do not create: microservices, unnecessary abstractions, unnecessary design
patterns, dozens of modules, complex cloud infrastructure, premature AI
systems, unnecessary networking, unnecessary accounts — unless the current
milestone actually requires them. Prefer a small, maintainable architecture
that can evolve.

### Rule 6 — Never hide uncertainty

When uncertain, write:

```
UNCERTAIN:
Reason:
What must be verified:
Recommended safe default:
```

Never cover uncertainty with plausible-looking code.

### Rule 7 — Compile after structural changes

After every meaningful implementation step:

1. Build.
2. Check compilation errors.
3. Fix only relevant errors.
4. Run tests where applicable.
5. Do not continue piling features onto broken code.

Never claim something works without verification.

## 2. PRODUCT VISION

MY Algeria BAC is an Algerian BAC-learning ecosystem. The learner should
experience:

```
OPEN APP
↓
SEE TODAY'S MISSION
↓
COMPLETE SHORT LESSON
↓
ANSWER QUIZ
↓
GET XP
↓
MAINTAIN STREAK
↓
REVIEW WEAK AREAS
↓
UNLOCK NEXT LEARNING NODE
↓
IMPROVE BAC READINESS
```

The emotional objective is:

> "I know exactly what I should study today."

Not:

> "Here is a huge PDF library. Good luck."

## 3. PRIMARY USER

Main user: Algerian BAC student preparing for the Baccalauréat. Potential users
include: first-time BAC candidates, repeat candidates, students seeking higher
grades, students weak in particular subjects, students who procrastinate,
students who need structured revision, students preparing independently, and
students using private-school/coaching resources. Do not assume every user has
the same level.

## 4. CORE PRODUCT PRINCIPLE

The application must distinguish between:

**SOURCE CONTENT** — Human-provided, verified educational material. Examples:
official BAC exams, official solutions, approved educational documents,
teacher-created lessons, curated explanations, verified educational videos,
verified study methodology.

**GENERATED CONTENT** — Content generated from source material. Examples:
quizzes, flashcards, practice questions, summaries, revision prompts,
difficulty variants.

Generated content is NEVER automatically considered authoritative. It must
retain: `generatedFromContentId`, `generationMethod`, `validationStatus`,
`validatedBy`, `validationDate`.

## 5. CONTENT TRUST MODEL

Every educational object should have a trust status:

```
UNVERIFIED
SOURCE_IMPORTED
SOURCE_VERIFIED
TEACHER_REVIEWED
PUBLISHED
DEPRECATED
```

Only appropriate statuses may be exposed to users. Never silently publish
unverified generated educational content.

## 6. CURRICULUM STRUCTURE

Use a hierarchy:

```
BAC STREAM
    ↓
SUBJECT
    ↓
UNIT
    ↓
LESSON
    ↓
CONCEPT
    ↓
PRACTICE
    ↓
QUIZ
    ↓
EXAM
```

Example:

```
Mathematics
  └── Functions
       └── Derivatives
            └── Derivative rules
                 ├── Lesson
                 ├── Flashcards
                 ├── Quiz
                 ├── Exercises
                 └── BAC past-paper questions
```

Do not hardcode curriculum claims until verified against the content supplied
by the product owner.

## 7. SUBJECT SUPPORT

The system must be designed so subjects can be added without rewriting the
application. Example subjects may include: Mathematics, Physics, Natural
Sciences, Arabic, French, English, Philosophy, History, Geography, Islamic
Education, other BAC-relevant subjects. The actual supported streams,
coefficients, curricula and programme structure must come from verified project
content. Never hardcode assumptions.

## 8. LEARNING PATH

The main screen should behave like a learning map rather than a document
browser. Example:

```
LEVEL 1  ● Basics
LEVEL 2  ● Core Concepts
LEVEL 3  ● Guided Practice
LEVEL 4  ● Exam Skills
LEVEL 5  ● Advanced Problems
LEVEL 6  ● BAC Simulation
```

Nodes may be: lesson, quiz, challenge, review, exam, mastery check. The user
should always have a clear next action.

## 9. GAMIFICATION

- **XP** — Earn XP from learning activities (lesson completed, quiz completed,
  correct answer, revision session, exam practice, daily mission). Do not make
  XP equivalent to real money.
- **LEVELS** — e.g., Novice, Apprentice, Scholar, Expert, BAC Fighter, BAC
  Master. Names are product/UI decisions and should remain configurable.
- **STREAK** — Track `currentStreak`, `longestStreak`, `lastStudyDate`,
  `streakProtection`. Streaks should encourage studying without creating
  abusive pressure.
- **DAILY MISSION** — e.g., Complete 2 lessons, Answer 15 questions, Review 10
  weak concepts, Complete one BAC exercise, Study for 20 minutes. Daily
  objectives should adapt to progress.
- **MASTERY** — Every concept may have `NOT_STARTED`, `LEARNING`,
  `PRACTICING`, `MASTERED`, `NEEDS_REVIEW`. Mastery should be based on
  performance data, not merely lesson completion.

## 10. QUIZ ENGINE

Create a reusable quiz engine. Question types should be extensible. Potential
types: multiple choice, true/false, numerical answer, matching, ordering,
fill-in-the-blank, multi-select, short structured answer, exam-style problem.

Each question needs: `id`, `subjectId`, `lessonId`, `conceptId`,
`questionType`, `prompt`, `choices`, `correctAnswer`, `explanation`,
`difficulty`, `sourceReference`, `validationStatus`.

Never generate a question without a known content source or clearly-marked
generated status.

## 11. WRONG-ANSWER SYSTEM

Wrong answers are valuable learning data. Track: `questionId`, `userAnswer`,
`correctAnswer`, `attemptCount`, `timestamp`, `conceptId`. The app should
create a "My Weak Points" section. The learner then receives targeted revision.

## 12. SPACED REVIEW

Implement a review scheduler. The exact algorithm must be encapsulated so it
can change later. Example states: `NEW`, `AGAIN`, `HARD`, `GOOD`, `MASTERED`.
Never pretend a simple timer is scientifically equivalent to a validated
spaced-repetition algorithm. If an algorithm is described as evidence-based,
verify the claim before documenting it as such.

## 13. BAC EXAM LIBRARY

The application should contain a structured BAC archive. Possible metadata:
`year`, `session`, `stream`, `subject`, `exercise`, `chapter`, `difficulty`,
`officialSolutionAvailable`, `sourceDocument`.

Features: browse by year, browse by subject, browse by chapter, search,
filter, save, practice, timed mode, solution reveal, error review.

Never fabricate an exam year or exam question.

## 14. EXAM MODE

Exam mode should include: timer, sections, question navigation, answer
persistence, mark for review, submit, score, performance breakdown, mistakes,
recommended lessons. Do not claim the score is an official BAC prediction
unless an actual validated scoring model has been established. Call it
"Practice Result" until a validated prediction model exists.

## 15. "HOW TO STUDY" ACADEMY

Create a separate methodology section. Possible topics: How to revise, how to
learn a lesson, how to make homework useful, how to review mistakes, how to
memorize effectively, how to prepare for an exam, how to avoid procrastination,
how to build a study routine, how to use past BAC papers, how to convert
homework into revision, how to detect weak concepts, how to review before an
exam. Do not present unsupported psychological claims as scientific facts. For
strong claims, attach sources.

## 16. TEACHER VIDEO HUB

The app may curate educational YouTube videos. Do NOT download/rehost
copyrighted YouTube videos unless the necessary rights exist. Prefer linking to
legitimate YouTube content or using supported embedding/API mechanisms where
appropriate. Each video entry should contain: `title`, `creator`,
`youtubeVideoId`, `subject`, `lesson`, `language`, `description`, `sourceUrl`,
`verifiedAt`, `status`. Broken or unavailable videos must fail gracefully.
Never invent a YouTube ID.

## 17. LANGUAGE STRATEGY

Primary UI languages: Arabic, French, English. Potentially support Algerian
Arabic / Darija for marketing-oriented microcopy, but educational terminology
must remain consistent. The app architecture must support localization from
day one. Do not scatter user-visible strings throughout code. Use Android
string resources / proper localization architecture.

## 18. LOCALIZATION

Never hardcode "Start", "Continue", "Your score" directly inside composables.
Use localized resources. Support: RTL, Arabic typography, French, English,
dynamic text sizing, accessibility. Arabic layout must be tested independently.

## 19. HOME SCREEN

The home screen should answer: WHAT SHOULD I DO NOW? Suggested structure:
Greeting, current streak, XP / Level, today's mission, continue learning, weak
points, quick practice, recent results, BAC countdown/status, recommended
lesson. Do not overcrowd the screen.

## 20. APP NAVIGATION

Initial navigation: Home, Learn, Practice, BAC Exams, Progress, Profile.
Potential later sections: Study Academy, Video Hub, Challenges, Leaderboard,
Premium, Schools. Do not add navigation destinations merely because they sound
impressive. Every screen must justify its user value.

## 21. OFFLINE-FIRST DESIGN

Educational consumption should work with limited connectivity. Offline-capable:
lessons, downloaded content, quizzes, progress, saved questions, study history,
streak, local settings. Network-dependent: advertisements, cloud
synchronization, remote content updates, external YouTube content, purchases,
analytics. Never make the entire app unusable just because the network is
unavailable.

## 22. DATA ARCHITECTURE

Separate: UI → ViewModel → Use Case / Domain Logic → Repository → Local Data /
Remote Data. Do not put database, network, billing or ad logic directly into
Compose UI.

## 23. LOCAL DATABASE

Use a structured local database. Core entities may include: UserProfile,
Subject, Unit, Lesson, Concept, Question, Quiz, Exam, ExamQuestion,
UserProgress, QuestionAttempt, Mastery, StudySession, DailyMission,
Achievement, SavedItem, VideoResource, PurchaseState, AdReward. Avoid storing
arbitrary JSON everywhere when relational data is more appropriate. Use JSON
only where it provides a real advantage.

## 24. REMOTE CONTENT ARCHITECTURE

The architecture should eventually allow:

```
APP
 ↓
CONTENT MANIFEST
 ↓
CONTENT PACKS
 ↓
LOCAL DATABASE
```

This allows educational content to be updated independently of app releases.
However, do not build a complete CMS unless it is actually required by the
current milestone. For the MVP, local bundled content can be acceptable.

## 25. CONTENT FORMAT

Educational content should be importable in a structured format. Example
conceptual structure:

```json
{
  "id": "math_functions_derivative_001",
  "subject": "mathematics",
  "title": "...",
  "language": "fr",
  "source": {
    "type": "official_document",
    "name": "...",
    "year": "...",
    "verified": true
  },
  "sections": [
    {
      "type": "explanation",
      "content": "..."
    }
  ]
}
```

Do not copy this blindly into production if a stronger schema is appropriate.

## 26. CONTENT VALIDATION PIPELINE

Before publishing educational content:

```
IMPORT
↓
PARSE
↓
NORMALIZE
↓
SOURCE CHECK
↓
STRUCTURE CHECK
↓
ANSWER CHECK
↓
HUMAN REVIEW
↓
PUBLISH
```

Generated quiz questions must not bypass validation automatically.

## 27. MONETIZATION

Monetization should never destroy the learning experience. Core model:

```
FREE
+
REWARDED ADS
+
PREMIUM
+
SPONSORSHIP
```

## 28. REWARDED ADS — CRITICAL POLICY RULE

Do NOT reward users with: cash, DZD, bank transfers, gift cards, withdrawable
money, crypto, real-world payment equivalents. Rewarded advertisements can
instead provide non-transferable in-app rewards such as: XP boost, extra hint,
temporary premium feature, bonus practice, streak protection, review token,
temporary ad-free session. The reward must be clearly explained before the
user opts in. The user must explicitly choose to watch the rewarded ad. Never
create deceptive "watch ad to earn money" mechanics. Google's rewarded-ad
policy explicitly prohibits direct monetary rewards.

## 29. PREMIUM

Possible premium benefits: remove ads, advanced statistics, premium courses,
advanced exam simulations, premium explanations, additional practice packs,
offline premium content, advanced review tools, special challenge modes.
Avoid making the entire educational experience paywalled. The free experience
must be genuinely useful.

## 30. PAID UNLOCKS

Digital content/features sold through the Google Play-distributed app must be
designed around Google Play Billing unless a verified policy exception applies.
Possible one-time products: premium unlock, subject pack, advanced BAC pack,
ad-free upgrade. Possible subscription: Premium Monthly, Premium Yearly. Do
not hardcode prices. Read product information from the billing system. Never
treat client-side UI state as proof of payment.

## 31. PURCHASE SECURITY

Purchase flow:

```
USER PURCHASE
↓
GOOGLE PLAY BILLING
↓
PURCHASE RESULT
↓
VERIFY / ACKNOWLEDGE CORRECTLY
↓
ENTITLEMENT STATE
↓
PERSIST
↓
RESTORE ON NEXT APP START
```

Use the official current Play Billing documentation. Never invent billing APIs.
Do not give permanent premium access merely because the user clicked a button.

## 32. PRIVATE-SCHOOL / SPONSOR ADVERTISING

Potential Algerian advertisers: private schools, language institutes, tutoring
centres, study academies, university preparation services, stationery shops,
bookstores, computer stores, educational technology services, student
transport services, scholarship-related services, exam-preparation programmes.

Advertising must be architecturally separate from educational recommendations.
A sponsor must never be silently presented as an authoritative educational
source. Example:

```
SPONSORED
Centre XYZ
BAC preparation programme
```

not:

```
Recommended by MY Algeria BAC:
Centre XYZ
```

unless that claim is genuinely justified.

## 33. AD SYSTEM

Create an abstraction:

```
AdProvider
```

Possible implementations: AdMobProvider, DirectSponsorProvider, NoAdsProvider.
The UI must not know which provider is being used. This allows future
monetization changes without rewriting the application.

## 34. AD FREQUENCY

Never place ads everywhere. Prefer: natural pauses, between sessions, optional
rewarded ads, clearly marked sponsor placements. Avoid interrupting: active
exam answering, concentration-heavy exercises, lesson explanations, important
correction screens. The learning experience has priority.

## 35. MINORS / AGE / PRIVACY

BAC learners can include minors. Do not assume all users are adults. Build the
architecture so that age/audience treatment can be configured and privacy
requirements can be applied appropriately. Do not collect unnecessary personal
data. Do not collect: contacts, SMS, precise location, microphone, camera,
unrelated device information — unless there is a documented product
requirement.

## 36. ANALYTICS

Analytics should answer product questions, not spy on students. Useful
anonymous/product metrics: `lesson_started`, `lesson_completed`, `quiz_started`,
`quiz_completed`, `question_answered`, `question_wrong`, `exam_started`,
`exam_completed`, `premium_screen_viewed`, `purchase_started`,
`purchase_completed`, `rewarded_ad_opt_in`, `rewarded_ad_completed`. Avoid
collecting educationally unnecessary personal information.

## 37. DASHBOARD

Progress dashboard should show: total study time, lessons completed, questions
answered, accuracy, strong subjects, weak subjects, current streak, longest
streak, mastery percentage, BAC practice performance.

Do not produce fake precision. Example — bad:

```
You have a 93.7% probability of passing BAC.
```

unless a validated predictive model actually exists. Better:

```
Practice readiness: Strong
```

with an explanation based on observable metrics.

## 38. NOTIFICATION SYSTEM

Useful notifications: "Your daily mission is ready.", "Your Mathematics review
is due.", "You have a 5-day streak.", "You have 8 weak concepts waiting for
review." Avoid manipulative notifications. Allow the user to disable
categories.

## 39. SEARCH

Global search should support: lesson, subject, concept, BAC exam, question,
teacher/video. Search must never require network access for local content.

## 40. DESIGN LANGUAGE

Visual direction: "Modern Algerian education + game progression".
Characteristics: clean, youthful, premium, energetic, highly readable, subtle
motion, strong hierarchy, rounded cards, meaningful progress indicators,
polished empty states, excellent Arabic RTL support. Do not blindly imitate
Duolingo's visual identity or proprietary assets. Take inspiration from the
psychological concept of progression, not the branding.

## 41. HOOKS / RETENTION MECHANICS

Potential hooks: Today's Mission, 7-Day Challenge, BAC Boss Fight, Weak Point
Hunter, Exam Sprint, Study Streak, Subject Mastery, Daily Duel, Speed Quiz,
Perfect Lesson, Revision Rescue, Last-Minute Mode, BAC Marathon. Do not
implement all of these. Use experiments and prioritize the mechanics that
actually improve learning.

## 42. FEATURE PRIORITY

- **PHASE 1 — FOUNDATION**: Project setup, theme, navigation, Home, Subjects,
  Lessons, quiz engine, Progress, local database, basic gamification.
- **PHASE 2 — BAC ENGINE**: BAC exam archive, exam mode, solutions, weak
  points, review system, study academy.
- **PHASE 3 — MONETIZATION**: AdMob, rewarded ads, premium, Play Billing,
  entitlements, ad-free mode.
- **PHASE 4 — CONTENT ECOSYSTEM**: Video hub, remote content, teacher content,
  sponsor system.
- **PHASE 5 — ADVANCED**: adaptive learning, advanced analytics, leaderboards,
  challenges, AI-assisted tutoring, teacher dashboard, parent dashboard,
  institution partnerships.

Do not jump directly to Phase 5.

## 43. AI FEATURES — FUTURE, NOT FOUNDATION

An AI tutor may eventually be included. AI must NOT automatically become the
authoritative source for: BAC answers, official curriculum, grading rules,
exam regulations. AI-generated explanations should cite the underlying trusted
lesson/source where possible. A future AI assistant should use retrieval from
verified MY Algeria BAC content rather than unconstrained generation.

## 44. SOURCE HIERARCHY

When sources conflict:

1. Official Algerian educational authority / official exam documentation.
2. The verified documents explicitly provided by the product owner.
3. Verified teacher-authored material.
4. Reputable educational sources.
5. General web sources.
6. Model knowledge.

Model knowledge must NOT override verified project data.

## 45. CONFLICT RULE

If two sources conflict: DO NOT choose silently. Create:

```
CONTENT_CONFLICT
```

with: `sourceA`, `sourceB`, `conflictingClaims`, `recommendedReview`. The
product owner decides.

## 46. CODE QUALITY RULES

Every implementation should favor: readable code, small functions, explicit
state, predictable data flow, testable business logic, no hidden global state,
no unnecessary singleton abuse, no duplicated business rules, clear naming,
robust error handling. Do not optimize prematurely.

## 47. ERROR STATES

Every network-dependent feature must define: Loading, Success, Empty, Error,
Offline, Retry. Every purchase flow must define: Loading, Success, Cancelled,
Pending, Failed, AlreadyOwned, Unavailable. Never leave screens in indefinite
loading states.

## 48. ACCESSIBILITY

Support: scalable text, semantic labels, sufficient contrast, touch targets,
screen readers where practical, RTL correctness, reduced-motion
considerations. Accessibility is part of the architecture, not a final patch.

## 49. SECURITY

Never put secrets in: source code, Git, APK resources, BuildConfig, public
repositories. Never trust the client for: premium entitlement, server-side
rewards, sensitive account information. Do not store unnecessary sensitive
data.

## 50. TESTING STRATEGY

At minimum — **Unit tests** for: XP calculation, streak calculation, mastery
calculation, quiz scoring, exam scoring, review scheduling, entitlement logic.
**UI tests** for critical flows: Launch, Lesson, Quiz, Exam, Premium, Purchase
restore. **Manual testing**: Arabic, French, English, RTL, offline, slow
network, no network, fresh install, upgrade, restore purchase, screen
rotation/configuration changes, process death.

## 51. DEVELOPMENT RULE

Implement in vertical slices. Do NOT create 100 unfinished files. Example —
Lesson feature: UI, ViewModel, Domain logic, Repository, Database, Tests.
Finish the slice before adding unrelated features.

## 52. GIT / CHANGE DISCIPLINE

Every meaningful feature should be independently understandable. Do not rewrite
unrelated files. Do not perform giant speculative refactors. When changing
architecture, explain: WHY, WHAT, RISK, FILES AFFECTED.

## 53. BEFORE WRITING CODE

Always inspect: project structure, Gradle configuration, Android manifest,
existing dependencies, existing navigation, existing database, existing
themes, existing tests. Never assume the project starts empty.

## 54. WHEN RECEIVING A TASK

For every task, first classify it: FEATURE, BUG, REFACTOR, CONTENT,
ARCHITECTURE, UI, MONETIZATION, POLICY. Then identify: KNOWN, UNKNOWN,
DEPENDENCIES, RISKS. Only then implement.

## 55. DO NOT ASK UNNECESSARY QUESTIONS

If implementation can safely proceed using a clearly documented default,
proceed. If the missing decision affects: money, legal compliance, educational
correctness, data privacy, architecture that is expensive to reverse,
destructive changes — do not guess. Mark the decision as requiring
clarification.

## 56. DECISION LOG

Maintain a project decision log. Example:

```
DECISION:
Use Room for local educational persistence.

REASON:
Offline-first learning requires persistent local data.

STATUS:
Accepted

SOURCE:
Architecture requirement
```

Another example:

```
DECISION:
Rewarded ads give XP/hints rather than money.

REASON:
Direct monetary rewards from Google-served rewarded ads are prohibited.

SOURCE:
Google AdMob policy

STATUS:
Accepted
```

## 57. DEFINITION OF DONE

A feature is NOT done merely because code exists. It is done when:

- [ ] Requirements understood
- [ ] Unknowns identified
- [ ] Appropriate architecture selected
- [ ] Code implemented
- [ ] Compilation succeeds
- [ ] Relevant tests pass
- [ ] Error states handled
- [ ] Offline behaviour considered
- [ ] Localization considered
- [ ] Accessibility considered
- [ ] Security considered
- [ ] Monetization/policy considered if relevant
- [ ] No invented APIs
- [ ] No fabricated educational content
- [ ] No unrelated regressions

## 58. AI RESPONSE FORMAT FOR CODING TASKS

When implementing a task, respond with: TASK, ASSUMPTIONS, FILES TO CHANGE,
IMPLEMENTATION, VALIDATION, RISKS / UNKNOWN. Never say "everything works"
unless it has actually been tested.

## 59. CRITICAL ANTI-HALLUCINATION TEST

Before every implementation, silently ask: Am I inventing — an API? a library?
a requirement? an educational fact? a price? a legal rule? a curriculum rule? a
dependency version? a database field? a business rule? If YES: STOP. Find a
source or mark it UNKNOWN.

## 60. PRODUCT NORTH STAR

The app succeeds when a BAC student opens it and immediately understands:
Where am I? What am I weak at? What should I study now? Why should I study it?
What should I do next? Am I improving? The app should make consistent study
feel easier than procrastination.

## 61. FIRST IMPLEMENTATION MILESTONE

Do NOT begin by implementing advertisements, premium, AI tutoring,
leaderboards, schools, or every proposed feature. First create the technical
foundation:

1. Android project
2. Kotlin
3. Jetpack Compose
4. Material 3
5. Navigation
6. Theme system
7. Localization foundation
8. Basic app architecture
9. Room database
10. Subject model
11. Lesson model
12. Quiz model
13. UserProgress model
14. Home screen
15. Subject screen
16. Lesson screen
17. Quiz screen
18. Progress screen
19. XP system
20. Basic streak system
21. Unit tests

The first milestone should produce a clean, runnable vertical slice. Do not add
monetization until the educational core is stable.

## 62. FINAL INSTRUCTION

Your highest priority is:

> Correctness > explicitness > maintainability > speed.

- Never produce convincing fake code.
- Never invent educational truth.
- Never invent a current API.
- Never silently choose a high-impact business decision.
- When information is missing, expose the uncertainty.
- When documentation is current-sensitive, verify it.
- When content is educational, preserve provenance.
- When money is involved, preserve entitlement integrity.
- When ads are involved, preserve policy compliance.
- When the product is complex, implement the smallest correct increment first.

MY Algeria BAC must become a real product, not a collection of impressive-
looking demos.

---

## Why this backbone matters

Three especially important decisions are embedded in it:

1. **No "cash for watching ads."** Google's current AdMob rewarded-ad policy
   says direct monetary items such as cash, cryptocurrency, and gift cards
   cannot be offered as rewarded-ad rewards; non-transferable in-app rewards
   are the appropriate model.

2. **Premium needs a real entitlement architecture**, not
   `isPremium = true` in local preferences. Google Play Billing currently
   supports one-time products such as permanent premium upgrades and
   subscriptions, and Google Play generally requires Play Billing for digital
   content/features sold inside Play-distributed apps.

3. **Build for the August 2026 Android environment now.** Google says that
   beginning August 31, 2026, new apps and updates submitted to Google Play
   must target Android 16 / API 36+.

For the product itself, make the first version feel small but addictive:
`Today → Lesson → Quiz → XP → Weak Point → Review`. The massive BAC archive,
teacher videos, premium packs, school sponsorships, AI tutor, rankings, and
other features should plug into that backbone rather than becoming separate
disconnected systems.
