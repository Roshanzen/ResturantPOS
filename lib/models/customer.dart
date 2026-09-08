class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String initials;
  final int totalVisits;
  final double totalSpent;
  final double creditBalance;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.initials,
    this.totalVisits = 0,
    this.totalSpent = 0.0,
    this.creditBalance = 0.0,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? initials,
    int? totalVisits,
    double? totalSpent,
    double? creditBalance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      initials: initials ?? this.initials,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      creditBalance: creditBalance ?? this.creditBalance,
    );
  }
}
