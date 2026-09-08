class Money {
  final int minorUnits;
  final String currency;

  const Money(this.minorUnits, {this.currency = 'NPR'});

  factory Money.fromMajor(double major, {String currency = 'NPR'}) {
    return Money((major * 100).round(), currency: currency);
  }

  double get major => minorUnits / 100.0;

  Money operator +(Money other) {
    if (currency != other.currency) {
      throw Exception('Currency mismatch: $currency vs ${other.currency}');
    }
    return Money(minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    if (currency != other.currency) {
      throw Exception('Currency mismatch: $currency vs ${other.currency}');
    }
    return Money(minorUnits - other.minorUnits, currency: currency);
  }

  Money multiply(int factor) => Money(minorUnits * factor, currency: currency);

  Money percentage(int percent) =>
      Money((minorUnits * percent) ~/ 100, currency: currency);

  bool get isNegative => minorUnits < 0;

  bool get isZero => minorUnits == 0;

  @override
  String toString() => '${major.toStringAsFixed(2)} $currency';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          minorUnits == other.minorUnits &&
          currency == other.currency;

  @override
  int get hashCode => minorUnits.hashCode ^ currency.hashCode;
}
