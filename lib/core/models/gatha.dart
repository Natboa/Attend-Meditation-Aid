class Gatha {
  const Gatha({
    required this.id,
    required this.title,
    required this.body,
    this.attribution,
    required this.tags,
    this.isFavourite = false,
  });

  final String id;
  final String title;
  final String body;
  final String? attribution;
  final List<String> tags;
  final bool isFavourite;

  Gatha copyWith({bool? isFavourite}) => Gatha(
        id: id,
        title: title,
        body: body,
        attribution: attribution,
        tags: tags,
        isFavourite: isFavourite ?? this.isFavourite,
      );

  /// First N lines of the poem body, for preview/notification use.
  String preview({int lines = 2}) {
    final allLines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return allLines.take(lines).join('\n');
  }

  factory Gatha.fromJson(Map<String, dynamic> json) => Gatha(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        attribution: json['attribution'] as String?,
        tags: (json['tags'] as List<dynamic>).cast<String>(),
      );
}
