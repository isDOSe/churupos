enum Currency {
  ves(code: 'VES', label: 'Bolívar', symbol: 'Bs.'),
  usd(code: 'USD', label: 'Dólar BCV', symbol: '\$'),
  eur(code: 'EUR', label: 'Euro BCV', symbol: '€'),
  usdt(code: 'USDT', label: 'Binance', symbol: 'USDT');

  const Currency({
    required this.code,
    required this.label,
    required this.symbol,
  });

  final String code;
  final String label;
  final String symbol;

  bool get isBase => this == Currency.ves;

  String get sourceLabel => switch (this) {
    Currency.ves => 'Base',
    Currency.usd || Currency.eur => 'BCV',
    Currency.usdt => 'Binance P2P',
  };

  static Currency? fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final currency in Currency.values) {
      if (currency.code == normalized) return currency;
    }
    return null;
  }
}
