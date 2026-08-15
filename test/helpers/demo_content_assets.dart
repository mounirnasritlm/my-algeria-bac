/// Canned asset content used by tests. Mirrors the shape of the real
/// assets/content/*.json files, all marked as demo content.
const Map<String, String> demoContentAssets = {
  'assets/content/content_version.json': '{"version": "0.1.0", "kind": "demo"}',
  'assets/content/subjects.json': '''
[
  {
    "id": "math",
    "name": "Mathematics",
    "language": "fr",
    "icon": "∑",
    "lessonIds": ["math_functions", "math_derivatives"]
  },
  {
    "id": "physics",
    "name": "Physics",
    "language": "fr",
    "icon": "⚡",
    "lessonIds": ["physics_motion"]
  }
]
''',
  'assets/content/lessons.json': '''
[
  {
    "id": "math_functions",
    "subjectId": "math",
    "title": "Functions",
    "description": "Introduction to mathematical functions.",
    "conceptIds": ["function_definition", "domain"],
    "estimatedMinutes": 15,
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "math_derivatives",
    "subjectId": "math",
    "title": "Derivatives",
    "description": "Introduction to derivative concepts.",
    "conceptIds": ["derivative_definition"],
    "estimatedMinutes": 20,
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "physics_motion",
    "subjectId": "physics",
    "title": "Motion",
    "description": "Introduction to motion.",
    "conceptIds": ["motion_basics"],
    "estimatedMinutes": 15,
    "source": {"sourceType": "demo_content", "verified": false}
  }
]
''',
  'assets/content/concepts.json': '''
[
  {
    "id": "function_definition",
    "name": "Function definition",
    "summary": "A relation that maps each input to exactly one output.",
    "lessonId": "math_functions",
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "domain",
    "name": "Domain",
    "summary": "The set of all valid input values of a function.",
    "lessonId": "math_functions",
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "derivative_definition",
    "name": "Derivative",
    "summary": "The rate of change of a function at a point.",
    "lessonId": "math_derivatives",
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "motion_basics",
    "name": "Motion",
    "summary": "The change of position of an object over time.",
    "lessonId": "physics_motion",
    "source": {"sourceType": "demo_content", "verified": false}
  }
]
''',
  'assets/content/questions.json': '''
[
  {
    "id": "q_math_001",
    "subjectId": "math",
    "lessonId": "math_functions",
    "conceptId": "function_definition",
    "type": "multipleChoice",
    "prompt": "Which symbol is commonly used for a function?",
    "options": ["f", "z", "q", "x"],
    "correctIndex": 0,
    "explanation": "In standard notation, f denotes a function.",
    "difficulty": 1,
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "q_math_002",
    "subjectId": "math",
    "lessonId": "math_functions",
    "conceptId": "domain",
    "type": "multipleChoice",
    "prompt": "Which set is the set of valid inputs of a function?",
    "options": ["Range", "Domain", "Codon", "Median"],
    "correctIndex": 1,
    "explanation": "The domain is the set of valid inputs.",
    "difficulty": 1,
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "q_math_003",
    "subjectId": "math",
    "lessonId": "math_functions",
    "conceptId": "function_definition",
    "type": "multipleChoice",
    "prompt": "Which of these is a function?",
    "options": ["f: x maps to x squared", "a circle", "a line segment", "a point"],
    "correctIndex": 0,
    "explanation": "Only the mapping associates each input with one output.",
    "difficulty": 2,
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "q_math_004",
    "subjectId": "math",
    "lessonId": "math_derivatives",
    "conceptId": "derivative_definition",
    "type": "multipleChoice",
    "prompt": "The rate of change of a function at a point is its...",
    "options": ["integral", "derivative", "root", "limit of a sequence"],
    "correctIndex": 1,
    "explanation": "The derivative measures the rate of change at a point.",
    "difficulty": 2,
    "source": {"sourceType": "demo_content", "verified": false}
  },
  {
    "id": "q_math_005",
    "subjectId": "math",
    "lessonId": "math_functions",
    "conceptId": "domain",
    "type": "multipleChoice",
    "prompt": "For f(x) = 1/x, which value is excluded from the domain?",
    "options": ["1", "0", "-1", "2"],
    "correctIndex": 1,
    "explanation": "Division by zero is undefined, so x = 0 is excluded.",
    "difficulty": 1,
    "source": {"sourceType": "demo_content", "verified": false}
  }
]
''',
  'assets/content/exams.json': '''
[
  {
    "id": "e_math_001",
    "subjectId": "math",
    "year": "UNKNOWN",
    "stream": null,
    "durationMinutes": 180,
    "sections": [
      {
        "id": "e_math_001_s1",
        "title": "Demo exercise 1",
        "questionIds": ["q_math_001", "q_math_002", "q_math_003"],
        "scoringInfo": "UNKNOWN"
      },
      {
        "id": "e_math_001_s2",
        "title": "Demo exercise 2",
        "questionIds": ["q_math_004", "q_math_005"],
        "scoringInfo": "UNKNOWN"
      }
    ],
    "scoringInfo": "UNKNOWN",
    "source": {"sourceType": "demo_content", "verified": false}
  }
]
''',
  'assets/content/resources.json': '''
[
  {
    "id": "r_math_001",
    "type": "book",
    "title": "El-Moughni (المغني)",
    "authorCreator": null,
    "publisher": null,
    "language": "ar",
    "url": null,
    "description": "Metadata only.",
    "subjectIds": ["math"],
    "level": "secondary",
    "source": {"sourceType": "demo_content", "verified": false}
  }
]
''',
  'assets/content/teachers.json': '[]',
  'assets/content/videos.json': '[]',
};
