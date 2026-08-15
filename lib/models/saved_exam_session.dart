import 'dart:convert';

/// A persisted snapshot of an in-progress (or finished) exam session, used to
/// resume an interrupted paper. Only the mutable state is stored; the exam
/// and its questions are re-loaded from the content repository on resume.
enum SavedExamSessionStatus { inProgress, submitted, expired }

class SavedExamSession {
  final String id;

  final String examId;

  final DateTime startedAt;

  final int durationSeconds;

  final SavedExamSessionStatus status;

  final int currentIndex;

  /// questionId -> selected option index (unanswered questions absent).
  final Map<String, int> answers;

  final Set<String> flaggedQuestionIds;

  const SavedExamSession({
    required this.id,
    required this.examId,
    required this.startedAt,
    required this.durationSeconds,
    required this.status,
    required this.currentIndex,
    required this.answers,
    required this.flaggedQuestionIds,
  });

  factory SavedExamSession.fromMap(
    Map<String, Object?> row, {
    required Map<String, int> answers,
  }) {
    return SavedExamSession(
      id: row['id'] as String,
      examId: row['exam_id'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['started_at'] as num).toInt(),
      ),
      durationSeconds: (row['duration_seconds'] as num).toInt(),
      status: _statusFromString(row['status'] as String),
      currentIndex: (row['current_index'] as num).toInt(),
      answers: answers,
      flaggedQuestionIds: _decodeFlags(row['flagged'] as String?),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'exam_id': examId,
      'started_at': startedAt.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'status': _statusToString(status),
      'current_index': currentIndex,
      'flagged': jsonEncode(flaggedQuestionIds.toList()),
    };
  }

  static SavedExamSessionStatus _statusFromString(String value) {
    switch (value) {
      case 'submitted':
        return SavedExamSessionStatus.submitted;
      case 'expired':
        return SavedExamSessionStatus.expired;
      case 'in_progress':
      default:
        return SavedExamSessionStatus.inProgress;
    }
  }

  static String _statusToString(SavedExamSessionStatus status) {
    switch (status) {
      case SavedExamSessionStatus.inProgress:
        return 'in_progress';
      case SavedExamSessionStatus.submitted:
        return 'submitted';
      case SavedExamSessionStatus.expired:
        return 'expired';
    }
  }

  static Set<String> _decodeFlags(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<String>().toSet();
      }
    } catch (_) {
      // Fall back to empty on corrupt data.
    }

    return <String>{};
  }
}

/// Seconds left for a session that started at [startedAt] with
/// [durationSeconds], as seen from [now]. Never negative.
int remainingSecondsFor({
  required DateTime startedAt,
  required int durationSeconds,
  required DateTime now,
}) {
  final elapsed = now.difference(startedAt).inSeconds;
  final remaining = durationSeconds - elapsed;
  return remaining < 0 ? 0 : remaining;
}

/// True when a session has run out of time from [now]'s perspective.
bool sessionExpiredFor({
  required DateTime startedAt,
  required int durationSeconds,
  required DateTime now,
}) {
  return remainingSecondsFor(
        startedAt: startedAt,
        durationSeconds: durationSeconds,
        now: now,
      ) <=
      0;
}
