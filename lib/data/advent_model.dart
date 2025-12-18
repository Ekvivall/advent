class AdventDay {
  final String id;
  final int dayNum;
  final String title;
  final String description;
  final String hintImageUrl;
  final bool hasGift;
  final bool isFound;
  final String audioUrl;

  AdventDay({
    required this.id,
    required this.dayNum,
    required this.title,
    required this.description,
    required this.hintImageUrl,
    required this.hasGift,
    required this.isFound,
    required this.audioUrl,
  });

  factory AdventDay.fromFirestore(Map<String, dynamic> data, String id) {
    return AdventDay(
      id: id,
      dayNum: int.tryParse(id) ?? 0,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      hintImageUrl: data['hintImageUrl'] ?? '',
      hasGift: data['hasGift'] ?? false,      isFound: data['isFound'] ?? false,
      audioUrl: data['audioUrl'] ?? '',
    );
  }
}
