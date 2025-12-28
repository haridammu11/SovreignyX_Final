class GamificationChallenge {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int points;
  final List<dynamic>? testCases;
  final String initialCode;
  final String language;
  final String solutionCode;

  GamificationChallenge({
    this.id = 'temp-id',
    this.title = 'Challenge',
    required this.description,
    this.difficulty = 'Medium',
    this.points = 10,
    this.testCases,
    this.initialCode = '',
    this.language = 'python',
    this.solutionCode = '',
  });

  factory GamificationChallenge.fromJson(Map<String, dynamic> json) {
    return GamificationChallenge(
      id: json['id'] ?? 'temp-id',
      title: json['title'] ?? 'Challenge',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
      points: json['points'] ?? 10,
      testCases: json['testCases'],
      initialCode: json['initialCode'] ?? '',
      language: json['language'] ?? 'python',
      solutionCode: json['solutionCode'] ?? '',
    );
  }
}
