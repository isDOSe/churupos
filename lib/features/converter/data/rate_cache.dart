import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/currency.dart';
import '../domain/rate_quote.dart';

class RateCache {
  RateCache(this._prefs);

  static const String key = 'rates_snapshot_v1';

  final SharedPreferences _prefs;

  ({Map<Currency, RateQuote> quotes, DateTime fetchedAt})? read() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;

      final fetchedAt = DateTime.tryParse(json['fetchedAt']?.toString() ?? '');
      final quotesJson = json['quotes'];
      if (fetchedAt == null || quotesJson is! Map) return null;

      final quotes = <Currency, RateQuote>{
        Currency.ves: RateQuote.baseVes(fetchedAt),
      };

      for (final entry in quotesJson.entries) {
        final currency = Currency.fromCode(entry.key.toString());
        if (currency == null || currency.isBase) continue;
        final value = entry.value;
        if (value is! Map) continue;
        final quote = RateQuote.fromJson(
          currency,
          Map<String, Object?>.from(value),
        );
        if (quote != null) quotes[currency] = quote;
      }

      return (quotes: quotes, fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<Currency, RateQuote> quotes, DateTime fetchedAt) {
    final payload = <String, Object?>{
      'fetchedAt': fetchedAt.toIso8601String(),
      'quotes': {
        for (final entry in quotes.entries)
          if (!entry.key.isBase)
            entry.key.code.toLowerCase(): entry.value.toJson(),
      },
    };
    return _prefs.setString(key, jsonEncode(payload));
  }
}
