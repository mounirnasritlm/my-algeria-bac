enum WeakPointPriority {
  critical,
  high,
  medium,
  low,
}

extension WeakPointPriorityLabel on WeakPointPriority {
  String get label {
    switch (this) {
      case WeakPointPriority.critical:
        return 'CRITICAL';
      case WeakPointPriority.high:
        return 'HIGH';
      case WeakPointPriority.medium:
        return 'MEDIUM';
      case WeakPointPriority.low:
        return 'LOW';
    }
  }
}

class WeakPoint {
  final String conceptId;
  final String lessonId;
  final double mastery;
  final int attempts;
  final WeakPointPriority priority;

  const WeakPoint({
    required this.conceptId,
    required this.lessonId,
    required this.mastery,
    required this.attempts,
    required this.priority,
  });
}
