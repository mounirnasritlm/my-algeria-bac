# AI Development Rules — MY Algeria BAC

These rules are a contract for AI-assisted development on this project. They
exist to protect the integrity of educational content and the trust of the
students who use the app. Violations are treated as product bugs.

## The core principle

Educational content is never invented, guessed, or "completed". If content is
not known to be correct and attributable, it is not shipped.

## Rules

1. **Never invent educational content.** Every subject, chapter, lesson,
   concept, question, answer, and explanation must trace back to a real,
   documented source. A statement of fact that cannot be backed by a source
   does not enter the content.

2. **Never invent IDs.** `id` fields are references. A lesson, question, or
   exam that references a non-existent id breaks the content graph and is
   caught by `ContentValidator` as an error. If an id is unknown, stop and
   ask — do not fabricate one.

3. **Never silently repair.** The `ContentValidator` rejects invalid bundles;
   it never fixes them. An invalid bundle is refused and the previous valid
   bundle stays in use (`rejectedInvalidUpdate`). Fixes happen in the source
   repository, not in the app.

4. **Source everything.** Every lesson, concept, question, exam, video, and
   worksheet carries a `sourceId` pointing at a `ContentSource`. Unverified
   sources produce `UNVERIFIED_SOURCE` warnings, never silent acceptance as
   fact.

5. **Official content is special.** Official BAC exams and ministry material
   use `type: "official"` sources. Never relabel community or teacher content
   as official, and never mark content verified without evidence.

6. **Demo stays demo.** Demo content (source type `demo`) is for
   demonstration and testing only. It is never presented as real curriculum
   and never upgraded to verified.

7. **Never fabricate verification.** `verified: true` means a human verified
   the content against its source. Do not set it by assumption or to satisfy
   a validator.

8. **Preserve attribution.** Removing or rewriting an author, url, or
   publication field is a copyright/provenance change. It requires the user's
   explicit request.

9. **Schema changes require a version bump.** Any change to the JSON content
   schema increments `schemaVersion`; app support for a schema must be
   checked against it. The manifest `contentVersion` changes whenever the
   bundle changes.

10. **Compile before expanding.** Run `flutter analyze` and `flutter test`
    before and after content or code changes. A change that breaks the build
    or the test suite is incomplete.

11. **Do not delete working functionality.** Removing or silently replacing
    existing screens, repositories, or content during refactors is a product
    decision, not a code detail.

12. **No silent product decisions.** If a design choice affects what the user
    sees or learns (ordering, difficulty, what counts as correct), surface it
    to the user. Do not decide unilaterally.

## When in doubt

Ask. A question costs less than a wrong answer shipped to a student.
