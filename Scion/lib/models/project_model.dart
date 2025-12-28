class Project {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String language;
  Map<String, String> files;
  final List<String> objectives;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.language,
    this.files = const {},
    required this.objectives,
  });
}
