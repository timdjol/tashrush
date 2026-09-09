enum CellType { empty, normal, frozen, gold, bomb }

class CellState {
  const CellState({this.type = CellType.empty, this.hitsRemaining = 0});

  final CellType type;
  final int hitsRemaining;
  bool get isEmpty => type == CellType.empty;

  CellState hit() {
    if (type != CellType.frozen || hitsRemaining <= 1) return const CellState();
    return CellState(type: CellType.frozen, hitsRemaining: hitsRemaining - 1);
  }

  Map<String, Object> toJson() => {
        'type': type.name,
        'hits': hitsRemaining,
      };

  factory CellState.fromJson(Map<String, Object?> json) => CellState(
        type: CellType.values.byName(json['type']! as String),
        hitsRemaining: (json['hits'] as num?)?.toInt() ?? 0,
      );
}

class GridPoint {
  const GridPoint(this.row, this.column);
  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is GridPoint && row == other.row && column == other.column;
  @override
  int get hashCode => Object.hash(row, column);
}

class GameStats {
  const GameStats({
    this.score = 0,
    this.lines = 0,
    this.combo = 0,
    this.highestCombo = 0,
    this.goldDestroyed = 0,
    this.specialCellsDestroyed = 0,
  });
  final int score;
  final int lines;
  final int combo;
  final int highestCombo;
  final int goldDestroyed;
  final int specialCellsDestroyed;

  GameStats copyWith({
    int? score,
    int? lines,
    int? combo,
    int? highestCombo,
    int? goldDestroyed,
    int? specialCellsDestroyed,
  }) =>
      GameStats(
        score: score ?? this.score,
        lines: lines ?? this.lines,
        combo: combo ?? this.combo,
        highestCombo: highestCombo ?? this.highestCombo,
        goldDestroyed: goldDestroyed ?? this.goldDestroyed,
        specialCellsDestroyed:
            specialCellsDestroyed ?? this.specialCellsDestroyed,
      );
}

enum DailyGoalType { score, lines, combo, specialCells }

class DailyChallenge {
  const DailyChallenge({
    required this.dateKey,
    required this.type,
    required this.target,
    this.progress = 0,
    this.completed = false,
  });
  final String dateKey;
  final DailyGoalType type;
  final int target;
  final int progress;
  final bool completed;

  DailyChallenge copyWith({int? progress, bool? completed}) => DailyChallenge(
        dateKey: dateKey,
        type: type,
        target: target,
        progress: progress ?? this.progress,
        completed: completed ?? this.completed,
      );
}
