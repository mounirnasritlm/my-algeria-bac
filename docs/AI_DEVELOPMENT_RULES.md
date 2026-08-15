# BAC Algeria — AI Development Rules

## NON-NEGOTIABLE

1. Do not invent APIs, database fields, classes, methods, or packages.

2. Before creating a new model, search the existing `lib/models`
   directory for an equivalent model.

3. Before creating a repository, search `lib/data/repositories`.

4. Before creating a service, search `lib/services`.

5. Business rules belong in services/configuration, not UI widgets.

6. UI screens must not directly manipulate SQLite.

7. UI screens must not contain XP calculation rules.

8. UI screens must not contain streak calculation rules.

9. Gamification constants must come from:
   `lib/config/gamification_config.dart`

10. Never silently change an existing business rule.

11. If a required field does not exist, STOP and report the missing
    field instead of inventing one.

12. If two existing classes appear to represent the same concept,
    STOP and report the conflict.

13. Do not replace an existing architecture with another architecture
    unless explicitly instructed.

14. Do not add dependencies unless explicitly approved.

15. Do not fabricate educational content.

16. Do not fabricate BAC exam dates, official ministry information,
    teacher identities, links, exam answers, or source attribution.

17. Educational content must have a source/reference identifier.

18. Never mark content as "official" unless the source has actually
    been verified.

19. Never create fake YouTube links.

20. Never create fake Telegram/Facebook links.

21. Never invent answers to BAC examinations.

22. If information is uncertain, represent it as unknown rather than
    guessing.

## BEFORE CODING

First inspect:
- `lib/models`
- `lib/data`
- `lib/services`
- `lib/config`
- `lib/screens`
- `pubspec.yaml`

Then state:
- files that will be modified
- files that will be created
- dependencies required
- existing classes reused

Only then write code.

## AFTER CODING

Run:

```
flutter analyze
```

Fix all analyzer errors introduced by the change.

Do not modify unrelated code just to hide an error.

## DATABASE RULE

Database schema changes require:
- version increment
- migration code
- backward compatibility consideration

Never delete existing user progress during a migration.

## CONTENT RULE

The app must distinguish:

- official
- teacher-created
- community-created
- editorial
- AI-generated

AI-generated material must never be presented as official.
