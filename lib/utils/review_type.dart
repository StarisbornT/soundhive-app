// review_type.dart
enum ReviewType { creativeService, generalUser }

extension ReviewTypeX on ReviewType {
  List<String> get tags => switch (this) {
    ReviewType.creativeService => const [
      "Professional",
      "Great Communication",
      "Timely",
      "Highly Skilled",
      "Value for Money",
    ],
    ReviewType.generalUser => const [
      "Clear Brief",
      "Paid Promptly",
      "Respectful",
      "Easy to Work With",
      "Responsive",
    ],
  };

  String get subtitle => switch (this) {
    ReviewType.creativeService => "Kindly tell us your experience with this service provider",
    ReviewType.generalUser => "Kindly tell us your experience with this client",
  };
}