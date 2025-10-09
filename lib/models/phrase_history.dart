class PhraseHistory {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isFavorite;

  PhraseHistory({
    required this.id,
    required this.text,
    required this.timestamp,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory PhraseHistory.fromJson(Map<String, dynamic> json) => PhraseHistory(
        id: json['id'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isFavorite: json['isFavorite'] as bool? ?? false,
      );
}

// Backwards-compatible alias used across the codebase
typedef PhraseHistoryItem = PhraseHistory;
