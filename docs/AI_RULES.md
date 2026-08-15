# MY Algeria BAC — AI Development Rules

> **Contract:** Before any coding work, read `docs/AI_DEVELOPMENT_RULES.md`.
> It is the non-negotiable development contract (inspect-first, no invented
> APIs/models, no silent architecture changes, XP/streak rules never in UI).

## 1. Project purpose

MY Algeria BAC is an Algerian secondary-school and BAC preparation
Android application.

The application is NOT a language-learning application.

It combines:

- structured curriculum learning
- BAC preparation
- short practice
- long-form BAC examinations
- exam simulations
- progress tracking
- mastery tracking
- weak-point detection
- revision planning
- teacher/resource discovery
- educational videos
- summaries
- worksheets
- solved exercises
- premium educational features

## 2. Never invent educational facts

Never invent:

- BAC exam questions
- official solutions
- curriculum requirements
- coefficients
- official grading rules
- teacher credentials
- publisher information
- copyright ownership
- URLs
- educational references

If information is not present in the project's verified content,
do not fabricate it.

Use TODO/UNKNOWN instead.

## 3. Content provenance

Every educational item must have provenance.

Examples:

- official_exam
- official_textbook
- teacher_verified
- editorial_content
- external_resource
- demo_content

Unverified content must never be presented as official.

## 4. External resources

Do not copy third-party copyrighted content into the project
unless the project has permission or an appropriate license.

External resources should normally be represented as metadata and
opened from their original source.

## 5. BAC exam integrity

Official exams must preserve their original:

- year
- subject
- stream
- exercise structure
- question structure
- scoring information
- source/reference

Never alter an official question while labeling it as official.

## 6. Learning architecture

The application must support:

Subject
→ Lesson
→ Concept
→ Practice
→ Exam
→ Attempt
→ Question Attempt
→ Mastery
→ Revision recommendation

## 7. Exam mode

Exam mode is different from normal practice.

It must support:

- long sessions
- timer
- navigation
- question review
- autosave
- final submission
- scoring
- detailed correction
- concept diagnosis

Do not add gamification elements that interfere with the examination
experience.

## 8. Persistence

Persistent data must go through repositories.

UI code must not directly manipulate SQLite tables.

## 9. Architecture

Prefer small files with one responsibility.

Do not put application logic into main.dart.

Do not create duplicate models.

Before creating a new model, search the project for an existing model.

## 10. Dependencies

Do not add a Flutter package unless:

1. the package is actually required,
2. the official/current API is known,
3. it solves a problem that should not be solved with existing code.

Never invent package APIs.

## 11. Error handling

Do not silently ignore errors.

User-facing errors should be understandable.

Developer errors should contain enough context to diagnose the problem.

## 12. UI

Use Material 3.

The UI should be:

- smooth
- modern
- responsive
- accessible
- Arabic/French/English ready
- suitable for Algerian students

Do not hardcode strings throughout widgets.

Localization will eventually be introduced.

## 13. Localization

Do not assume the application is French-only.

The product must eventually support:

- Arabic
- French
- English

Design layouts so Arabic RTL is possible.

## 14. Monetization

Ads and premium must never manipulate educational correctness.

Never make a student pay to know whether an answer is correct.

Never fabricate rewards.

Premium features must be controlled by a proper entitlement system.

## 15. Rewards

XP, streaks, achievements and rewards are engagement systems.

They must never replace actual academic progress.

## 16. Before modifying architecture

Explain:

- what is changing
- why it is necessary
- which files are affected

Do not perform large architectural changes silently.

## 17. If uncertain

STOP.

Do not guess.

Write:

UNKNOWN:
<what is unknown>

and explain what information is needed.

## 18. Code quality

Before considering a task complete:

- run flutter analyze
- fix errors
- avoid warnings where practical
- keep APIs consistent
- do not leave fake production implementations

Demo implementations must be explicitly marked as demo.
