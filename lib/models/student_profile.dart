/// The BAC streams supported by the student profile.
enum BacStream {
  experimentalSciences,
  mathematics,
  technicalMathematics,
  managementEconomics,
  literaturePhilosophy,
  foreignLanguages,
  arts,
}

extension BacStreamStorage on BacStream {
  String get storageValue {
    switch (this) {
      case BacStream.experimentalSciences:
        return 'experimental_sciences';
      case BacStream.mathematics:
        return 'mathematics';
      case BacStream.technicalMathematics:
        return 'technical_mathematics';
      case BacStream.managementEconomics:
        return 'management_economics';
      case BacStream.literaturePhilosophy:
        return 'literature_philosophy';
      case BacStream.foreignLanguages:
        return 'foreign_languages';
      case BacStream.arts:
        return 'arts';
    }
  }
}

BacStream bacStreamFromStorage(String? value) {
  switch (value) {
    case 'mathematics':
      return BacStream.mathematics;
    case 'technical_mathematics':
      return BacStream.technicalMathematics;
    case 'management_economics':
      return BacStream.managementEconomics;
    case 'literature_philosophy':
      return BacStream.literaturePhilosophy;
    case 'foreign_languages':
      return BacStream.foreignLanguages;
    case 'arts':
      return BacStream.arts;
    case 'experimental_sciences':
    default:
      return BacStream.experimentalSciences;
  }
}

/// Student choices used to personalize the BAC journey.
class StudentProfile {
  final BacStream stream;
  final int bacYear;
  final double targetAverage;
  final String languageCode;
  final int dailyGoalMinutes;

  const StudentProfile({
    required this.stream,
    required this.bacYear,
    required this.targetAverage,
    required this.languageCode,
    required this.dailyGoalMinutes,
  });
}
