/// 遊戲記錄實體
/// 表示一局已完成遊戲的記錄
class GameRecord {
  /// 記錄創建日期
  final DateTime date;

  /// 完成遊戲所用的移動次數
  final int moves;

  /// 完成遊戲所用的時間
  final Duration duration;

  const GameRecord({
    required this.date,
    required this.moves,
    required this.duration,
  });

  /// 創建記錄副本
  GameRecord copyWith({
    DateTime? date,
    int? moves,
    Duration? duration,
  }) {
    return GameRecord(
      date: date ?? this.date,
      moves: moves ?? this.moves,
      duration: duration ?? this.duration,
    );
  }

  /// 從JSON映射創建記錄
  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      date: DateTime.parse(json['date']),
      moves: json['moves'],
      duration: Duration(seconds: json['duration']),
    );
  }

  /// 轉換為JSON映射
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'moves': moves,
      'duration': duration.inSeconds,
    };
  }
}
