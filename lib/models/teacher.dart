class Teacher {
  final String id;

  final String name;

  final String? bio;

  final List<String> subjects;

  final Map<String, String> platforms;

  final bool verified;

  const Teacher({
    required this.id,
    required this.name,
    required this.bio,
    required this.subjects,
    required this.platforms,
    required this.verified,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final platformsRaw = Map<String, dynamic>.from(
      json['platforms'] ?? const <String, dynamic>{},
    );

    return Teacher(
      id: json['id'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      subjects: List<String>.from(json['subjects'] ?? const []),
      platforms: platformsRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      verified: json['verified'] as bool? ?? false,
    );
  }
}
