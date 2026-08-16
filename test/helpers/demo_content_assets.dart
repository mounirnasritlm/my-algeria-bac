/// Canned asset content used by tests. Mirrors the shape of the real
/// assets/content/*.json files, all marked as demo content.
const Map<String, String> demoContentAssets = {
  'assets/content/manifest.json': '''
{
  "schemaVersion": "1.0.0",
  "contentVersion": "0.1.0",
  "updatedAt": "2026-08-15T00:00:00Z",
  "files": [
    { "path": "subjects.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "chapters.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "lessons.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "concepts.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "questions.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "exams.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "solutions.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "sources.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "teachers.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "videos.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" },
    { "path": "worksheets.json", "sha256": "0000000000000000000000000000000000000000000000000000000000000000" }
  ]
}
''',
  'assets/content/subjects.json': '''
[
  {
    "id": "mathematics",
    "names": {"ar": "الرياضيات", "fr": "Mathématiques", "en": "Mathematics"},
    "icon": "∑",
    "chapterIds": ["math_functions", "math_derivatives"],
    "lessonIds": [],
    "order": 1
  },
  {
    "id": "physics",
    "names": {"ar": "العلوم الفيزيائية", "fr": "Physique", "en": "Physics"},
    "icon": "⚡",
    "chapterIds": ["physics_motion"],
    "lessonIds": [],
    "order": 2
  }
]
''',
  'assets/content/chapters.json': '''
[
  {
    "id": "math_functions",
    "subjectId": "mathematics",
    "names": {"ar": "الدوال", "fr": "Fonctions", "en": "Functions"},
    "lessonIds": ["math_function_definition", "math_function_domain"],
    "order": 1
  },
  {
    "id": "math_derivatives",
    "subjectId": "mathematics",
    "names": {"ar": "الاشتقاق", "fr": "Dérivation", "en": "Derivatives"},
    "lessonIds": ["math_derivative_definition"],
    "order": 2
  },
  {
    "id": "physics_motion",
    "subjectId": "physics",
    "names": {"ar": "الحركة", "fr": "Mouvement", "en": "Motion"},
    "lessonIds": ["physics_motion_basics"],
    "order": 1
  }
]
''',
  'assets/content/lessons.json': '''
[
  {
    "id": "math_function_definition",
    "subjectId": "mathematics",
    "chapterId": "math_functions",
    "title": {"ar": "مفهوم الدالة", "fr": "Notion de fonction", "en": "Function concept"},
    "description": {"ar": "محتوى تجريبي.", "fr": "Contenu de démonstration.", "en": "Demo content."},
    "conceptIds": ["function_definition"],
    "estimatedMinutes": 15,
    "sourceId": "demo_source"
  },
  {
    "id": "math_function_domain",
    "subjectId": "mathematics",
    "chapterId": "math_functions",
    "title": {"ar": "مجال التعريف", "fr": "Domaine de définition", "en": "Domain"},
    "description": {"ar": "محتوى تجريبي.", "fr": "Contenu de démonstration.", "en": "Demo content."},
    "conceptIds": ["function_domain"],
    "estimatedMinutes": 15,
    "sourceId": "demo_source"
  },
  {
    "id": "math_derivative_definition",
    "subjectId": "mathematics",
    "chapterId": "math_derivatives",
    "title": {"ar": "مفهوم المشتقة", "fr": "Notion de dérivée", "en": "Derivative concept"},
    "description": {"ar": "محتوى تجريبي.", "fr": "Contenu de démonstration.", "en": "Demo content."},
    "conceptIds": ["derivative_definition"],
    "estimatedMinutes": 20,
    "sourceId": "demo_source"
  },
  {
    "id": "physics_motion_basics",
    "subjectId": "physics",
    "chapterId": "physics_motion",
    "title": {"ar": "أساسيات الحركة", "fr": "Les bases du mouvement", "en": "Basics of motion"},
    "description": {"ar": "محتوى تجريبي.", "fr": "Contenu de démonstration.", "en": "Demo content."},
    "conceptIds": ["motion_basics"],
    "estimatedMinutes": 15,
    "sourceId": "demo_source"
  }
]
''',
  'assets/content/concepts.json': '''
[
  {
    "id": "function_definition",
    "name": "Function definition",
    "summary": "A relation that maps each input to exactly one output.",
    "lessonId": "math_function_definition",
    "sourceId": "demo_source"
  },
  {
    "id": "function_domain",
    "name": "Function domain",
    "summary": "The set of all valid input values of a function.",
    "lessonId": "math_function_domain",
    "sourceId": "demo_source"
  },
  {
    "id": "derivative_definition",
    "name": "Derivative",
    "summary": "The rate of change of a function at a point.",
    "lessonId": "math_derivative_definition",
    "sourceId": "demo_source"
  },
  {
    "id": "motion_basics",
    "name": "Motion",
    "summary": "The change of position of an object over time.",
    "lessonId": "physics_motion_basics",
    "sourceId": "demo_source"
  }
]
''',
  'assets/content/questions.json': '''
[
  {
    "id": "q_math_001",
    "subjectId": "mathematics",
    "lessonId": "math_function_definition",
    "conceptId": "function_definition",
    "type": "multipleChoice",
    "prompt": "Which symbol is commonly used for a function?",
    "options": ["f", "z", "q", "x"],
    "correctIndex": 0,
    "explanation": "In standard notation, f denotes a function.",
    "difficulty": 1,
    "sourceId": "demo_source"
  },
  {
    "id": "q_math_002",
    "subjectId": "mathematics",
    "lessonId": "math_function_domain",
    "conceptId": "function_domain",
    "type": "multipleChoice",
    "prompt": "Which set is the set of valid inputs of a function?",
    "options": ["Range", "Domain", "Codon", "Median"],
    "correctIndex": 1,
    "explanation": "The domain is the set of valid inputs.",
    "difficulty": 1,
    "sourceId": "demo_source"
  },
  {
    "id": "q_math_003",
    "subjectId": "mathematics",
    "lessonId": "math_function_definition",
    "conceptId": "function_definition",
    "type": "multipleChoice",
    "prompt": "Which of these is a function?",
    "options": ["f: x maps to x squared", "a circle", "a line segment", "a point"],
    "correctIndex": 0,
    "explanation": "Only the mapping associates each input with one output.",
    "difficulty": 2,
    "sourceId": "demo_source"
  },
  {
    "id": "q_math_004",
    "subjectId": "mathematics",
    "lessonId": "math_derivative_definition",
    "conceptId": "derivative_definition",
    "type": "multipleChoice",
    "prompt": "The rate of change of a function at a point is its...",
    "options": ["integral", "derivative", "root", "limit of a sequence"],
    "correctIndex": 1,
    "explanation": "The derivative measures the rate of change at a point.",
    "difficulty": 2,
    "sourceId": "demo_source"
  },
  {
    "id": "q_math_005",
    "subjectId": "mathematics",
    "lessonId": "math_function_domain",
    "conceptId": "function_domain",
    "type": "multipleChoice",
    "prompt": "For f(x) = 1/x, which value is excluded from the domain?",
    "options": ["1", "0", "-1", "2"],
    "correctIndex": 1,
    "explanation": "Division by zero is undefined, so x = 0 is excluded.",
    "difficulty": 1,
    "sourceId": "demo_source"
  }
]
''',
  'assets/content/exams.json': '''
[
  {
    "id": "e_math_001",
    "subjectId": "mathematics",
    "year": "UNKNOWN",
    "stream": null,
    "durationMinutes": 180,
    "sections": [
      {
        "id": "e_math_001_s1",
        "title": "Demo exercise 1",
        "questionIds": ["q_math_001", "q_math_002", "q_math_003"]
      },
      {
        "id": "e_math_001_s2",
        "title": "Demo exercise 2",
        "questionIds": ["q_math_004", "q_math_005"]
      }
    ],
    "scoringInfo": "UNKNOWN",
    "sourceId": "demo_source"
  }
]
''',
  'assets/content/solutions.json': '[]',
  'assets/content/sources.json': '''
[
  {
    "id": "demo_source",
    "type": "demo",
    "name": "MY Algeria BAC demo content",
    "author": "MY Algeria BAC",
    "url": null,
    "publication": null,
    "year": "2026",
    "verified": false
  }
]
''',
  'assets/content/teachers.json': '[]',
  'assets/content/videos.json': '[]',
  'assets/content/worksheets.json': '[]',
};
