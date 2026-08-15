import 'concept_mastery.dart';

class RevisionRecommendation {
  final String conceptId;
  final String lessonId;
  final String title;
  final double priority;
  final MasteryStatus status;
  final String reason;

  const RevisionRecommendation({
    required this.conceptId,
    required this.lessonId,
    required this.title,
    required this.priority,
    required this.status,
    required this.reason,
  });
}
