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

  bool get hasRealTitle => !title.endsWith('…') && !title.endsWith('...');

  String get displayTitle {
    if (hasRealTitle) return title;
    final attr = attribution;
    if (attr != null) {
      final lower = attr.toLowerCase();
      if (lower.contains('dhammapada')) return 'Dhammapada Verse';
      if (lower.contains('therigatha')) return 'Therigatha Verse';
      if (lower.contains('sutta nipata')) return 'Sutta Nipata Verse';
      if (lower.contains('meditations') ||
          lower.contains('enchiridion') ||
          lower.contains('lucilius') ||
          lower.contains('stoic') ||
          lower.contains('golden sayings')) {
        return 'Stoic Reflection';
      }
      if (lower.contains('tao te ching') || lower.contains('zhuangzi')) {
        return 'Taoist Reflection';
      }
      if (lower.contains('analects')) return 'Confucian Reflection';
      if (lower.contains('bhagavad gita') || lower.contains('song celestial')) {
        return 'Bhagavad Gita Verse';
      }
      final cleanAttr = attr.split(',').first.trim();
      return '$cleanAttr Quote';
    }
    return 'Wisdom Verse';
  }


  factory Gatha.fromJson(Map<String, dynamic> json) => Gatha(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        attribution: json['attribution'] as String?,
        tags: (json['tags'] as List<dynamic>).cast<String>(),
      );
}
