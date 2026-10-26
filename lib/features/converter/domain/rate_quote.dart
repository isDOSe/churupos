import 'currency.dart';

enum RateSource { base, dolarApi, binanceP2p }

class RateQuote {
  const RateQuote({
    required this.currency,
    required this.vesPerUnit,
    required this.updatedAt,
    required this.source,
    this.stale = false,
  });

  factory RateQuote.baseVes(DateTime at) => RateQuote(
    currency: Currency.ves,
    vesPerUnit: 1,
    updatedAt: at,
    source: RateSource.base,
  );

  final Currency currency;

  /// Cuántos bolívares vale una unidad de [currency].
  final double vesPerUnit;
  final DateTime updatedAt;
  final RateSource source;
  final bool stale;

  RateQuote copyWith({
    double? vesPerUnit,
    DateTime? updatedAt,
    RateSource? source,
    bool? stale,
  }) {
    return RateQuote(
      currency: currency,
      vesPerUnit: vesPerUnit ?? this.vesPerUnit,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      stale: stale ?? this.stale,
    );
  }

  Map<String, Object?> toJson() => {
    'vesPerUnit': vesPerUnit,
    'updatedAt': updatedAt.toIso8601String(),
    'source': source.name,
  };

  static RateQuote? fromJson(Currency currency, Map<String, Object?> json) {
    final rate = (json['vesPerUnit'] as num?)?.toDouble();
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (rate == null || !rate.isFinite || rate <= 0 || updatedAt == null) {
      return null;
    }

    var source = RateSource.base;
    final rawSource = json['source'];
    for (final candidate in RateSource.values) {
      if (candidate.name == rawSource) {
        source = candidate;
        break;
      }
    }

    return RateQuote(
      currency: currency,
      vesPerUnit: rate,
      updatedAt: updatedAt,
      source: source,
      stale: true,
    );
  }
}
