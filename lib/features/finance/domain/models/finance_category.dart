enum CategoryTone { emerald, amber, coral, sky, plum }
enum CategoryKind { expense, income }

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tone,
    required this.kind,
  });

  final String id;
  final String name;
  final String emoji;
  final CategoryTone tone;
  final CategoryKind kind;

  FinanceCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    CategoryTone? tone,
    CategoryKind? kind,
  }) {
    return FinanceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      tone: tone ?? this.tone,
      kind: kind ?? this.kind,
    );
  }
}

extension CategoryKindLabelX on CategoryKind {
  String get label {
    switch (this) {
      case CategoryKind.expense:
        return 'Expense';
      case CategoryKind.income:
        return 'Income';
    }
  }
}
